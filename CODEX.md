# MCP Agent Chat - Codex CLI Instructions

This document provides instructions for OpenAI Codex CLI to coordinate with other agents using MCP Agent Chat.

## Configuration

Codex CLI does not have native MCP support, so you'll interact via shell commands.

### Environment Setup

Set your MCP server URL:
```bash
export MCP_SERVER_URL="http://localhost:3000/mcp"
```

### Helper Scripts

Use the provided scripts in `scripts/mcp/` for common operations:
```bash
# Register and get token
source scripts/mcp/register_agent.sh

# Check for conflicts before editing
scripts/mcp/check_reservation.sh "app/models/user.rb"

# Reserve files
scripts/mcp/reserve_files.sh "app/models/**/*.rb" "Working on user model"

# Release reservations
scripts/mcp/release_files.sh all

# Send a chat message
scripts/mcp/send_message.sh "Starting work on authentication"

# Cleanup when done
scripts/mcp/cleanup_session.sh
```

## Manual Workflow

If not using helper scripts, follow this workflow:

### 1. Start Session

```bash
# Register agent
curl -s -X POST "$MCP_SERVER_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "macro_start_session",
      "arguments": {
        "project_path": "'$(pwd)'",
        "program": "Codex CLI",
        "model": "codex",
        "task_description": "Your task description"
      }
    }
  }'

# Save the api_token from response
export MCP_TOKEN="<token_from_response>"
```

### 2. Before Editing Files

```bash
# Check for conflicts
curl -s -X POST "$MCP_SERVER_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MCP_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "check_conflicts",
      "arguments": {
        "patterns": ["app/models/user.rb"]
      }
    }
  }'

# If no conflicts, reserve
curl -s -X POST "$MCP_SERVER_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MCP_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "reserve_files",
      "arguments": {
        "patterns": ["app/models/user.rb"],
        "reason": "Fixing bug"
      }
    }
  }'
```

### 3. Communicate

```bash
# Send message to project room
curl -s -X POST "$MCP_SERVER_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MCP_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "tools/call",
    "params": {
      "name": "send_message",
      "arguments": {
        "room_id": 1,
        "body": "Starting work on user authentication"
      }
    }
  }'
```

### 4. Check for Messages

```bash
# Fetch recent messages
curl -s -X POST "$MCP_SERVER_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MCP_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 5,
    "method": "tools/call",
    "params": {
      "name": "fetch_messages",
      "arguments": {
        "room_id": 1,
        "limit": 20
      }
    }
  }'
```

### 5. Release Reservations

```bash
# Get your reservation ID first
RESERVATIONS=$(curl -s -X POST "$MCP_SERVER_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MCP_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 6,
    "method": "tools/call",
    "params": {
      "name": "list_reservations",
      "arguments": {}
    }
  }')

# Release specific reservation
curl -s -X POST "$MCP_SERVER_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MCP_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 7,
    "method": "tools/call",
    "params": {
      "name": "release_reservation",
      "arguments": {
        "reservation_id": 1
      }
    }
  }'
```

## Tool Reference

See [AGENTS.md](./AGENTS.md) for complete tool documentation.

### Quick Reference

| Tool | Purpose |
|------|---------|
| `macro_start_session` | Register and setup in one call |
| `check_conflicts` | Check before reserving |
| `reserve_files` | Claim files for editing |
| `release_reservation` | Release file locks |
| `send_message` | Post to chat room |
| `fetch_messages` | Get chat history |
| `list_agents` | See other agents |
| `heartbeat` | Keep session alive |

## Best Practices

### Always Check Conflicts First
Before editing any file, run `check_conflicts` to avoid stepping on another agent's work.

### Reserve with Descriptive Reasons
Include a reason when reserving files so others know what you're doing.

### Send Periodic Heartbeats
If working for extended periods, call `heartbeat` every few minutes to maintain online status.

### Clean Up When Done
Always release reservations when finished, even if the session ends unexpectedly.

### Communicate Progress
Use `send_message` to keep other agents informed of your progress and any blockers.

## Example Full Session

```bash
#!/bin/bash
set -e

MCP_SERVER_URL="${MCP_SERVER_URL:-http://localhost:3000/mcp}"
PROJECT_PATH=$(pwd)

# 1. Register
RESULT=$(curl -s -X POST "$MCP_SERVER_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "macro_start_session",
      "arguments": {
        "project_path": "'$PROJECT_PATH'",
        "program": "Codex CLI",
        "model": "codex",
        "task_description": "Implementing new feature"
      }
    }
  }')

# Extract token (requires jq)
MCP_TOKEN=$(echo "$RESULT" | jq -r '.result.content[0].text' | jq -r '.api_token')
ROOM_ID=$(echo "$RESULT" | jq -r '.result.content[0].text' | jq -r '.room_id')

echo "Registered as agent, token: $MCP_TOKEN"

# 2. Announce arrival
curl -s -X POST "$MCP_SERVER_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MCP_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "send_message",
      "arguments": {
        "room_id": '$ROOM_ID',
        "body": "Codex CLI agent starting work"
      }
    }
  }'

# 3. Reserve files
curl -s -X POST "$MCP_SERVER_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MCP_TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "reserve_files",
      "arguments": {
        "patterns": ["app/controllers/**/*.rb"],
        "reason": "Adding new controller"
      }
    }
  }'

echo "Ready to work. Remember to release reservations when done."
```

## Troubleshooting

### "Unauthorized" Error
- Your token may have expired or be invalid
- Re-run the registration step
- Check server is running: `curl $MCP_SERVER_URL/health`

### Conflict on Reserve
- Another agent has those files reserved
- Fetch messages to see coordination requests
- Wait for release or negotiate via chat

### Connection Refused
- Server may not be running
- Check URL is correct
- Verify network access to server

## Related Documentation

- [AGENTS.md](./AGENTS.md) - Complete tool documentation
- [docs/SETUP.md](./docs/SETUP.md) - Server setup guide
