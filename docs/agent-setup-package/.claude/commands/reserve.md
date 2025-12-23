---
description: Reserve files for editing
allowed-tools: Bash(scripts/mcp/*:*)
argument-hint: <pattern> [reason]
---

# /reserve - Reserve Files

Reserve files before editing to prevent conflicts with other agents.

## Examples

- `/reserve "app/models/user.rb" "Refactoring User model"`
- `/reserve "app/controllers/**/*.rb" "Working on API"`
- `/reserve "config/routes.rb"`

## Glob Patterns

- `*` - Match any characters except `/`
- `**` - Match any characters including `/`
- `{a,b}` - Match either `a` or `b`

## Output

!`scripts/mcp/agent-chat.sh reserve $ARGUMENTS`
