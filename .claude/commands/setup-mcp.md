# /setup-mcp - Configure MCP Agent Chat

Set up MCP Agent Chat in any project to enable multi-agent coordination.

## Usage

```
/setup-mcp <mcp_server_url>
```

## Examples

```
/setup-mcp http://localhost:3000/mcp
/setup-mcp https://bonfire.example.com/mcp
```

## What This Does

1. **Creates `.claude/` directory** (if needed)
2. **Configures MCP server** in `.claude/settings.json`
3. **Installs hooks** for automatic registration and cleanup
4. **Creates helper scripts** in `scripts/mcp/`
5. **Copies skill definitions** to `.claude/commands/`
6. **Tests the connection** to verify setup

## Implementation Steps

### Step 1: Create directories

```bash
mkdir -p .claude/commands
mkdir -p scripts/mcp
```

### Step 2: Configure settings.json

Create or update `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(scripts/mcp/*:*)"
    ]
  },
  "hooks": {
    "PreSession": [
      {
        "command": "scripts/mcp/register_agent.sh",
        "timeout": 10000
      }
    ],
    "PreToolUse": [
      {
        "matcher": {
          "tools": ["Edit", "Write", "MultiEdit"]
        },
        "command": "scripts/mcp/check_reservation.sh \"$TOOL_INPUT_FILE_PATH\"",
        "timeout": 5000,
        "onFailure": "warn"
      }
    ],
    "PostSession": [
      {
        "command": "scripts/mcp/cleanup_session.sh",
        "timeout": 10000
      }
    ]
  },
  "env": {
    "MCP_SERVER_URL": "<mcp_server_url>"
  }
}
```

### Step 3: Copy hook scripts

Copy these scripts from the MCP Agent Chat project:
- `scripts/mcp/register_agent.sh`
- `scripts/mcp/check_reservation.sh`
- `scripts/mcp/cleanup_session.sh`
- `scripts/mcp/send_message.sh`
- `scripts/mcp/reserve_files.sh`
- `scripts/mcp/release_files.sh`

Make them executable:
```bash
chmod +x scripts/mcp/*.sh
```

### Step 4: Copy skill definitions

Copy skill markdown files to `.claude/commands/`:
- `chat.md`
- `reserve.md`
- `release.md`
- `agents.md`
- `status.md`

### Step 5: Test connection

```bash
curl -s http://localhost:3000/mcp/health
```

## Using the Portable Setup Package

For easier setup, use the portable package:

```bash
# From the MCP Agent Chat project
cp -r docs/agent-setup-package/* /path/to/your/project/
cd /path/to/your/project
./install.sh http://localhost:3000/mcp
```

## Notes

- The MCP server must be running before using agent features
- Each agent instance should use a unique session
- Hooks automatically handle registration and cleanup
- Test with `/status` after setup to verify
