# ask-user

Interactive user question tool for the pi AI agent. Pauses agent execution and presents a question to the user in the TUI, then returns the answer.

## Registered Tools

### `ask_user_question`

Asks the user a single question and waits for a response. One question per call; use multiple calls for multiple questions.

**Parameters:**

| Parameter    | Type     | Description                                        |
|--------------|----------|----------------------------------------------------|
| `question`   | string   | The question to ask                                |
| `details`    | string?  | Extra context shown below the question             |
| `options`    | array?   | Multiple-choice options (omit for free-form text)  |
| `multiSelect`| boolean? | Allow multiple selections (default: false)         |

Each option has `label` (required), `value` (optional), and `description` (optional).

## Modes

- **text** -- free-form text input via the built-in editor. Used when no `options` are provided.
- **single-select** -- navigate a list with arrow keys, select with Enter. An "Other" entry lets the user type a custom answer. Used when `options` is non-empty and `multiSelect` is false/absent.
- **multi-select** -- checkbox list toggled with Space, submitted via a Submit entry. Also includes "Other". Used when `options` is non-empty and `multiSelect` is true.

## Result

Returns a structured result with `status` (`answered`, `cancelled`, or `unavailable`), `mode`, and an `answers` array. Each answer is one of:

- `{ type: "text", label, value }` -- free-form text response
- `{ type: "option", label, value, index }` -- selected predefined option
- `{ type: "other", label, value }` -- custom text entered via "Other"

## Dependencies

- `@earendil-works/pi-coding-agent` -- extension API (`ExtensionAPI`)
- `@earendil-works/pi-tui` -- TUI rendering (`Editor`, `Key`, `Text`, `matchesKey`, `truncateToWidth`, `wrapTextWithAnsi`)
- `typebox` -- JSON schema for tool parameters (`Type`)

## Requirements

- Interactive mode (requires `ctx.hasUI`). Returns `unavailable` status in headless/non-interactive contexts.
- Concurrent calls are serialized via an internal UI lock.
