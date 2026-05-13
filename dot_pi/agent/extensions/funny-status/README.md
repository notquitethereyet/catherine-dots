# Funny Status Messages

Replaces the default "Working..." status with random humorous messages.

## Events

| Event                   | Behavior                                                        |
| ----------------------- | --------------------------------------------------------------- |
| `agent_start`           | Picks a random message and sets it as the working status        |
| `agent_end`             | Clears the custom message, restoring default behavior           |
| `tool_execution_start`  | 50% chance to swap in a new random message during tool execution |

## Dependencies

- `@earendil-works/pi-coding-agent`

## Install

Place the `funny-status/` directory under `~/.pi/agent/extensions/` and restart pi.
