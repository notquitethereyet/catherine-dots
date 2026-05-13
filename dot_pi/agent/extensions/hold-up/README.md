# hold-up

Blocks dangerous bash commands before they execute.

## Dangerous Patterns

Catches commands matching any of these:

| Pattern | Example |
|---|---|
| `rm -rf` with absolute or home paths | `rm -rf /` `rm -rf ~` |
| Writes to block devices | `> /dev/sda` |
| Filesystem formatting | `mkfs.ext4 /dev/sda1` |
| Raw disk writes | `dd if=... of=/dev/sda` |
| Overly permissive permissions | `chmod 777 /` |
| Curl piped to shell | `curl ... \| sh` |

## How It Works

Hooks the `tool_call` event and inspects bash commands against the pattern list.

- **Interactive mode** (has UI): prompts the user with a confirm dialog. Blocked unless explicitly allowed.
- **Non-interactive mode**: blocks immediately with a reason string.

## Dependencies

- `@earendil-works/pi-coding-agent`
