#!/bin/bash
# MCP Agent Registration Script
# Called automatically at session start via hooks
# Can also be sourced manually: source scripts/mcp/register_agent.sh

set -e

MCP_SERVER_URL="${MCP_SERVER_URL:-http://localhost:3000/mcp}"
PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"
AGENT_PROGRAM="${AGENT_PROGRAM:-Claude Code}"
AGENT_MODEL="${AGENT_MODEL:-claude-opus-4-5-20251101}"
TASK_DESCRIPTION="${TASK_DESCRIPTION:-Working on project}"

# Agent ID storage location (used for header-based auth)
AGENT_ID_FILE="${HOME}/.mcp_agent_id_$(echo "$PROJECT_PATH" | md5sum | cut -d' ' -f1)"
# Legacy token storage (still supported)
TOKEN_FILE="${HOME}/.mcp_agent_token_$(echo "$PROJECT_PATH" | md5sum | cut -d' ' -f1)"

# Check if server is reachable
if ! curl -s "${MCP_SERVER_URL%/mcp}/mcp/health" > /dev/null 2>&1; then
    echo "Warning: MCP server not reachable at $MCP_SERVER_URL" >&2
    exit 0  # Don't fail - server may not be running
fi

# Register agent using macro_start_session
RESULT=$(curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "macro_start_session",
            "arguments": {
                "project_path": "'"$PROJECT_PATH"'",
                "program": "'"$AGENT_PROGRAM"'",
                "model": "'"$AGENT_MODEL"'",
                "task_description": "'"$TASK_DESCRIPTION"'"
            }
        }
    }')

# Check for errors
if echo "$RESULT" | grep -q '"error"'; then
    echo "Registration failed: $RESULT" >&2
    exit 1
fi

# Extract agent info using basic text parsing (no jq dependency)
# Response format: {"result":{"content":[{"type":"text","text":"{\"agent\":{\"id\":...,\"name\":\"...\"},...}"}]}}
INNER_JSON=$(echo "$RESULT" | sed 's/.*"text":"//; s/"}\]}}$//' | sed 's/\\"/"/g' | sed 's/\\\\/\\/g')
AGENT_ID=$(echo "$INNER_JSON" | grep -oE '"agent":\{"id":[0-9]+' | grep -oE '[0-9]+$')
AGENT_NAME=$(echo "$INNER_JSON" | grep -oE '"agent":\{[^}]*"name":"[^"]*"' | grep -oE '"name":"[^"]*"' | sed 's/"name":"//; s/"$//')
ROOM_ID=$(echo "$INNER_JSON" | grep -oE '"room":\{"id":[0-9]*' | grep -oE '[0-9]+$')
API_TOKEN=$(echo "$INNER_JSON" | grep -oE '"api_token":"[^"]*"' | sed 's/"api_token":"//; s/"$//')

# Store agent ID for header-based auth (preferred method)
echo "$AGENT_ID" > "$AGENT_ID_FILE"
chmod 600 "$AGENT_ID_FILE"

# Store token for legacy compatibility
if [ -n "$API_TOKEN" ]; then
    echo "$API_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
fi

# Export for current session
export MCP_AGENT_ID="$AGENT_ID"
export MCP_TOKEN="$API_TOKEN"
export MCP_AGENT_NAME="$AGENT_NAME"
export MCP_ROOM_ID="$ROOM_ID"

echo "Registered as $AGENT_NAME (id: $AGENT_ID, room: $ROOM_ID)"
