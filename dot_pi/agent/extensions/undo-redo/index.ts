/**
 * Undo/Redo Extension (Turn-level)
 *
 * Tracks file changes at the turn level — one /undo reverts everything the
 * agent did in the last turn (all writes, edits, and bash mutations combined).
 *
 * How it works:
 *   turn_start  → snapshot current state of known trackable files
 *   tool_call   → learn about new files the agent is about to modify
 *   turn_end    → diff current state against turn_start snapshot, commit as
 *                 one "turn" entry
 *
 * Commands:
 *   /undo [n]     - Revert the last n turns (default 1)
 *   /redo [n]     - Re-apply the last n undone turns (default 1)
 *   /timeline     - Interactive timeline with per-file diffs
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, truncateToWidth } from "@earendil-works/pi-tui";
import { DatabaseSync } from "node:sqlite";
import { readFile, writeFile, mkdir, unlink, readdir } from "node:fs/promises";
import { existsSync, mkdirSync } from "node:fs";
import { dirname, join, resolve, extname } from "node:path";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface FileSnapshot {
	path: string;
	before: string | null;
	after: string | null;
	added: number;
	removed: number;
}

interface TurnEntry {
	id: number;
	desc: string;
	timestamp: number;
	snapshots: FileSnapshot[];
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const MAX_ENTRIES = 200;

const TRACKABLE_EXTENSIONS = new Set([
	".ts", ".js", ".tsx", ".jsx", ".py", ".rs", ".go", ".java", ".c", ".cpp",
	".h", ".hpp", ".rb", ".sh", ".bash", ".json", ".yaml", ".yml", ".toml",
	".md", ".txt", ".css", ".html", ".sql", ".proto", ".zig",
]);

// ---------------------------------------------------------------------------
// Line diff (LCS-based)
// ---------------------------------------------------------------------------

function countLineChanges(before: string | null, after: string | null): { added: number; removed: number } {
	if (before === null && after === null) return { added: 0, removed: 0 };
	if (before === null) return { added: (after ?? "").split("\n").length, removed: 0 };
	if (after === null) return { added: 0, removed: before.split("\n").length };

	const oldLines = before.split("\n");
	const newLines = after.split("\n");
	const m = oldLines.length;
	const n = newLines.length;

	// Cap for very large files — fall back to simple delta
	if (m * n > 2_000_000) {
		const delta = n - m;
		return {
			added: delta > 0 ? delta : 0,
			removed: delta < 0 ? -delta : 0,
		};
	}

	// LCS via DP
	const dp = new Uint16Array((m + 1) * (n + 1));
	const idx = (i: number, j: number) => i * (n + 1) + j;

	for (let i = 1; i <= m; i++) {
		for (let j = 1; j <= n; j++) {
			if (oldLines[i - 1] === newLines[j - 1]) {
				dp[idx(i, j)] = dp[idx(i - 1, j - 1)] + 1;
			} else {
				dp[idx(i, j)] = Math.max(dp[idx(i - 1, j)], dp[idx(i, j - 1)]);
			}
		}
	}

	const lcs = dp[idx(m, n)];
	return { added: n - lcs, removed: m - lcs };
}

function computeSnapshotStats(before: string | null, after: string | null): FileSnapshot {
	const { added, removed } = countLineChanges(before, after);
	return { path: "", before, after, added, removed };
}

// ---------------------------------------------------------------------------
// SQLite-backed store
// ---------------------------------------------------------------------------

class UndoStore {
	private db: DatabaseSync;

	constructor(dbPath: string) {
		const dir = dirname(dbPath);
		if (!existsSync(dir)) {
			mkdirSync(dir, { recursive: true });
		}

		this.db = new DatabaseSync(dbPath);
		this.db.exec("PRAGMA journal_mode = WAL");
		this.db.exec("PRAGMA synchronous = NORMAL");
		this.db.exec("PRAGMA foreign_keys = ON");

		this.db.exec(`
			CREATE TABLE IF NOT EXISTS meta (
				key   TEXT PRIMARY KEY,
				value TEXT NOT NULL
			);
			CREATE TABLE IF NOT EXISTS turns (
				id        INTEGER PRIMARY KEY AUTOINCREMENT,
				desc      TEXT NOT NULL,
				timestamp INTEGER NOT NULL
			);
			CREATE TABLE IF NOT EXISTS snapshots (
				turn_id        INTEGER NOT NULL REFERENCES turns(id) ON DELETE CASCADE,
				path           TEXT NOT NULL,
				before_content TEXT,
				after_content  TEXT
			);
		`);

		this.stmtInsertTurn = this.db.prepare(
			"INSERT INTO turns (desc, timestamp) VALUES (?, ?)",
		);
		this.stmtInsertSnapshot = this.db.prepare(
			"INSERT INTO snapshots (turn_id, path, before_content, after_content) VALUES (?, ?, ?, ?)",
		);
		this.stmtTurnsRange = this.db.prepare(
			"SELECT id, desc, timestamp FROM turns WHERE id > ? AND id <= ? ORDER BY id",
		);
		this.stmtSnapshotsForTurn = this.db.prepare(
			"SELECT path, before_content, after_content FROM snapshots WHERE turn_id = ?",
		);
		this.stmtTurnsAfter = this.db.prepare(
			"SELECT id FROM turns WHERE id > ? ORDER BY id",
		);
		this.stmtAllTurns = this.db.prepare(
			"SELECT id, desc, timestamp FROM turns ORDER BY id",
		);
		this.stmtDeleteAfter = this.db.prepare(
			"DELETE FROM turns WHERE id > ?",
		);
		this.stmtCountAll = this.db.prepare(
			"SELECT COUNT(*) AS cnt FROM turns",
		);
		this.stmtMinId = this.db.prepare(
			"SELECT MIN(id) AS minId FROM turns",
		);
		this.stmtGetMeta = this.db.prepare(
			"SELECT value FROM meta WHERE key = ?",
		);
		this.stmtSetMeta = this.db.prepare(
			"INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)",
		);
	}

	private stmtInsertTurn: ReturnType<DatabaseSync["prepare"]>;
	private stmtInsertSnapshot: ReturnType<DatabaseSync["prepare"]>;
	private stmtTurnsRange: ReturnType<DatabaseSync["prepare"]>;
	private stmtSnapshotsForTurn: ReturnType<DatabaseSync["prepare"]>;
	private stmtTurnsAfter: ReturnType<DatabaseSync["prepare"]>;
	private stmtAllTurns: ReturnType<DatabaseSync["prepare"]>;
	private stmtDeleteAfter: ReturnType<DatabaseSync["prepare"]>;
	private stmtCountAll: ReturnType<DatabaseSync["prepare"]>;
	private stmtMinId: ReturnType<DatabaseSync["prepare"]>;
	private stmtGetMeta: ReturnType<DatabaseSync["prepare"]>;
	private stmtSetMeta: ReturnType<DatabaseSync["prepare"]>;

	getPosition(): number {
		const row = this.stmtGetMeta.get("position") as { value: string } | null;
		return row ? parseInt(row.value, 10) || 0 : 0;
	}

	setPosition(id: number): void {
		this.stmtSetMeta.run("position", String(id));
	}

	addTurn(description: string, snapshots: FileSnapshot[]): number {
		const now = Date.now();
		const info = this.stmtInsertTurn.run(description, now);
		const turnId = Number(info.lastInsertRowid);

		for (const snap of snapshots) {
			this.stmtInsertSnapshot.run(turnId, snap.path, snap.before, snap.after);
		}

		return turnId;
	}

	getTurnsRange(fromId: number, toId: number): TurnEntry[] {
		const rows = this.stmtTurnsRange.all(fromId, toId) as Array<{
			id: number;
			desc: string;
			timestamp: number;
		}>;
		return rows.map((r) => ({
			id: r.id,
			desc: r.desc,
			timestamp: r.timestamp,
			snapshots: this.getSnapshots(r.id),
		}));
	}

	getSnapshots(turnId: number): FileSnapshot[] {
		const rows = this.stmtSnapshotsForTurn.all(turnId) as Array<{
			path: string;
			before_content: string | null;
			after_content: string | null;
		}>;
		return rows.map((r) => {
			const { added, removed } = countLineChanges(r.before_content, r.after_content);
			return {
				path: r.path,
				before: r.before_content,
				after: r.after_content,
				added,
				removed,
			};
		});
	}

	getTurnIdsAfter(afterId: number): number[] {
		const rows = this.stmtTurnsAfter.all(afterId) as Array<{ id: number }>;
		return rows.map((r) => r.id);
	}

	deleteAfter(afterId: number): void {
		this.stmtDeleteAfter.run(afterId);
	}

	getAllTurns(): TurnEntry[] {
		const rows = this.stmtAllTurns.all() as Array<{
			id: number;
			desc: string;
			timestamp: number;
		}>;
		return rows.map((r) => ({
			id: r.id,
			desc: r.desc,
			timestamp: r.timestamp,
			snapshots: this.getSnapshots(r.id),
		}));
	}

	pruneIfNeeded(): void {
		const row = this.stmtCountAll.get() as { cnt: number } | null;
		const count = row?.cnt ?? 0;
		if (count <= MAX_ENTRIES) return;
		const minRow = this.stmtMinId.get() as { minId: number } | null;
		if (minRow?.minId == null) return;
		const cutoff = minRow.minId + (count - MAX_ENTRIES);
		this.db.prepare("DELETE FROM turns WHERE id < ?").run(cutoff);
		this.db.exec("VACUUM");
	}

	close(): void {
		this.db.close();
	}
}

// ---------------------------------------------------------------------------
// File helpers
// ---------------------------------------------------------------------------

async function readFileOrNull(absPath: string): Promise<string | null> {
	try {
		return await readFile(absPath, "utf-8");
	} catch {
		return null;
	}
}

async function writeFileFromSnapshot(absPath: string, content: string | null): Promise<void> {
	if (content === null) {
		try {
			await unlink(absPath);
		} catch {
			// Already gone
		}
	} else {
		await mkdir(dirname(absPath), { recursive: true });
		await writeFile(absPath, content, "utf-8");
	}
}

function shortPath(abs: string, cwd: string): string {
	return abs.startsWith(cwd + "/") ? abs.slice(cwd.length + 1) : abs;
}

function resolveAbs(cwd: string, p: string): string {
	return resolve(cwd, p);
}

async function collectFileState(
	dir: string,
	depth: number = 3,
): Promise<Map<string, string>> {
	const result = new Map<string, string>();

	async function walk(current: string, d: number): Promise<void> {
		if (d <= 0) return;
		let entries;
		try {
			entries = await readdir(current, { withFileTypes: true });
		} catch {
			return;
		}
		for (const entry of entries) {
			if (entry.name.startsWith(".") || entry.name === "node_modules") continue;
			const full = join(current, entry.name);
			if (entry.isDirectory()) {
				await walk(full, d - 1);
			} else if (entry.isFile()) {
				const ext = extname(entry.name).toLowerCase();
				if (TRACKABLE_EXTENSIONS.has(ext)) {
					const content = await readFileOrNull(full);
					if (content !== null) {
						result.set(full, content);
					}
				}
			}
		}
	}

	await walk(dir, depth);
	return result;
}

/** Format a unified diff between two string contents. */
function makeUnifiedDiff(path: string, before: string | null, after: string | null): string {
	const bLines = (before ?? "").split("\n");
	const aLines = (after ?? "").split("\n");
	const m = bLines.length;
	const n = aLines.length;

	// LCS DP to produce edit script
	const cap = m * n > 2_000_000;
	let edit: Array<{ type: "+" | "-" | " "; line: string }>;

	if (cap) {
		// Fallback: show all old lines removed, all new lines added
		edit = [
			...bLines.map((l) => ({ type: "-" as const, line: l })),
			...aLines.map((l) => ({ type: "+" as const, line: l })),
		];
	} else {
		const dp = new Uint16Array((m + 1) * (n + 1));
		const idx = (i: number, j: number) => i * (n + 1) + j;
		for (let i = 1; i <= m; i++) {
			for (let j = 1; j <= n; j++) {
				if (bLines[i - 1] === aLines[j - 1]) {
					dp[idx(i, j)] = dp[idx(i - 1, j - 1)] + 1;
				} else {
					dp[idx(i, j)] = Math.max(dp[idx(i - 1, j)], dp[idx(i, j - 1)]);
				}
			}
		}

		// Backtrack to produce edit script
		edit = [];
		let i = m, j = n;
		while (i > 0 || j > 0) {
			if (i > 0 && j > 0 && bLines[i - 1] === aLines[j - 1]) {
				edit.push({ type: " ", line: bLines[i - 1]! });
				i--; j--;
			} else if (j > 0 && (i === 0 || dp[idx(i, j - 1)] >= dp[idx(i - 1, j)])) {
				edit.push({ type: "+", line: aLines[j - 1]! });
				j--;
			} else {
				edit.push({ type: "-", line: bLines[i - 1]! });
				i--;
			}
		}
		edit.reverse();
	}

	// Collapse into hunks with 3 lines context
	const output: string[] = [];
	output.push(`--- a/${path}`);
	output.push(`+++ b/${path}`);

	// Find all change regions and merge overlapping hunks
	const CONTEXT = 3;
	const regions: Array<{ start: number; end: number }> = [];
	let i = 0;
	while (i < edit.length) {
		while (i < edit.length && edit[i]!.type === " ") i++;
		if (i >= edit.length) break;
		const changeStart = i;
		while (i < edit.length && edit[i]!.type !== " ") i++;
		const changeEnd = i;
		regions.push({ start: changeStart, end: changeEnd });
	}

	// Merge regions that overlap with context padding
	const hunks: Array<{ start: number; end: number }> = [];
	for (const r of regions) {
		const hStart = Math.max(0, r.start - CONTEXT);
		const hEnd = Math.min(edit.length, r.end + CONTEXT);
		if (hunks.length > 0 && hStart <= hunks[hunks.length - 1]!.end) {
			hunks[hunks.length - 1]!.end = hEnd;
		} else {
			hunks.push({ start: hStart, end: hEnd });
		}
	}

	for (const hunk of hunks) {
		const slice = edit.slice(hunk.start, hunk.end);
		const beforeLines = slice.filter((e) => e.type === " " || e.type === "-");
		const afterLines = slice.filter((e) => e.type === " " || e.type === "+");

		const bStart = beforeLines.length > 0 ? "1" : "0";
		const aStart = afterLines.length > 0 ? "1" : "0";
		output.push(`@@ -${bStart},${beforeLines.length} +${aStart},${afterLines.length} @@`);

		for (const e of slice) {
			output.push(`${e.type}${e.line}`);
		}
	}

	return output.join("\n");
}

// ---------------------------------------------------------------------------
// Widget / status helpers
// ---------------------------------------------------------------------------

function formatFileTag(snap: FileSnapshot): string {
	if (snap.before === null) return "+";
	if (snap.after === null) return "x";
	return "Δ";
}

function buildStatusText(snapshots: FileSnapshot[]): string | undefined {
	if (snapshots.length === 0) return undefined;
	let edited = 0;
	let created = 0;
	let deleted = 0;
	let totalAdded = 0;
	let totalRemoved = 0;
	for (const s of snapshots) {
		if (s.before === null) created++;
		else if (s.after === null) deleted++;
		else edited++;
		totalAdded += s.added;
		totalRemoved += s.removed;
	}
	const parts: string[] = [];
	if (edited > 0) parts.push(`Δ ${edited}`);
	if (created > 0) parts.push(`+ ${created}`);
	if (deleted > 0) parts.push(`- ${deleted}`);
	return `${parts.join("  ")}  (+${totalAdded}/-${totalRemoved})`;
}

function buildWidgetLines(snapshots: FileSnapshot[], cwd: string): string[] | undefined {
	if (snapshots.length === 0) return undefined;
	const max = 8;
	const lines: string[] = [];
	for (const s of snapshots.slice(0, max)) {
		const tag = formatFileTag(s);
		const p = shortPath(s.path, cwd);
		lines.push(`${tag} ${p} (+${s.added}/-${s.removed})`);
	}
	if (snapshots.length > max) {
		lines.push(`...and ${snapshots.length - max} more`);
	}
	return lines;
}

// ---------------------------------------------------------------------------
// Interactive timeline component
// ---------------------------------------------------------------------------

interface TimelineEntry {
	turn: TurnEntry;
	isApplied: boolean;
	isCurrent: boolean;
}

type ThemeLike = {
	fg: (color: string, text: string) => string;
	bg: (color: string, text: string) => string;
	bold: (text: string) => string;
};

class TimelineComponent {
	private entries: TimelineEntry[];
	private cursorIdx: number;
	private scrollOffset: number;
	private onClose: (targetId: number | null) => void;
	private cwd: string;
	private theme: ThemeLike;
	private termHeight: number;
	private cachedRender: string[] | null = null;

	constructor(
		entries: TimelineEntry[],
		initialCursorIdx: number,
		cwd: string,
		theme: ThemeLike,
		termHeight: number,
		onClose: (targetId: number | null) => void,
	) {
		this.entries = entries;
		this.cursorIdx = initialCursorIdx;
		this.scrollOffset = Math.max(0, initialCursorIdx - 5);
		this.cwd = cwd;
		this.theme = theme;
		this.termHeight = termHeight;
		this.onClose = onClose;
	}

	private clampScroll(): void {
		const maxVisible = this.maxVisible();
		if (this.cursorIdx < this.scrollOffset) {
			this.scrollOffset = this.cursorIdx;
		}
		if (this.cursorIdx >= this.scrollOffset + maxVisible) {
			this.scrollOffset = this.cursorIdx - maxVisible + 1;
		}
	}

	private maxVisible(): number {
		return Math.max(3, Math.min(this.termHeight - 8, 40));
	}

	handleInput(data: string): void {
		if (matchesKey(data, Key.up) || matchesKey(data, "k")) {
			if (this.cursorIdx > 0) this.cursorIdx--;
		} else if (matchesKey(data, Key.down) || matchesKey(data, "j")) {
			if (this.cursorIdx < this.entries.length - 1) this.cursorIdx++;
		} else if (matchesKey(data, Key.pageUp)) {
			this.cursorIdx = Math.max(0, this.cursorIdx - this.maxVisible());
		} else if (matchesKey(data, Key.pageDown)) {
			this.cursorIdx = Math.min(this.entries.length - 1, this.cursorIdx + this.maxVisible());
		} else if (matchesKey(data, Key.home)) {
			this.cursorIdx = 0;
		} else if (matchesKey(data, Key.end)) {
			this.cursorIdx = this.entries.length - 1;
		} else if (matchesKey(data, Key.enter) || matchesKey(data, Key.return)) {
			this.onClose(this.entries[this.cursorIdx]!.turn.id);
		} else if (matchesKey(data, Key.escape) || matchesKey(data, "ctrl+c")) {
			this.onClose(null);
		} else {
			return;
		}

		this.clampScroll();
		this.cachedRender = null;
	}

	private formatFileLine(snap: FileSnapshot): string {
		const th = this.theme;
		const p = shortPath(snap.path, this.cwd);
		const tag = formatFileTag(snap);
		const tagColored = snap.before === null
			? th.fg("success", "+")
			: snap.after === null
				? th.fg("error", "x")
				: th.fg("muted", "Δ");

		const plus = snap.added === 0
			? th.fg("dim", `+${snap.added}`)
			: th.fg("success", `+${snap.added}`);
		const minus = snap.removed === 0
			? th.fg("dim", `-${snap.removed}`)
			: th.fg("error", `-${snap.removed}`);
		const stats = `(${plus}${th.fg("text", "/")}${minus})`;

		return `${tagColored} ${th.fg("muted", p)} ${stats}`;
	}

	render(width: number): string[] {
		if (this.cachedRender) return this.cachedRender;

		const th = this.theme;
		const lines: string[] = [];

		const headerText = th.fg("accent", th.bold(" Turn History "));
		const border = th.fg("borderMuted", "─");
		const rule = border.repeat(3) + headerText + border.repeat(Math.max(0, width - 20));
		lines.push("", truncateToWidth(rule, width), "");

		if (this.entries.length === 0) {
			lines.push(truncateToWidth(`  ${th.fg("dim", "No turns recorded yet.")}`, width));
			lines.push("", truncateToWidth(`  ${th.fg("dim", "Press Escape to close")}`, width), "");
			this.cachedRender = lines;
			return lines;
		}

		const maxVisible = this.maxVisible();
		const visible = this.entries.slice(this.scrollOffset, this.scrollOffset + maxVisible);

		if (this.scrollOffset > 0) {
			lines.push(truncateToWidth(`  ${th.fg("dim", "  ↑ more above")}`, width));
		}

		for (let vi = 0; vi < visible.length; vi++) {
			const idx = this.scrollOffset + vi;
			const { turn, isApplied, isCurrent } = visible[vi]!;
			const isCursor = idx === this.cursorIdx;

			const time = new Date(turn.timestamp).toLocaleTimeString();

			let rail: string;
			if (isCurrent) rail = th.fg("accent", "◀");
			else if (isApplied) rail = th.fg("success", "│");
			else rail = th.fg("dim", "╎");

			let node: string;
			if (isCurrent) node = th.fg("accent", th.bold("●"));
			else if (isApplied) node = th.fg("success", "●");
			else node = th.fg("dim", "○");

			// Turn header: rail + node + #id + time + file count
			let totalAdded = 0;
			let totalRemoved = 0;
			for (const s of turn.snapshots) {
				totalAdded += s.added;
				totalRemoved += s.removed;
			}
			const statsStr = th.fg("dim", `(+${totalAdded}/-${totalRemoved})`);
			const fileCount = th.fg("dim", `${turn.snapshots.length} file(s)`);
			const timeStr = th.fg("dim", time);

			let header: string;
			if (isCursor) {
				header = th.bg("selectedBg", ` ${rail} ${node} #${turn.id} ${fileCount} ${statsStr} ${timeStr} `);
			} else {
				header = ` ${rail} ${node} ${th.fg("muted", `#${turn.id}`)} ${fileCount} ${statsStr} ${timeStr}`;
			}
			lines.push(truncateToWidth(header, width));

			// Per-file lines (only show for cursor or a few neighbors)
			if (isCursor || Math.abs(idx - this.cursorIdx) <= 1) {
				for (const snap of turn.snapshots) {
					const fileLine = this.formatFileLine(snap);
					const prefix = isCursor
						? th.bg("selectedBg", `     ${fileLine} `)
						: `     ${fileLine}`;
					lines.push(truncateToWidth(prefix, width));
				}
			}
		}

		if (this.scrollOffset + maxVisible < this.entries.length) {
			lines.push(truncateToWidth(`  ${th.fg("dim", "  ↓ more below")}`, width));
		}

		const cur = this.entries[this.cursorIdx]!;
		const posLabel = cur.isApplied
			? th.fg("success", "applied")
			: th.fg("dim", "undone");
		const last = this.entries[this.entries.length - 1]!;
		lines.push("");
		lines.push(truncateToWidth(
			`  ${th.fg("muted", "Position:")} ${posLabel}  ${th.fg("dim", `#${cur.turn.id} / #${last.turn.id}`)}`,
			width,
		));

		lines.push("", truncateToWidth(
			`  ${th.fg("dim", "↑↓ navigate")}  ${th.fg("dim", "Enter jump")}  ${th.fg("dim", "Esc cancel")}`,
			width,
		));
		lines.push("");

		this.cachedRender = lines;
		return lines;
	}

	invalidate(): void {
		this.cachedRender = null;
	}
}

// ---------------------------------------------------------------------------
// Diff viewer component
// ---------------------------------------------------------------------------

class DiffComponent {
	private snapshots: FileSnapshot[];
	private fileIdx: number;
	private scrollOffset: number;
	private cwd: string;
	private theme: ThemeLike;
	private termHeight: number;
	private onClose: () => void;
	private cachedRender: string[] | null = null;

	constructor(
		snapshots: FileSnapshot[],
		initialFileIdx: number,
		cwd: string,
		theme: ThemeLike,
		termHeight: number,
		onClose: () => void,
	) {
		this.snapshots = snapshots;
		this.fileIdx = initialFileIdx;
		this.scrollOffset = 0;
		this.cwd = cwd;
		this.theme = theme;
		this.termHeight = termHeight;
		this.onClose = onClose;
	}

	handleInput(data: string): void {
		if (matchesKey(data, Key.escape) || matchesKey(data, "ctrl+c")) {
			this.onClose();
		} else if (matchesKey(data, Key.left) || matchesKey(data, "h")) {
			if (this.fileIdx > 0) {
				this.fileIdx--;
				this.scrollOffset = 0;
				this.cachedRender = null;
			}
		} else if (matchesKey(data, Key.right) || matchesKey(data, "l")) {
			if (this.fileIdx < this.snapshots.length - 1) {
				this.fileIdx++;
				this.scrollOffset = 0;
				this.cachedRender = null;
			}
		} else if (matchesKey(data, Key.down) || matchesKey(data, "j")) {
			this.scrollOffset++;
			this.cachedRender = null;
		} else if (matchesKey(data, Key.up) || matchesKey(data, "k")) {
			if (this.scrollOffset > 0) this.scrollOffset--;
			this.cachedRender = null;
		} else if (matchesKey(data, Key.pageDown)) {
			this.scrollOffset += this.maxDiffLines();
			this.cachedRender = null;
		} else if (matchesKey(data, Key.pageUp)) {
			this.scrollOffset = Math.max(0, this.scrollOffset - this.maxDiffLines());
			this.cachedRender = null;
		}
	}

	private maxDiffLines(): number {
		return Math.max(3, this.termHeight - 6);
	}

	render(width: number): string[] {
		if (this.cachedRender) return this.cachedRender;

		const th = this.theme;
		const snap = this.snapshots[this.fileIdx]!;
		const p = shortPath(snap.path, this.cwd);
		const tag = formatFileTag(snap);
		const lines: string[] = [];

		// Header
		const border = th.fg("borderMuted", "─");
		const title = th.fg("accent", th.bold(` ${tag} ${p} `));
		const nav = th.fg("dim", ` [${this.fileIdx + 1}/${this.snapshots.length}] `);
		lines.push(truncateToWidth(border.repeat(2) + title + nav + border.repeat(Math.max(0, width - p.length - 20)), width));

		// Diff
		const diff = makeUnifiedDiff(p, snap.before, snap.after);
		const diffLines = diff.split("\n");
		const maxLines = this.maxDiffLines();

		// Clamp scroll
		if (this.scrollOffset > 0 && this.scrollOffset >= diffLines.length) {
			this.scrollOffset = Math.max(0, diffLines.length - maxLines);
		}

		const visible = diffLines.slice(this.scrollOffset, this.scrollOffset + maxLines);
		for (const dl of visible) {
			if (dl.startsWith("---") || dl.startsWith("+++")) {
				lines.push(truncateToWidth(th.fg("muted", dl), width));
			} else if (dl.startsWith("@@")) {
				lines.push(truncateToWidth(th.fg("accent", dl), width));
			} else if (dl.startsWith("+")) {
				lines.push(truncateToWidth(th.fg("success", dl), width));
			} else if (dl.startsWith("-")) {
				lines.push(truncateToWidth(th.fg("error", dl), width));
			} else {
				lines.push(truncateToWidth(th.fg("dim", dl), width));
			}
		}

		// Footer
		lines.push(truncateToWidth(
			border.repeat(Math.max(0, width)),
			width,
		));
		lines.push(truncateToWidth(
			`  ${th.fg("dim", "←→ file")}  ${th.fg("dim", "↑↓ scroll")}  ${th.fg("dim", "Esc back")}`,
			width,
		));

		this.cachedRender = lines;
		return lines;
	}

	invalidate(): void {
		this.cachedRender = null;
	}
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	let cwd = "";
	let store: UndoStore | null = null;
	let position = 0;

	// Per-turn buffering
	let turnActive = false;
	let turnBeforeState: Map<string, string> = new Map();
	let turnFilesTouched: Set<string> = new Set();

	// Latest turn snapshots for widget display
	let lastSnapshots: FileSnapshot[] = [];

	// ------- Open / close -------

	function openStore(ctxCwd: string): void {
		cwd = ctxCwd;
		const dbPath = join(ctxCwd, ".pi", "undo-history.db");
		store = new UndoStore(dbPath);
		position = store.getPosition();

		// Restore widget from DB
		if (position > 0) {
			const turns = store.getTurnsRange(position - 1, position);
			lastSnapshots = turns.length > 0 ? turns[turns.length - 1]!.snapshots : [];
		}
	}

	function closeStore(): void {
		if (store) {
			store.close();
			store = null;
		}
	}

	function persistPosition(): void {
		if (store) store.setPosition(position);
	}

	// ------- Widget update -------

	function updateWidget(ctx: { hasUI: boolean; ui: any }): void {
		if (!ctx.hasUI) return;

		const statusText = buildStatusText(lastSnapshots);
		ctx.ui.setStatus("undo-redo", statusText ? `↩ ${statusText}` : undefined);

		const widgetLines = buildWidgetLines(lastSnapshots, cwd);
		if (widgetLines) {
			ctx.ui.setWidget("undo-redo", widgetLines);
		} else {
			ctx.ui.setWidget("undo-redo", undefined);
		}
	}

	// ------- Jump to a target turn id -------

	async function jumpTo(targetId: number): Promise<string | null> {
		if (!store) return null;
		if (targetId === position) return null;

		let turns: TurnEntry[];

		if (targetId < position) {
			turns = store.getTurnsRange(targetId, position);
			for (let i = turns.length - 1; i >= 0; i--) {
				for (const snap of turns[i].snapshots) {
					await writeFileFromSnapshot(snap.path, snap.before);
				}
			}
		} else {
			turns = store.getTurnsRange(position, targetId);
			for (const turn of turns) {
				for (const snap of turn.snapshots) {
					await writeFileFromSnapshot(snap.path, snap.after);
				}
			}
		}

		position = targetId;
		persistPosition();
		return formatTurnsSummary(turns);
	}

	function formatTurnsSummary(turns: TurnEntry[]): string {
		return turns
			.map((t) => {
				const files = t.snapshots
					.map((s) => {
						const p = shortPath(s.path, cwd);
						const tag = formatFileTag(s);
						return `${tag} ${p} (+${s.added}/-${s.removed})`;
					})
					.join(", ");
				return `  - Turn #${t.id}: ${files}`;
			})
			.join("\n");
	}

	function notifyModel(summary: string, turnCount: number, direction: "undone" | "redone"): void {
		pi.sendMessage(
			{
				customType: "undo-redo",
				content: `${turnCount} turn(s) ${direction}:\n${summary}`,
				display: true,
				details: { action: direction, changes: summary },
			},
			{ deliverAs: "nextTurn" },
		);
	}

	// ------- turn_start: snapshot current file state -------

	pi.on("turn_start", async (_event, ctx) => {
		turnActive = true;
		turnFilesTouched = new Set();
		turnBeforeState = await collectFileState(ctx.cwd);
	});

	// ------- tool_call: track which files the agent touches -------

	pi.on("tool_call", async (event, ctx) => {
		const tool = event.toolName;

		if (tool === "write") {
			const input = event.input as { path?: string };
			if (input.path) {
				turnFilesTouched.add(resolveAbs(ctx.cwd, input.path));
			}
		}

		if (tool === "edit") {
			const input = event.input as { path?: string };
			if (input.path) {
				turnFilesTouched.add(resolveAbs(ctx.cwd, input.path));
			}
		}

		if (tool === "bash") {
			const input = event.input as { command?: string };
			if (!input.command) return;
			const cmd = input.command.trim();

			const mutatingPatterns =
				/\b(sed|awk|perl|python|node|ruby)\b.*(-i|--in-place)\b|\btee\b|\bdd\b|\b>[>=]?\s*\S|\b>>\s*\S|\bmv\b|\bcp\b|\btruncate\b|\binstall\b|\bpatch\b/i;
			if (!mutatingPatterns.test(cmd)) return;

			const referencedPaths = extractPathsFromCommand(cmd);
			for (const relPath of referencedPaths) {
				turnFilesTouched.add(resolveAbs(ctx.cwd, relPath));
			}
		}
	});

	// ------- turn_end: compute diff and commit one turn entry -------

	pi.on("turn_end", async (_event, ctx) => {
		if (!turnActive || !store) {
			turnActive = false;
			return;
		}
		turnActive = false;

		const afterState = await collectFileState(ctx.cwd);

		const allPaths = new Set<string>();
		for (const p of turnFilesTouched) allPaths.add(p);
		for (const p of turnBeforeState.keys()) allPaths.add(p);
		for (const p of afterState.keys()) allPaths.add(p);

		const snapshots: FileSnapshot[] = [];
		for (const absPath of allPaths) {
			const before = turnBeforeState.get(absPath) ?? null;
			const after = afterState.get(absPath) ?? (await readFileOrNull(absPath));
			if (before !== after) {
				const { added, removed } = countLineChanges(before, after);
				snapshots.push({ path: absPath, before, after, added, removed });
			}
		}

		if (snapshots.length === 0) {
			turnBeforeState = new Map();
			turnFilesTouched = new Set();
			return;
		}

		// Truncate redo history
		if (position < store.getPosition()) {
			store.deleteAfter(position);
		}

		const fileNames = snapshots
			.slice(0, 5)
			.map((s) => `${formatFileTag(s)} ${shortPath(s.path, cwd)}`)
			.join(", ");
		const desc = snapshots.length <= 5
			? fileNames
			: `${fileNames} +${snapshots.length - 5} more`;

		const turnId = store.addTurn(desc, snapshots);
		position = turnId;
		persistPosition();
		store.pruneIfNeeded();

		lastSnapshots = snapshots;
		updateWidget(ctx);

		turnBeforeState = new Map();
		turnFilesTouched = new Set();
	});

	// ------- Session lifecycle -------

	pi.on("session_start", async (_event, ctx) => {
		closeStore();
		openStore(ctx.cwd);
		updateWidget(ctx);
	});

	pi.on("session_shutdown", async () => {
		closeStore();
	});

	// ------- /undo -------

	pi.registerCommand("undo", {
		description: "Undo the last agent turn(s). Usage: /undo [n]",
		handler: async (args, ctx) => {
			if (!store) return;

			const count = Math.max(1, parseInt(args?.trim() || "1", 10) || 1);
			const targetId = Math.max(0, position - count);

			if (targetId === position) {
				ctx.ui.notify("Nothing to undo", "warning");
				return;
			}

			const undoCount = position - targetId;
			const summary = await jumpTo(targetId);
			if (summary) {
				ctx.ui.notify(`Undid turn(s):\n${summary}`, "info");
				notifyModel(summary, undoCount, "undone");
			}

			// Update widget to show the turn we jumped to
			if (position > 0) {
				const turns = store.getTurnsRange(position - 1, position);
				lastSnapshots = turns.length > 0 ? turns[turns.length - 1]!.snapshots : [];
			} else {
				lastSnapshots = [];
			}
			updateWidget(ctx);
		},
	});

	// ------- /redo -------

	pi.registerCommand("redo", {
		description: "Redo the last undone turn(s). Usage: /redo [n]",
		handler: async (args, ctx) => {
			if (!store) return;

			const count = Math.max(1, parseInt(args?.trim() || "1", 10) || 1);
			const undoneIds = store.getTurnIdsAfter(position);
			if (undoneIds.length === 0) {
				ctx.ui.notify("Nothing to redo", "warning");
				return;
			}

			const targetId = undoneIds[Math.min(count, undoneIds.length) - 1]!;
			const redoCount = targetId - position;
			const summary = await jumpTo(targetId);
			if (summary) {
				ctx.ui.notify(`Redid turn(s):\n${summary}`, "info");
				notifyModel(summary, redoCount, "redone");
			}

			// Update widget
			const turns = store.getTurnsRange(position - 1, position);
			lastSnapshots = turns.length > 0 ? turns[turns.length - 1]!.snapshots : [];
			updateWidget(ctx);
		},
	});

	// ------- /timeline -------

	pi.registerCommand("timeline", {
		description: "Interactive turn history timeline with per-file diffs. Navigate with arrows, Enter to jump.",
		handler: async (_args, ctx) => {
			if (!store) return;

			const turns = store.getAllTurns();

			if (turns.length === 0) {
				ctx.ui.notify("No turns recorded yet.", "info");
				return;
			}

			if (!ctx.hasUI) {
				const lines = turns.map((t) => {
					const marker = t.id <= position ? "done" : "undone";
					const files = t.snapshots
						.map((s) => `${formatFileTag(s)} ${shortPath(s.path, cwd)} (+${s.added}/-${s.removed})`)
						.join(", ");
					return `[${marker}] #${t.id} ${files}`;
				});
				ctx.ui.notify(lines.join("\n"), "info");
				return;
			}

			// Main loop: timeline → diff viewer → back to timeline
			while (true) {
				const timeline: TimelineEntry[] = turns.map((t) => ({
					turn: t,
					isApplied: t.id <= position,
					isCurrent: t.id === position,
				}));

				const cursorStart = timeline.findIndex((t) => t.isCurrent);
				const initialCursor = cursorStart >= 0 ? cursorStart : timeline.length - 1;

				const action = await ctx.ui.custom<{ type: "jump"; id: number } | { type: "diff"; turnIdx: number } | null>(
					(tui, theme, _kb, done) => {
						return new TimelineComponent(
							timeline, initialCursor, cwd, theme, tui.terminal.rows,
							(result) => {
								if (result === null) {
									done(null);
								} else {
									const turnIdx = timeline.findIndex((t) => t.turn.id === result);
									// Enter on the current position = show diff; otherwise = jump
									if (result === position && turnIdx >= 0) {
										done({ type: "diff", turnIdx });
									} else {
										done({ type: "jump", id: result });
									}
								}
							},
						);
					},
				);

				if (!action) return;

				if (action.type === "jump") {
					const direction = action.id < position ? "undone" : "redone";
					const jumpCount = Math.abs(action.id - position);
					const summary = await jumpTo(action.id);
					if (summary) {
						const verb = direction === "undone" ? "Undid" : "Redid";
						ctx.ui.notify(`${verb} turn(s):\n${summary}`, "info");
						notifyModel(summary, jumpCount, direction);
					}

					if (position > 0) {
						const t = store.getTurnsRange(position - 1, position);
						lastSnapshots = t.length > 0 ? t[t.length - 1]!.snapshots : [];
					} else {
						lastSnapshots = [];
					}
					updateWidget(ctx);
					return; // Exit timeline after jump
				}

				if (action.type === "diff") {
					const turn = turns[action.turnIdx]!;
					if (turn.snapshots.length === 0) continue;

					// Show diff viewer
					await ctx.ui.custom<void>(
						(tui, theme, _kb, done) => {
							return new DiffComponent(
								turn.snapshots, 0, cwd, theme, tui.terminal.rows, done,
							);
						},
					);
					// Loop back to timeline
				}
			}
		},
	});
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function extractPathsFromCommand(cmd: string): string[] {
	const paths: string[] = [];

	const redirectRe = /(?:>{1,2})\s*(\S+)/g;
	for (const m of cmd.matchAll(redirectRe)) paths.push(m[1]!);

	const sedRe = /\bsed\b.*?(?:-i|--in-place).*?\s+(\S+)\s*$/;
	const sedMatch = cmd.match(sedRe);
	if (sedMatch) paths.push(sedMatch[1]!);

	const mvCpRe = /\b(?:mv|cp|install)\s+(?:-[a-zA-Z]+\s+)*(\S+)\s+(\S+)/;
	const mvCpMatch = cmd.match(mvCpRe);
	if (mvCpMatch) { paths.push(mvCpMatch[1]!); paths.push(mvCpMatch[2]!); }

	const patchRe = /\bpatch\s+(?:-[a-zA-Z]+\s+)*(\S+)/;
	const patchMatch = cmd.match(patchRe);
	if (patchMatch) paths.push(patchMatch[1]!);

	const teeRe = /\btee\s+(?:-[a-zA-Z]+\s+)*(\S+)/;
	const teeMatch = cmd.match(teeRe);
	if (teeMatch) paths.push(teeMatch[1]!);

	return paths.filter((p) => {
		if (p.startsWith("-")) return false;
		if (p.startsWith("(") || p.startsWith("{")) return false;
		return true;
	});
}
