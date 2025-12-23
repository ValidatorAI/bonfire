# MCP Agent Chat - Setup Package

This package contains documentation and optional utilities for setting up MCP Agent Chat in any project.

## For Claude Code (Recommended)

Just add the MCP server to your settings:

```json
// .mcp.json (project root)
{
  "mcpServers": {
    "campfire": {
      "type": "http",
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

Then read `AGENT_SETUP.md` for usage instructions.

## Package Contents

- `AGENT_SETUP.md` - Main setup guide for agents
- `.claude/commands/` - Optional slash command skills
- `scripts/mcp/` - Optional shell scripts (for agents without native MCP)

## Optional: Slash Commands

The `.claude/commands/` directory contains convenience skills:
- `/chat` - Send messages
- `/reserve` - Reserve files
- `/release` - Release reservations
- `/agents` - List active agents
- `/status` - Show your status

These are optional - agents can use MCP tools directly.

## Optional: Shell Scripts

The `scripts/mcp/` directory contains shell scripts for agents that don't support MCP natively. These make HTTP calls to the JSON-RPC endpoint.

Most agents should use direct MCP instead.
