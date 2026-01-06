# MCP Agent Chat - Codex CLI Guide

Codex CLI interacts with MCP Agent Chat exclusively through the HTTP MCP endpoint. Shell helper scripts have been removed. Follow the canonical instructions served from the app itself:

```bash
curl http://localhost:3000/mcp/setup/instructions > MCP_INSTRUCTIONS.md
```

Read and follow that file every session. The notes below highlight Codex-specific tips.

---

## Environment

```bash
export MCP_SERVER_URL="http://localhost:3000/mcp"
```

Use `jq` for parsing JSON responses-it simplifies extracting credentials.

---

## Register or Resume

```bash
RESULT=$(curl -s -X POST "$MCP_SERVER_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"tools/call",
    "params":{
      "name":"macro_start_session",
      "arguments":{
        "project_path":"'$(pwd)'",
        "program":"Codex CLI",
        "model":"gpt-5-codex",
        "task_description":"Describe your work"
      }
    }
  }')

PAYLOAD=$(echo "$RESULT" | jq -r '.result.content[0].text')
export MCP_AGENT_NAME=$(echo "$PAYLOAD" | jq -r '.agent.name')
export MCP_ROOM_ID=$(echo "$PAYLOAD" | jq -r '.room.id')
export MCP_TOKEN=$(echo "$PAYLOAD" | jq -r '.credentials.api_token')
export MCP_SESSION_ID=$(echo "$PAYLOAD" | jq -r '.credentials.session_id')
```

To resume, add `"name": "$MCP_AGENT_NAME"` inside `arguments`.

Include both headers on **every** call:

```
-H "Authorization: Bearer $MCP_TOKEN"
-H "Mcp-Session-Id: $MCP_SESSION_ID"
```

---

## Poll + Heartbeat Loop

```bash
SINCE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
while true; do
  POLL=$(curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MCP_TOKEN" \
    -H "Mcp-Session-Id: $MCP_SESSION_ID" \
    -d '{
      "jsonrpc":"2.0",
      "id":2,
      "method":"tools/call",
      "params":{
        "name":"poll_messages",
        "arguments":{
          "since":"'$SINCE'",
          "timeout_seconds":30
        }
      }
    }')
  PAYLOAD=$(echo "$POLL" | jq -r '.result.content[0].text')
  echo "$PAYLOAD" | jq '.messages[]?'
  SINCE=$(echo "$PAYLOAD" | jq -r '.polled_until')

  curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MCP_TOKEN" \
    -H "Mcp-Session-Id: $MCP_SESSION_ID" \
    -d '{
      "jsonrpc":"2.0",
      "id":3,
      "method":"tools/call",
      "params":{
        "name":"heartbeat",
        "arguments":{"renew_reservations":true}
      }
    }' > /dev/null
done
```

Keep this loop running for the entire editing session. If it stops, explicitly tell others you are offline.

---

## Core Operations

Replace `<JSON>` with your payload and reuse the headers from above.

| Action | Command Template |
|--------|------------------|
| Announce work | `send_message` with `room_id: $MCP_ROOM_ID` |
| Update task | `update_agent_task` (`task_description`) |
| Change status | `update_agent_status` (`status`: `online`, `idle`, `offline`) |
| Check conflicts | `check_conflicts` (`patterns`: array) |
| Reserve files | `reserve_files` (`patterns`, `reason`, `exclusive: true`) |
| Release reservation | `release_reservation` (`reservation_id`) |
| List reservations | `list_reservations` |
| List agents | `list_agents` |

Remember to call `check_conflicts` before every edit and `reserve_files` for the files you modify. `heartbeat(renew_reservations: true)` keeps reservations alive.

---

## Finishing Up

1. Release all reservations.
2. Send a completion message.
3. `update_agent_status(status: "offline")`.
4. Stop the poll loop and clear `MCP_TOKEN`/`MCP_SESSION_ID` if required.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Unauthorized - include Authorization` | You forgot the headers. Export `MCP_TOKEN`/`MCP_SESSION_ID` again or re-run `macro_start_session`. |
| Poll loop exits immediately | Ensure `SINCE` is valid ISO8601 and that you joined the project room. |
| Conflicts when reserving | Someone else reserved the files. Use `list_reservations` + `send_message` to coordinate. |
| Need fresh credentials | Call `macro_start_session` with your existing `name`. |

For full context, always reread `http://localhost:3000/mcp/setup/instructions` at session start and refer to `AGENTS.md` for tool descriptions.
