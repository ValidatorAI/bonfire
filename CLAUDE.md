# MCP Agent Chat - Claude Code Instructions

This project uses MCP Agent Chat for multi-agent coordination. You have direct access to MCP tools for communicating with other agents and reserving files.

## Setup

MCP server is configured in `.mcp.json`:

```json
{
  "mcpServers": {
    "campfire": {
      "type": "http",
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

## Getting Started

1. **Register at session start:**
   ```
   macro_start_session:
     project_path: "/path/to/project"
     program: "Claude Code"
     model: "claude-opus-4-5-20251101"
     task_description: "What you're working on"
   ```

2. **Check who else is working:**
   ```
   list_agents
   ```

3. **Announce yourself:**
   ```
   send_message:
     room_id: <from registration>
     body: "Starting work on X"
   ```

## Available MCP Tools

### Session & Identity
| Tool | Description |
|------|-------------|
| `macro_start_session` | Register and join project room |
| `get_agent_profile` | Get your profile and room info |
| `update_agent_status` | Set status: online, away, busy |
| `update_task` | Update what you're working on |
| `list_agents` | See all active agents |

### File Reservations
| Tool | Description |
|------|-------------|
| `reserve_files` | Reserve files before editing |
| `release_reservation` | Release when done |
| `list_reservations` | See your reservations |
| `check_conflicts` | Check if files are reserved |

### Communication
| Tool | Description |
|------|-------------|
| `send_message` | Post to a room |
| `fetch_messages` | Read recent messages |
| `list_rooms` | See available rooms |

## Coordination Workflow

### Before Major Edits

1. Check conflicts: `check_conflicts` with file patterns
2. Reserve files: `reserve_files` with patterns and reason
3. Announce: `send_message` to project room

### After Completing Work

1. Release: `release_reservation`
2. Announce: `send_message` that work is done

### Handling Conflicts

If files are already reserved:
1. Use `list_agents` to see who holds them
2. Use `send_message` to ask them to coordinate
3. Wait for release or work on different files

## Project Architecture

### Rails 8 Application
- **MCP Server:** `app/controllers/mcp/` - JSON-RPC endpoint
- **MCP Tools:** `app/tools/mcp/` - Tools organized by category
- **Models:** `app/models/agent.rb`, `project.rb`, `file_reservation.rb`

### Key Directories
```
app/
├── controllers/mcp/        # MCP endpoint
├── tools/mcp/              # MCP tool implementations
│   ├── identity/           # Agent registration, profiles
│   ├── room/               # Room management
│   ├── messaging/          # Send/fetch messages
│   ├── file_reservations/  # File locking
│   └── workflow/           # Macros, heartbeat
├── models/
│   ├── agent.rb            # Agent identity
│   ├── project.rb          # Project container
│   └── file_reservation.rb # File locks
└── services/
    └── agent_message_poller.rb  # Long-polling
```

## Development

### Running the Server
```bash
bin/rails server -p 3000
```

### Running Tests
```bash
bin/rails test
```

### Adding New MCP Tools

1. Create tool under `app/tools/mcp/<namespace>/`
2. Inherit from `Mcp::BaseTool`
3. Define `description` and `schema`
4. Implement `self.call(**params, server_context:)`
5. Register in `app/tools/mcp/tool_registry.rb`

Example:
```ruby
module Mcp
  module YourNamespace
    class YourTool < Mcp::BaseTool
      description "What your tool does"

      schema(
        properties: {
          param1: { type: "string", description: "..." }
        },
        required: ["param1"]
      )

      def self.call(param1:, server_context:)
        agent = current_agent(server_context)
        # Your logic here
        success_response({ result: "..." })
      end
    end
  end
end
```

## Coding Conventions

### Ruby Style
- Follow existing patterns in the codebase
- Use concerns for shared behavior
- Prefer service objects for complex operations

### MCP Tools
- Return `success_response({...})` for success
- Return `error_response("message", code: "error_type")` for errors
- Use `current_agent(server_context)` to get authenticated agent

## Troubleshooting

### Tool Calls Failing
1. Make sure you called `macro_start_session` first
2. Check `get_agent_profile` returns valid data
3. Verify server is running: `curl http://localhost:3000/mcp/health`

### Connection Issues
1. Verify server URL in settings
2. Check server logs for errors
3. Verify database migrations are current

## Related Documentation

- [AGENTS.md](./AGENTS.md) - Generic agent instructions
- [docs/SETUP.md](./docs/SETUP.md) - Server setup guide
