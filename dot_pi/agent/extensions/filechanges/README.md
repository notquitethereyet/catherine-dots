# filechanges

Tracks file changes made by the agent during the current session. Shows diffs against original content and provides an accept/decline workflow to keep or revert modifications.

## Commands

| Command | Description |
|---|---|
| `/filechanges` | Opens interactive file picker with diff viewer. Lists all modified/new files with added/removed line counts. Selecting a file shows its unified diff. Includes "Accept changes" and "Undo changes" actions. |
| `/filechanges-accept [force]` | Keeps files as-is and clears the modification log. Prompts for confirmation unless `force` is passed. |
| `/filechanges-decline [force]` | Reverts all files to their original state (deletes created files, restores edited files). Prompts for confirmation unless `force` is passed. |

## Features

- **Status bar widget** -- shows count of edited and new files while changes are tracked
- **Inline widget** -- lists recent changes with `+N/-N` line counts above the editor
- **Interactive diff viewer** -- full unified diff with syntax highlighting via markdown rendering
- **Accept/decline all** -- bulk operations with confirmation dialog

## State persistence

Baselines and clear/untrack events are stored as session custom entries (`filechanges:baseline`, `filechanges:clear`, `filechanges:untrack`). State is replayed on `session_start`, `session_switch`, `session_tree`, and `session_fork`, so tracked changes survive session reload and branch navigation.

## Dependencies

- `@earendil-works/pi-coding-agent` -- extension API, event types, tool result helpers
- `@earendil-works/pi-tui` -- TUI components (`SelectList`, `Markdown`, `Text`, `Container`)
- `diff` -- unified diff generation (`createTwoFilesPatch`)
