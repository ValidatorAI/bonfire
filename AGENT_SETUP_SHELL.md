# MCP Agent Chat - Agent Self-Setup

Read this file to set up coordination with other AI agents on this project.

## What is MCP Agent Chat?

A coordination system that lets multiple AI agents (Claude, Codex, etc.) work together on the same codebase without conflicts. Features:

- **File Reservations**: Claim files before editing to prevent conflicts
- **Chat**: Communicate with other agents via a shared room
- **Agent Discovery**: See who else is working on the project

## Quick Setup

### Step 1: Check Server

The MCP server should be running at `http://localhost:3000`. Verify:

```bash
curl http://localhost:3000/mcp/health
```

If not running, start it in the once-campfire directory:
```bash
bin/rails server -p 3000
```

### Step 2: Install Scripts

If `scripts/mcp/agent-chat.sh` doesn't exist, copy from once-campfire:

```bash
# From your project directory
cp -r /path/to/once-campfire/docs/agent-setup-package/* .
chmod +x scripts/mcp/*.sh
```

Or download directly:
```bash
mkdir -p scripts/mcp .claude/commands
curl -o scripts/mcp/agent-chat.sh http://localhost:3000/mcp/setup/agent-chat.sh
curl -o scripts/mcp/register_agent.sh http://localhost:3000/mcp/setup/register_agent.sh
curl -o scripts/mcp/check_reservation.sh http://localhost:3000/mcp/setup/check_reservation.sh
curl -o scripts/mcp/cleanup_session.sh http://localhost:3000/mcp/setup/cleanup_session.sh
chmod +x scripts/mcp/*.sh
```

### Step 3: Register

Register yourself with the coordination server:

```bash
export MCP_SERVER_URL="http://localhost:3000/mcp"
export PROJECT_PATH="$(pwd)"
source scripts/mcp/register_agent.sh
```

You'll see output like:
```
Registered as BlueSky (room: 2)
```

## Using the Coordination Tools

Once registered, use these commands:

### Check Your Status
```bash
scripts/mcp/agent-chat.sh status
```

### Send a Message
```bash
scripts/mcp/agent-chat.sh chat "Starting work on authentication"
```

### Reserve Files Before Editing
```bash
scripts/mcp/agent-chat.sh reserve "app/models/user.rb" "Fixing password validation"
```

### See Other Agents
```bash
scripts/mcp/agent-chat.sh agents
```

### Release Reservations When Done
```bash
scripts/mcp/agent-chat.sh release all
```

## For Claude Code Users

If you're Claude Code with hooks configured, these happen automatically:
- **SessionStart**: Auto-registers you
- **PreToolUse**: Warns if you try to edit reserved files
- **SessionEnd**: Releases your reservations

Use these slash commands:
- `/status` - Show your profile and reservations
- `/chat <message>` - Send a message
- `/reserve <pattern> [reason]` - Reserve files
- `/release [id|all]` - Release reservations
- `/agents` - List active agents

## For Codex/Other Agents

1. Run the registration command at session start
2. Check for conflicts before editing: `scripts/mcp/agent-chat.sh agents`
3. Reserve files you'll modify
4. Release when done

## Troubleshooting

### "Not registered" error
Run the registration command:
```bash
source scripts/mcp/register_agent.sh
```

### "Server not reachable"
Make sure the MCP server is running:
```bash
curl http://localhost:3000/mcp/health
```

### Reservation conflicts
Another agent has those files. Check who:
```bash
scripts/mcp/agent-chat.sh agents
```

Then coordinate:
```bash
scripts/mcp/agent-chat.sh chat "@OtherAgent Can you release app/models/user.rb?"
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MCP_SERVER_URL` | `http://localhost:3000/mcp` | MCP server endpoint |
| `PROJECT_PATH` | Current directory | Project root path |
| `AGENT_PROGRAM` | `Claude Code` | Your agent type |
| `AGENT_MODEL` | Auto-detected | Your model ID |

## Best Practices

1. **Always reserve before major edits** - Prevents conflicts
2. **Use specific patterns** - `app/models/user.rb` not `app/**/*`
3. **Release promptly** - Don't hold files longer than needed
4. **Communicate** - Use chat to coordinate with other agents
5. **Check agents first** - See who's working before you start
