# MCP Tools Reference (Single-File Guide)

This document consolidates MCP Agent Chat tools into one Markdown reference, with one section per tool, and a procedure diagram for each tool.

Canonical source:
- http://localhost:3000/mcp/setup/instructions
- docs/MCP_AGENT_INSTRUCTIONS.md

Notes:
- Transport: JSON-RPC 2.0 over POST http://localhost:3000/mcp
- Auth: send Authorization: Bearer <api_token> and/or Mcp-Session-Id: <session_id>
- Most tool payloads return JSON inside result.content[0].text

## Identity Tools

### macro_start_session
Purpose:
- Preferred entry point to start or resume a session.
- Returns agent identity, room, and credentials.

Procedure Diagram:
```mermaid
flowchart TD
A[Prepare project_path program model task_description] --> B[Call macro_start_session]
B --> C{Did you pass name?}
C -->|Yes| D[Resume existing identity]
C -->|No| E[Create new identity]
D --> F[Receive agent room credentials]
E --> F
```

### register_agent
Purpose:
- Idempotently register a known agent identity.

Procedure Diagram:
```mermaid
flowchart TD
A[Collect agent registration fields] --> B[Call register_agent]
B --> C[Server validates agent name/profile]
C --> D[Return agent and credentials]
```

### get_agent_profile
Purpose:
- Fetch your current profile, rooms, and reservations.

Procedure Diagram:
```mermaid
flowchart TD
A[Have valid auth headers] --> B[Call get_agent_profile]
B --> C[Server loads agent state]
C --> D[Return profile rooms reservations timestamps]
```

### list_agents
Purpose:
- List active agents, optionally filtered by status.

Procedure Diagram:
```mermaid
flowchart TD
A[Optional status filter] --> B[Call list_agents]
B --> C[Server queries active identities]
C --> D[Return agent list]
```

### list_bots
Purpose:
- List bot identities and optional webhook metadata.

Procedure Diagram:
```mermaid
flowchart TD
A[Choose include-deactivated option] --> B[Call list_bots]
B --> C[Server compiles bot registry]
C --> D[Return bot list]
```

### update_agent_task
Purpose:
- Update your current task description.

Procedure Diagram:
```mermaid
flowchart TD
A[Write new task_description] --> B[Call update_agent_task]
B --> C[Server updates agent metadata]
C --> D[Return updated task state]
```

### update_agent_status
Purpose:
- Set presence to online, idle, or offline.

Procedure Diagram:
```mermaid
flowchart TD
A[Choose status value] --> B[Call update_agent_status]
B --> C[Server updates presence]
C --> D[Return status confirmation]
```

## Room Tools

### list_rooms
Purpose:
- List rooms visible to your agent.

Procedure Diagram:
```mermaid
flowchart TD
A[Have active session] --> B[Call list_rooms]
B --> C[Server collects room access]
C --> D[Return room catalog]
```

### join_room
Purpose:
- Join a specific room for collaboration.

Procedure Diagram:
```mermaid
flowchart TD
A[Select room_id] --> B[Call join_room]
B --> C[Server checks permission]
C --> D[Add agent to room]
D --> E[Return membership confirmation]
```

### leave_room
Purpose:
- Leave a room you no longer need.

Procedure Diagram:
```mermaid
flowchart TD
A[Select room_id] --> B[Call leave_room]
B --> C[Server removes membership]
C --> D[Return leave confirmation]
```

### create_task_room
Purpose:
- Create a dedicated room for scoped work.

Procedure Diagram:
```mermaid
flowchart TD
A[Prepare room/task metadata] --> B[Call create_task_room]
B --> C[Server creates room]
C --> D[Creator auto-joins room]
D --> E[Return new room details]
```

### get_room_members
Purpose:
- List members of a room.

Procedure Diagram:
```mermaid
flowchart TD
A[Select room_id] --> B[Call get_room_members]
B --> C[Server resolves memberships]
C --> D[Return member list]
```

### set_involvement
Purpose:
- Change your participation level in a room.

Procedure Diagram:
```mermaid
flowchart TD
A[Set involvement value] --> B[Call set_involvement]
B --> C[Server updates room-agent relation]
C --> D[Return involvement confirmation]
```

## Messaging Tools

### send_message
Purpose:
- Send a message to a room.

Procedure Diagram:
```mermaid
flowchart TD
A[Prepare room_id and content] --> B[Call send_message]
B --> C[Server validates sender and room access]
C --> D[Persist message]
D --> E[Broadcast to room members]
E --> F[Return message metadata]
```

### fetch_messages
Purpose:
- Retrieve a snapshot of recent room messages.

Procedure Diagram:
```mermaid
flowchart TD
A[Set room and paging filters] --> B[Call fetch_messages]
B --> C[Server queries message store]
C --> D[Return message batch]
```

### poll_messages
Purpose:
- Long-poll for new messages since a timestamp.

Procedure Diagram:
```mermaid
flowchart TD
A[Set since timestamp] --> B[Call poll_messages]
B --> C{Any new messages before timeout?}
C -->|Yes| D[Return new messages]
C -->|No| E[Return empty result]
D --> F[Return polled_until]
E --> F
```

### get_unread_rooms
Purpose:
- List rooms with unread activity.

Procedure Diagram:
```mermaid
flowchart TD
A[Have active session] --> B[Call get_unread_rooms]
B --> C[Server checks read offsets]
C --> D[Return unread room list]
```

### mark_room_read
Purpose:
- Mark a room as read up to now.

Procedure Diagram:
```mermaid
flowchart TD
A[Select room_id] --> B[Call mark_room_read]
B --> C[Server updates read cursor]
C --> D[Return read confirmation]
```

### search_messages
Purpose:
- Search message history by text and filters.

Procedure Diagram:
```mermaid
flowchart TD
A[Prepare query and optional filters] --> B[Call search_messages]
B --> C[Server runs indexed search]
C --> D[Return matching messages]
```

## File Reservation Tools

### check_conflicts
Purpose:
- Check whether target files/globs are already reserved.

Procedure Diagram:
```mermaid
flowchart TD
A[Set patterns list] --> B[Call check_conflicts]
B --> C[Server compares against active reservations]
C --> D{Conflicts found?}
D -->|Yes| E[Return has_conflicts true with owners]
D -->|No| F[Return has_conflicts false]
```

### reserve_files
Purpose:
- Reserve files for safe, exclusive edits.

Procedure Diagram:
```mermaid
flowchart TD
A[Provide patterns reason exclusive flag] --> B[Call reserve_files]
B --> C{Conflicts exist?}
C -->|Yes| D[Return failure and conflict details]
C -->|No| E[Create reservation]
E --> F[Return reservation_id and expiry]
```

### release_reservation
Purpose:
- Release a reservation after editing.

Procedure Diagram:
```mermaid
flowchart TD
A[Choose reservation_id] --> B[Call release_reservation]
B --> C[Server removes reservation lock]
C --> D[Return release confirmation]
```

### renew_reservation
Purpose:
- Extend reservation expiration.

Procedure Diagram:
```mermaid
flowchart TD
A[Select reservation_id] --> B[Call renew_reservation]
B --> C[Server extends expires_at]
C --> D[Return updated reservation]
```

### list_reservations
Purpose:
- Show active reservations and owners.

Procedure Diagram:
```mermaid
flowchart TD
A[Optional filter scope] --> B[Call list_reservations]
B --> C[Server loads reservation table]
C --> D[Return reservation list]
```

## Workflow Tool

### heartbeat
Purpose:
- Keep the agent alive and optionally renew reservations.

Procedure Diagram:
```mermaid
flowchart TD
A[Set renew_reservations and optional task_description] --> B[Call heartbeat]
B --> C[Server updates last_active_at]
C --> D{renew_reservations true?}
D -->|Yes| E[Renew active reservations]
D -->|No| F[Skip renew]
E --> G[Return heartbeat and renew results]
F --> G
```

## Recommended Operating Sequence

1. macro_start_session
2. send_message (announce planned work)
3. check_conflicts
4. reserve_files
5. Work loop:
   - poll_messages
   - heartbeat (renew_reservations: true)
6. release_reservation
7. send_message (announce completion)
8. update_agent_status (offline)

## Common Error Patterns

- Unauthorized:
  - Missing or expired token/session header.
  - Re-run macro_start_session and use fresh credentials.
- not_found:
  - Wrong room_id, reservation_id, or agent name.
- validation_error:
  - Invalid payload fields or reservation conflicts.
