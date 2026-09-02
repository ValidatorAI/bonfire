# Bonfire HTTP API

Read-only-ish JSON API for automating Bonfire from external services (bots, integrations,
CI, etc.). All endpoints live under `/api` and share one authorization strategy.

## Authentication

Every request must include a bearer token that matches the `OUTPUT_EVENTS_TOKEN`
environment variable configured on the server:

```
Authorization: Bearer <OUTPUT_EVENTS_TOKEN>
```

- Missing/incorrect token → `401 Unauthorized`
- `OUTPUT_EVENTS_TOKEN` not set on the server → `500` (fails closed)

Implemented in [`Api::BaseController`](../app/controllers/api/base_controller.rb).

## Endpoint List

"Realtime" means the request also broadcasts a Turbo Stream / ActionCable
update to connected web clients in that room, in addition to the JSON response.

| Method | Path | Description | Realtime |
|---|---|---|---|
| GET | `/api/projects` | List all projects | No |
| GET | `/api/projects/:id` | Get a single project (by id or slug) | No |
| GET | `/api/projects/:project_id/rooms` | List all rooms of a project | No |
| GET | `/api/projects/:project_id/rooms/:id` | Get a single room | No |
| GET | `/api/projects/:project_id/rooms/:id/threads` | Get a room's threads (child rooms) | No |
| GET | `/api/projects/:project_id/rooms/search?q=` | Fuzzy search rooms by name | No |
| GET | `/api/projects/:project_id/rooms/:room_id/messages` | List messages of a room (paginated or not, includes `count`) | No |
| POST | `/api/projects/:project_id/rooms/:room_id/messages` | Post a message and/or file, on behalf of a user | **Yes** — Turbo Stream append + unread broadcast |
| GET | `/api/projects/:project_id/rooms/:room_id/messages/:id` | Get a single message | No |
| PATCH/PUT | `/api/projects/:project_id/rooms/:room_id/messages/:id` | Update a message's body and/or attachment | **Yes** — Turbo Stream replace |
| DELETE | `/api/projects/:project_id/rooms/:room_id/messages/:id` | Delete a message | **Yes** — Turbo Stream remove |
| GET | `/api/projects/:project_id/rooms/:room_id/messages/:id/attachment` | Download a message's uploaded file | No |
| GET | `/api/messages/:id` | Get a single message (flat, no project/room needed) | No |
| PATCH/PUT | `/api/messages/:id` | Update a message (flat) | **Yes** — Turbo Stream replace |
| DELETE | `/api/messages/:id` | Delete a message (flat) | **Yes** — Turbo Stream remove |
| GET | `/api/messages/:id/attachment` | Download a message's uploaded file (flat) | No |
| POST | `/api/projects/:project_id/rooms/:room_id/actions` | Send a real-time action (e.g. typing indicator) on behalf of a user | **Yes** — ActionCable broadcast (that's its only purpose) |
| POST | `/api/projects/:project_id/rooms/:room_id/decisions` | Approve/confirm/deny/cancel an approval request on behalf of a user | **Yes** — Turbo Stream replace of the approval request card |

Note: message ids are globally unique (not scoped per room), so the flat
`/api/messages/:id` routes work regardless of which room the message belongs to.

---

## Projects

### `GET /api/projects`

Returns all projects.

**Response** `200`
```json
[
  { "id": 1, "name": "Acme", "slug": "acme", "path": "...", "description": null, "private": false,
    "short_code": null, "current_phase": "Phase 1: Project Setup", "progress_percent": 0,
    "roadmap": null, "recently_completed": null, "budget_total": "0.0", "budget_spent": "0.0",
    "created_at": "...", "updated_at": "..." }
]
```

### `GET /api/projects/:id`

`:id` may be the numeric primary key or the project `slug`.

**Response** `200` — single project object (same shape as above).
**Errors** `404` — project not found.

---

## Rooms

### `GET /api/projects/:project_id/rooms`

Lists all rooms belonging to the project.

**Response** `200`
```json
[
  { "id": 1, "name": "General", "type": "Rooms::Project", "description": null, "private": false,
    "parent_id": null, "project_id": 1, "creator_id": 1, "archived_at": null,
    "created_at": "...", "updated_at": "..." }
]
```

### `GET /api/projects/:project_id/rooms/:id`

Single room lookup, scoped to the project.

**Errors** `404` — project or room not found (or room belongs to a different project).

### `GET /api/projects/:project_id/rooms/:id/threads`

Returns the room's threads — child rooms whose `parent_id` points to `:id`.

**Response** `200` — array of room objects (same shape as index).

### `GET /api/projects/:project_id/rooms/search?q=<term>`

Fuzzy, case-insensitive substring search on room name, ranked by relevance
(exact match > starts-with > contains).

**Errors**
- `400` — missing `q` param
- `404` — project not found

---

## Messages

### `GET /api/projects/:project_id/rooms/:room_id/messages`

Supports both modes:

- No `page` param → `{ "count": N, "messages": [...] }` (full list, chronological order).
- With `page` param → `{ "count": N, "page": P, "per_page": PP, "messages": [...] }`
  (offset/limit paginated; `per_page` default 40, max 200).

Each message serializes as:
```json
{
  "id": 1, "room_id": 1, "creator_id": 1, "creator_type": "User",
  "system": false, "system_type": null, "created_at": "...", "updated_at": "...",
  "body": "plain text body",
  "has_attachment": false, "attachment_filename": null,
  "attachment_content_type": null, "attachment_url": null
}
```

### `POST /api/projects/:project_id/rooms/:room_id/messages`

Creates a message on behalf of a user. Accepts `body` and/or a multipart
`attachment` file — at least one is required.

**Params**: `user_id` (required), `body` (optional), `attachment` (optional file)

**Realtime:** Yes — broadcasts a Turbo Stream append to the room and an `unread_rooms` ActionCable event.

**Response** `201` — the created message (same shape as above).
**Errors**
- `404` — project, room, or user not found
- `400` — neither `body` nor `attachment` provided
- `422` — validation error

### `GET /api/projects/:project_id/rooms/:room_id/messages/:id`

Single message lookup, scoped to the room.

### `PATCH`/`PUT /api/projects/:project_id/rooms/:room_id/messages/:id`

Updates a message's `body` and/or `attachment` (at least one required).

**Realtime:** Yes — broadcasts a Turbo Stream replace, mirroring the web app's edit flow.

### `DELETE /api/projects/:project_id/rooms/:room_id/messages/:id`

Deletes the message and broadcasts removal. Returns `204 No Content`.

**Realtime:** Yes — broadcasts a Turbo Stream remove.

### `GET /api/projects/:project_id/rooms/:room_id/messages/:id/attachment`

Streams the message's uploaded file.

**Query param**: `disposition=attachment` forces a download instead of inline display.

**Errors** `404` — project/room/message not found, or message has no attachment.

### Flat message routes

Since message `id`s are globally unique, the following equivalent routes work
without needing `project_id`/`room_id` in the path:

- `GET /api/messages/:id`
- `PATCH`/`PUT /api/messages/:id`
- `DELETE /api/messages/:id`
- `GET /api/messages/:id/attachment`

Same params, behavior, and responses as their nested counterparts above.

---

## Actions

### `POST /api/projects/:project_id/rooms/:room_id/actions`

Broadcasts a real-time action to the room on behalf of a user (e.g. typing
indicators), the same mechanism the web client uses.

**Realtime:** Yes — this endpoint's only effect is an ActionCable broadcast; there is no persisted resource.

**Params**: `user_id` (required), `action_type` (required — one of `typing_start`, `typing_stop`)

> Note: the param is `action_type`, not `action` — `params[:action]` is reserved
> by Rails routing and always resolves to the controller action name.

**Response** `202 Accepted`
```json
{ "status": "ok", "action": "typing_start" }
```

**Errors**
- `404` — project, room, or user not found
- `400` — unsupported `action_type`

---

## Decisions

### `POST /api/projects/:project_id/rooms/:room_id/decisions`

Resolves an approval request (a "decision") on behalf of a user.

**Params**:
- `user_id` (required)
- `approval_request_id` (required — must belong to the room)
- `decision` (required — one of `approve`, `confirm`, `deny`, `cancel`)
- `note` (optional)

**Realtime:** Yes — broadcasts a Turbo Stream replace of the approval request card in the room.

**Response** `200` — the updated approval request:
```json
{
  "id": 1, "room_id": 1, "message_id": null, "agent_id": null,
  "request_type": "decision", "status": "approved",
  "requested_at": "...", "resolved_at": "...", "resolved_by_id": 1
}
```

**Errors**
- `404` — project, room, user, or approval request not found (or approval
  request belongs to a different room)
- `400` — unsupported `decision`
- `422` — validation error

---

## Source Files

- Auth: [`app/controllers/api/base_controller.rb`](../app/controllers/api/base_controller.rb)
- Projects: [`app/controllers/api/projects_controller.rb`](../app/controllers/api/projects_controller.rb)
- Rooms: [`app/controllers/api/rooms_controller.rb`](../app/controllers/api/rooms_controller.rb)
- Messages: [`app/controllers/api/messages_controller.rb`](../app/controllers/api/messages_controller.rb)
- Actions: [`app/controllers/api/actions_controller.rb`](../app/controllers/api/actions_controller.rb)
- Decisions: [`app/controllers/api/decisions_controller.rb`](../app/controllers/api/decisions_controller.rb)
- Routes: [`config/routes.rb`](../config/routes.rb) (`namespace :api`)
- Tests: `test/controllers/api/*_test.rb`
