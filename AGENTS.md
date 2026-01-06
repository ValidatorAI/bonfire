# MCP Agent Chat - AI Agent Instructions

MCP Agent Chat lets multiple coding agents collaborate safely on this repository. **Always fetch the canonical setup guide from the MCP server itself:**

```bash
curl http://localhost:3000/mcp/setup/instructions
```

That document (stored in `docs/MCP_AGENT_INSTRUCTIONS.md`) is the source of truth for registration, credential storage, polling loops, and best practices. This file summarizes the overall architecture and tool reference.

---

## MCP Server Connection

- **Endpoint:** `http://localhost:3000/mcp`
- **Protocol:** JSON-RPC 2.0 over HTTP POST
- **Initialization:** Call `initialize` -> `notifications/initialized` -> `tools/list` as needed.

### Authentication

1. Call `macro_start_session` (preferred) or `register_agent` to receive:
   - `agent` (id + name)
   - `room` (project room id)
   - `credentials.api_token`
   - `credentials.session_id`
2. Persist these values and send at least one of the following on every request:
   - `Authorization: Bearer <api_token>`
   - `Mcp-Session-Id: <session_id>`
3. `macro_start_session` accepts an optional `name` to resume the same identity; omit the name to receive an auto-generated one.

Requests that lack valid credentials are rejected with `Unauthorized - include Authorization: Bearer <api_token> or Mcp-Session-Id header`.

---

## Quick Session Flow

1. **Fetch instructions:** `curl /mcp/setup/instructions`.
2. **Register / resume:** `macro_start_session` with project path, program, model, and task.
3. **Store credentials:** Export `MCP_TOKEN`, `MCP_SESSION_ID`, `MCP_AGENT_NAME`, and `MCP_ROOM_ID`.
4. **Poll + heartbeat:** Loop over `poll_messages` (`since` timestamp) and `heartbeat(renew_reservations: true)`.
5. **Reserve before editing:** `check_conflicts` -> `reserve_files`.
6. **Communicate:** `send_message`, `list_agents`, `update_agent_task/status`.
7. **Release + sign off:** `release_reservation`, `send_message`, `update_agent_status(status: "offline")`.

---

## Tool Reference

### Identity

| Tool | Purpose |
|------|---------|
| `macro_start_session` | Register/reconnect, join the project room, optionally reserve files. Returns credentials. |
| `register_agent` | Idempotently register a known agent name, returning credentials. |
| `get_agent_profile` | Fetch your agent, rooms, reservations, and timestamps. |
| `list_agents` | View active agents (filterable by status). |
| `update_agent_task` | Describe what you are working on. |
| `update_agent_status` | Set presence (`online`, `idle`, `offline`). |

### Rooms

`list_rooms`, `join_room`, `leave_room`, `create_task_room`, `get_room_members`, `set_involvement`.

### Messaging

`send_message`, `fetch_messages`, `poll_messages`, `get_unread_rooms`, `mark_room_read`.

`poll_messages` requires:
- `since`: ISO8601 timestamp (use `polled_until` from previous response).
- Optional `room_ids`: subset of joined rooms.
- Optional `timeout_seconds` (default 30, max 60).

### File Reservations

`check_conflicts`, `reserve_files`, `release_reservation`, `renew_reservation`, `list_reservations`.

### Workflow

`heartbeat` keeps agents online, renews reservations, and can update `task_description`.

Each tool returns a `result` packaged inside `result.content[0].text` (JSON string). Parse it with `jq` or your client's native JSON handling.

---

## Authentication & Presence Details

- **Credentials:** `api_token` and `session_id` are generated automatically. Tokens rotate when agents are created; reuse the exact agent `name` to resume.
- **Headers:** Always send `Authorization: Bearer <api_token>` *and* `Mcp-Session-Id: <session_id>` to survive client limitations.
- **Heartbeat:** Send at least every 60 seconds to update `last_active_at` and optionally renew reservations (`renew_reservations: true`).
- **Status updates:** Use `update_agent_status` whenever you change availability (step away, idle, offline).

---

## File Reservation Protocol

1. `check_conflicts` with the precise files/globs you intend to edit.
2. `reserve_files` with `exclusive: true`, a descriptive `reason`, and the same patterns. The call fails if conflicts exist.
3. While editing, call `heartbeat(renew_reservations: true)` to extend expirations.
4. `list_reservations` to audit what you hold.
5. `release_reservation` when you are finished (never leave stale reservations).

Communicate conflicts in the project room instead of forcefully bypassing reservations.

---

## Communication & Polling

- Begin every work session with `send_message` announcing your task and any files you plan to touch.
- Run `poll_messages` in a continuous loop (see `docs/MCP_AGENT_INSTRUCTIONS.md` for a shell template). Update your `since` timestamp with `polled_until`.
- `fetch_messages` is available for snapshots, but it does **not** replace the long-poll loop.
- Use `list_agents` to see who else is online before making large edits.

---

## Example Session Workflow

```
1. Fetch latest instructions:
   curl http://localhost:3000/mcp/setup/instructions

2. macro_start_session(project_path, program, model, task_description)
   -> Save agent.name, room.id, credentials.api_token, credentials.session_id

3. Start poll_messages loop (since = now) and call heartbeat every cycle.

4. Announce work:
   send_message(room_id, "Starting work on authentication refactor")

5. Claim files:
   check_conflicts(patterns: ["app/controllers/authentication.rb"])
   reserve_files(...)

6. Perform edits, periodically heartbeat(renew_reservations: true).

7. Coordinate:
   list_agents, send_message updates, update_agent_task/status as needed.

8. Release & wrap up:
   release_reservation(reservation_id)
   send_message(room_id, "Finished, files released")
   update_agent_status(status: "offline")
```

---

## Error Handling

| Code | Meaning | Recovery |
|------|---------|----------|
| `-32000` | Unauthorized | Include valid `Authorization` or `Mcp-Session-Id` headers; rerun `macro_start_session` if needed. |
| `-32600` | Invalid request | Ensure you provide `method` and valid JSON. |
| `-32601` | Method not found | Tool name is wrong or missing; check `tools/list`. |
| `-32602` | Invalid params | Required arguments missing or wrong type. |
| `-32603` | Internal error | Retry; if persistent, inspect server logs. |
| `"validation_error"` | Business rule violation | Adjust arguments (e.g., reservation conflict or invalid status). |
| `"not_found"` | Resource missing | Verify IDs (room, agent, reservation). |

---

## Key Reminders

- Never impersonate other agents. Reuse your assigned name or pick a unique one.
- Do not claim to be polling unless `poll_messages` is actively running.
- Keep credentials secret; they grant full access to your agent identity.
- Release reservations promptly and communicate before overriding anything.
- If in doubt, re-fetch `http://localhost:3000/mcp/setup/instructions`-it is the only authoritative setup guide.
