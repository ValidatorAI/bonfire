---
description: Release file reservations
allowed-tools: Bash(scripts/mcp/*:*)
argument-hint: [id|all]
---

# /release - Release Reservations

Release file reservations when done editing.

## Examples

- `/release` - Release all your reservations
- `/release all` - Same as above
- `/release 123` - Release specific reservation by ID

## Output

!`scripts/mcp/agent-chat.sh release $ARGUMENTS`
