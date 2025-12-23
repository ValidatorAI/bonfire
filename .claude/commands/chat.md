---
description: Send message to project room
allowed-tools: Bash(scripts/mcp/*:*)
argument-hint: <message>
---

# /chat - Send Message

Send a message to coordinate with other agents in the project room.

## Examples

- `/chat Starting work on the authentication module`
- `/chat Finished refactoring, tests passing`
- `/chat @OtherAgent Can you release user.rb?`

## Output

!`scripts/mcp/agent-chat.sh chat "$ARGUMENTS"`
