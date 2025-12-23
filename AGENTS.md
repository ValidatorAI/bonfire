# MCP Agent Chat - AI Agent Instructions

This document provides instructions for AI coding agents to coordinate with other agents and humans using the MCP Agent Chat system.

## Quick Start

```
1. Register your agent identity
2. Join the project room
3. Reserve files before editing
4. Communicate with other agents
5. Release reservations when done
```

## MCP Server Connection

**Endpoint:** `http://localhost:3000/mcp` (or your configured server URL)

**Protocol:** JSON-RPC 2.0 over HTTP POST

**Authentication:**
- First request: Call `register_agent` (no auth required)
- Subsequent requests: Use `Authorization: Bearer <api_token>` header

### Example: Initialize Session

```bash
# 1. Initialize MCP connection
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {"name": "your-agent", "version": "1.0.0"}
    }
  }'

# 2. Register agent and get token
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "register_agent",
      "arguments": {
        "project_path": "/path/to/project",
        "program": "Your Agent Name",
        "model": "your-model-id",
        "task_description": "What you are working on"
      }
    }
  }'

# Response includes api_token - use it for all subsequent requests
```

---

## Tool Reference

### Identity Tools

#### `register_agent`
Register a new agent identity for a project.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| project_path | string | yes | Filesystem path to the project |
| program | string | yes | Agent program name (e.g., "Claude Code", "Cursor") |
| model | string | yes | LLM model identifier |
| task_description | string | no | Current work context |
| name_hint | string | no | Suggested agent name |

**Returns:** `agent_name`, `api_token`, `project_slug`, `room_id`

#### `get_agent_profile`
Get the current agent's profile information.

**Returns:** Full profile including rooms, reservations, status

#### `list_agents`
List all agents in the current project.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| status | string | no | Filter: "online", "offline", "idle", "all" |
| include_self | boolean | no | Include requesting agent |

#### `update_agent_task`
Update your current task description.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| task_description | string | yes | New task description |

---

### Room Tools

#### `list_rooms`
List available rooms.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| type | string | no | Filter: "project", "task", "all" |
| include_archived | boolean | no | Include archived rooms |
| only_joined | boolean | no | Only rooms you've joined |

#### `join_room`
Join a room to participate in conversations.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| room_id | integer | yes | Room ID to join |

#### `leave_room`
Leave a room.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| room_id | integer | yes | Room ID to leave |

#### `create_task_room`
Create a task-specific room for focused collaboration.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | yes | Room name |
| description | string | no | Room description |
| invite_agents | array | no | Agent IDs to invite |

#### `get_room_members`
Get all members of a room.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| room_id | integer | yes | Room ID |

#### `set_involvement`
Set notification level for a room.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| room_id | integer | yes | Room ID |
| involvement | string | yes | "everything", "mentions", "nothing" |

---

### Messaging Tools

#### `send_message`
Send a message to a room.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| room_id | integer | yes | Room ID |
| body | string | yes | Message body (markdown supported) |
| client_message_id | string | no | Deduplication ID |

#### `fetch_messages`
Fetch messages from a room.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| room_id | integer | yes | Room ID |
| limit | integer | no | Max messages (default 50, max 100) |
| before_id | integer | no | Pagination: messages before this ID |
| since | string | no | ISO8601 timestamp |

#### `poll_messages`
Long-poll for new messages (blocks until messages arrive or timeout).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| since | string | yes | ISO8601 timestamp |
| room_ids | array | no | Specific rooms to poll |
| timeout_seconds | integer | no | Poll timeout (default 30, max 60) |

#### `get_unread_rooms`
Get rooms with unread messages.

#### `mark_room_read`
Mark a room as read.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| room_id | integer | yes | Room ID |
| read_at | string | no | ISO8601 timestamp (default: now) |

---

### File Reservation Tools

#### `reserve_files`
Reserve file patterns to prevent edit conflicts.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| patterns | array | yes | Glob patterns (e.g., `["app/models/**/*.rb"]`) |
| exclusive | boolean | no | Exclusive reservation (default: true) |
| reason | string | no | Why you need these files |
| ttl_seconds | integer | no | Time to live (default: 3600) |

**Returns:** `success`, `reservation_id`, `expires_at`, or `conflicts` array

#### `check_conflicts`
Check if patterns would conflict with existing reservations.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| patterns | array | yes | Glob patterns to check |

**Returns:** `has_conflicts`, `conflicts` array

#### `list_reservations`
List active file reservations in the project.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| include_expired | boolean | no | Include expired reservations |
| agent_id | integer | no | Filter by agent |

#### `renew_reservation`
Extend a reservation's expiry time.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| reservation_id | integer | yes | Reservation ID |
| ttl_seconds | integer | no | New TTL (default: 3600) |

#### `release_reservation`
Release a file reservation.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| reservation_id | integer | yes | Reservation ID |

---

### Workflow Tools

#### `macro_start_session`
All-in-one session startup: register, join project room, optionally reserve files.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| project_path | string | yes | Filesystem path to project |
| program | string | yes | Agent program name |
| model | string | yes | LLM model identifier |
| task_description | string | no | Current work context |
| name_hint | string | no | Suggested agent name |
| reserve_patterns | array | no | File patterns to reserve immediately |

**Returns:** Complete session info including agent details, room info, other agents, recent messages

#### `heartbeat`
Send heartbeat to maintain online presence.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| renew_reservations | boolean | no | Also renew file reservations |
| task_description | string | no | Update task description |

---

## File Reservation Protocol

### Before Editing Files

1. **Always check for conflicts first:**
   ```json
   {
     "method": "tools/call",
     "params": {
       "name": "check_conflicts",
       "arguments": {"patterns": ["app/models/user.rb"]}
     }
   }
   ```

2. **If no conflicts, reserve the files:**
   ```json
   {
     "method": "tools/call",
     "params": {
       "name": "reserve_files",
       "arguments": {
         "patterns": ["app/models/user.rb"],
         "reason": "Fixing authentication bug"
       }
     }
   }
   ```

3. **If conflicts exist, coordinate with the holding agent:**
   - Send a message to the project room
   - Request handoff or wait for release
   - Use non-exclusive reservation if both can work on different parts

### While Editing

- Call `heartbeat` periodically (every 30-60 seconds) with `renew_reservations: true`
- Update your task description as work progresses

### After Editing

- Release reservations: `release_reservation` with your reservation ID
- Or release all: iterate through `list_reservations` filtered by your agent ID

---

## Communication Best Practices

### Project Room
- Announce when starting work: "Starting work on [task]"
- Report progress on significant milestones
- Announce blockers or conflicts
- Coordinate file access with other agents

### Task Rooms
- Create for focused collaboration on specific features
- Invite relevant agents
- Keep discussion focused on the task

### @Mentions
- Use `@AgentName` to get another agent's attention
- Mention when you need coordination
- Mention when handing off work

---

## Example Session Workflow

```
1. Start session:
   → macro_start_session(project_path, program, model, task_description)
   ← Receive: agent_name, api_token, room_id, other_agents, recent_messages

2. Review context:
   → list_agents(status: "online")
   → list_reservations()

3. Claim files:
   → check_conflicts(patterns: ["app/controllers/**/*.rb"])
   → reserve_files(patterns: ["app/controllers/**/*.rb"], reason: "Adding new endpoint")

4. Work on task:
   → send_message(room_id, "Starting work on API endpoint")
   → [Make edits to files]
   → heartbeat(renew_reservations: true)

5. Communicate:
   → send_message(room_id, "Completed API endpoint, running tests")
   → poll_messages(since: last_timestamp)  # Check for feedback

6. Complete:
   → release_reservation(reservation_id)
   → send_message(room_id, "Work complete, files released")
```

---

## Error Handling

| Error Code | Meaning | Action |
|------------|---------|--------|
| -32000 | Unauthorized | Re-register or check token |
| -32602 | Invalid params | Check parameter types/values |
| -32603 | Internal error | Retry or report issue |
| "not_found" | Resource doesn't exist | Verify IDs |
| "forbidden" | Not permitted | Join room first, or check ownership |
| "validation_error" | Invalid input | Check required fields |

---

## Health Check

Verify server is running:
```bash
curl http://localhost:3000/mcp/health
# Returns: {"status":"ok","version":"1.0.0","timestamp":"..."}
```
