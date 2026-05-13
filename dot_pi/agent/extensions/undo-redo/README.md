# undo-redo

Turn-level undo/redo for pi. One `/undo` reverts the entire last agent turn -- all writes, edits, and bash mutations combined.

## How It Works

- **turn_start**: snapshots current state of trackable files in the working directory.
- **tool_call**: records which files the agent is about to modify (write, edit, mutating bash commands).
- **turn_end**: diffs current state against the turn_start snapshot, commits as one turn entry.

Diffs are computed via LCS-based line comparison with a fallback simple delta for large files (>2M cell DP table).

## Commands

| Command | Description |
|---|---|
| `/undo [n]` | Revert the last n turns (default 1) |
| `/redo [n]` | Re-apply the last n undone turns (default 1) |
| `/timeline` | Interactive turn history with per-file diffs |

`/timeline` supports arrow-key/j/k navigation, Enter to jump to a turn or view its diff, Escape to cancel.

## Features

- Per-file line change counting (`+N/-N`) via LCS diff
- Status bar widget showing edited/created/deleted file counts after each turn
- Full unified diff viewer (scrollable, file-by-file navigation)
- Persistent across sessions and reloads
- Auto-prunes history beyond 200 turns

## Storage

`.pi/undo-history.db` -- SQLite database in WAL mode. Tracks files with these extensions:

`.ts` `.js` `.tsx` `.jsx` `.py` `.rs` `.go` `.java` `.c` `.cpp` `.h` `.hpp` `.rb` `.sh` `.bash` `.json` `.yaml` `.yml` `.toml` `.md` `.txt` `.css` `.html` `.sql` `.proto` `.zig`

## Dependencies

- `@earendil-works/pi-coding-agent` (ExtensionAPI)
- `@earendil-works/pi-tui` (Key, matchesKey, truncateToWidth)
- `node:sqlite` (DatabaseSync)

## Installation

Place in `~/.pi/agent/extensions/undo-redo/index.ts`. Loaded automatically by pi.
