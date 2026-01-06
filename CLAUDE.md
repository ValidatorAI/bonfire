# MCP Agent Chat - Claude Code Guide

Claude Code can talk directly to the MCP server configured in `.mcp.json`. Helper scripts are gone: you must follow the canonical setup served from the server itself.

```bash
curl http://localhost:3000/mcp/setup/instructions > MCP_INSTRUCTIONS.md
```

Read that file every session-it explains registration, credential storage, polling, file reservations, and shutdown steps. The summary below highlights Claude-specific tips.

---

## Configure Claude Code

`.mcp.json` should already contain:

```json
{
  "mcpServers": {
    "bonfire": {
      "type": "http",
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

Restart Claude Code after editing `.mcp.json` so it loads the server definition.

---

## Register / Resume

Inside Claude Code use the MCP client panel (or run `/call tool`). Recommended flow:

1. **Register (new agent)** - call `macro_start_session` with `project_path`, `program: "Claude Code"`, `model`, and `task_description`. Omit `name` the first time to receive a memorable one (e.g., "Gary the Compiler").
2. **Resume (existing agent)** - call `macro_start_session` again but include the exact `name` returned earlier. This preserves your identity and token.
3. Save:
   - `agent.name`
   - `room.id`
   - `credentials.api_token`
   - `credentials.session_id`
4. Have Claude Code include `Authorization: Bearer <api_token>` and `Mcp-Session-Id: <session_id>` on every call. (Claude automatically stores server-issued tokens; double-check the "Credentials" view if something fails.)

---

## Keep Polling

Claude should keep a `poll_messages` stream alive the entire session. Confirm via the MCP Activity pane that:

- `poll_messages` requests repeat every ~30 seconds.
- `heartbeat` runs every loop with `renew_reservations: true`.

If you stop polling (e.g., by pausing the MCP server), announce it in chat so other agents know you are offline.

---

## Core Workflow

1. **Announce work** - `send_message` with the room id from registration.
2. **List agents** - `list_agents` to see who is online.
3. **Reserve files** - `check_conflicts` -> `reserve_files` for each file glob you touch.
4. **Update presence** - `update_agent_task` as objectives change, and `update_agent_status` when you go idle or offline.
5. **Release** - `release_reservation` as soon as you finish a file; announce completion in chat.

Keep the canonical instructions open for exact `curl`/payload templates if you need to debug.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Unauthorized` errors | Re-run `macro_start_session` with your existing name to refresh credentials, then ensure Claude sends the new token/session id. |
| Poll stream stopped | Restart the MCP server in Claude's UI or close/reopen the project workspace. |
| Reservation conflicts | Use `list_reservations` + `list_agents`, then coordinate in chat. |
| Forgot assigned name | Call `list_agents` and search for your program/model pairing. |

---

## References

- `http://localhost:3000/mcp/setup/instructions` - detailed setup guide (authoritative)
- `AGENTS.md` - complete MCP tool reference and workflow overview
- `docs/MCP_AGENT_INSTRUCTIONS.md` - same instructions as the URL above (version-controlled copy)
