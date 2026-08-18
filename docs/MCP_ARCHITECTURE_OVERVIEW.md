# MCP Architecture and Logic Overview

This document describes the overall architecture and operating logic of MCP Agent Chat for this repository.

Scope:
- System architecture
- Protocol and transport
- Authentication and session lifecycle
- Collaboration and coordination logic
- File reservation control model
- Runtime loops and failure handling

Canonical references:
- http://localhost:3000/mcp/setup/instructions
- docs/MCP_AGENT_INSTRUCTIONS.md
- AGENTS.md

## 1. High-Level Architecture

MCP Agent Chat is a collaboration layer for coding agents. Agents connect to a central MCP server and coordinate through rooms, messages, presence, and file reservations.

```mermaid
flowchart LR
U[Agent Client\nClaude/Copilot/Cursor] -->|JSON-RPC over HTTP| S[MCP Server\nhttp://localhost:3000/mcp]
S --> I[Identity Service\nAgent registration/session]
S --> R[Room Service\nMembership and involvement]
S --> M[Messaging Service\nSend/fetch/poll/search]
S --> F[Reservation Service\nConflict and file locks]
S --> P[Presence Service\nHeartbeat/status]
```

## 2. Protocol and Transport Logic

Core behavior:
- Protocol: JSON-RPC 2.0
- Endpoint: HTTP Streamable transport at /mcp
- Typical startup sequence: initialize -> notifications/initialized -> tools/list

```mermaid
sequenceDiagram
participant A as Agent Client
participant S as MCP Server
A->>S: initialize
S-->>A: protocolVersion + capabilities
A->>S: notifications/initialized
A->>S: tools/list
S-->>A: available tools
```

Design intent:
- Keep one stable endpoint for all operations.
- Expose tools as explicit RPC methods.
- Let clients choose polling cadence while preserving server-side consistency.

## 3. Authentication and Session Lifecycle

Identity and credential model:
- Session starts with macro_start_session (preferred) or register_agent.
- Server returns agent identity, room info, and credentials.
- Each request must include Authorization bearer token and/or Mcp-Session-Id.

```mermaid
flowchart TD
A[Start Session Request] --> B[macro_start_session]
B --> C{Name provided?}
C -->|Yes| D[Resume existing identity]
C -->|No| E[Create new identity]
D --> F[Issue credentials]
E --> F
F --> G[Client stores token and session id]
G --> H[All future requests send auth headers]
```

Session lifecycle states:
- online: actively participating
- idle: temporarily inactive
- offline: signed off

## 4. Collaboration Logic: Rooms and Messaging

Rooms are coordination boundaries. Messages are the coordination channel.

Operational pattern:
1. Join project room.
2. Announce planned work.
3. Poll continuously for new messages.
4. Send updates when scope changes.
5. Announce completion.

```mermaid
flowchart TD
A[Join or discover room] --> B[Send start message]
B --> C[Poll messages loop]
C --> D{New updates?}
D -->|Yes| E[Adjust plan and reply]
D -->|No| F[Continue working]
E --> C
F --> C
```

Why this matters:
- Prevents hidden parallel edits.
- Makes conflicts visible early.
- Creates traceable decision history.

## 5. File Reservation Control Model

Reservations are the concurrency guard for code edits.

Required sequence:
1. check_conflicts on exact files/globs.
2. reserve_files with exclusive true.
3. renew via heartbeat while editing.
4. release_reservation immediately after completion.

```mermaid
flowchart TD
A[Select target files/globs] --> B[check_conflicts]
B --> C{has_conflicts?}
C -->|Yes| D[Coordinate with owner in room]
C -->|No| E[reserve_files]
E --> F[Perform edits]
F --> G[heartbeat renew_reservations true]
G --> H[release_reservation]
```

Control objective:
- Ensure one active editor per protected file scope.
- Trade small coordination overhead for predictable integration safety.

## 6. Runtime Loop Logic

A healthy agent usually runs two recurring actions:
- poll_messages with since timestamp
- heartbeat with renew_reservations true

```mermaid
flowchart TD
A[Initialize since timestamp] --> B[poll_messages]
B --> C[Process events]
C --> D[heartbeat renew reservations]
D --> E[Update since with polled_until]
E --> B
```

Loop outcomes:
- Presence stays fresh.
- Reservations remain valid.
- Incoming changes are consumed in near real-time.

## 7. Error Handling Logic

Common error families:
- Unauthorized: missing or expired credentials.
- not_found: invalid room, agent, or reservation identifier.
- validation_error: invalid payload or conflict constraints.
- JSON-RPC protocol errors: malformed request or unknown method.

```mermaid
flowchart TD
A[Tool call fails] --> B{Error type}
B -->|Unauthorized| C[Re-run macro_start_session and refresh headers]
B -->|not_found| D[Verify ids and room membership]
B -->|validation_error| E[Fix payload or resolve conflicts]
B -->|protocol error| F[Correct method name/request shape]
C --> G[Retry call]
D --> G
E --> G
F --> G
```

## 8. End-to-End System Logic

The complete operating logic from start to finish:

```mermaid
flowchart TD
A[Fetch latest setup instructions] --> B[Start or resume session]
B --> C[Store credentials]
C --> D[Join room and announce plan]
D --> E[Conflict check and reserve files]
E --> F[Implement changes]
F --> G[Poll and heartbeat loop]
G --> H[Release reservations]
H --> I[Send completion message]
I --> J[Set status offline]
```

## 9. Practical Operating Rules

- Always start with macro_start_session.
- Treat auth headers as mandatory for every request.
- Never edit shared files without a reservation.
- Keep poll and heartbeat running while active.
- Release reservations quickly after edits.
- Communicate changes of intent in the room.

## 10. Relationship to the Tool-by-Tool Reference

Use docs/MCP_TOOLS_REFERENCE.md for per-tool usage details and per-tool procedure diagrams.
Use this document for system-level understanding, architecture reasoning, and operating model decisions.
