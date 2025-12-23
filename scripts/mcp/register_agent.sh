#!/bin/bash
# MCP Agent Registration - creates a new agent identity
# Use --list to see existing agents, --resume <name> to reuse one

set -e

MCP_SERVER_URL="${MCP_SERVER_URL:-http://localhost:3000/mcp}"
PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"
AGENT_PROGRAM="${AGENT_PROGRAM:-Claude Code}"
AGENT_MODEL="${AGENT_MODEL:-claude-opus-4-5-20251101}"
TASK_DESCRIPTION="${TASK_DESCRIPTION:-Working on project}"

PROJECT_HASH=$(echo "$PROJECT_PATH" | md5sum | cut -d' ' -f1)
AGENTS_DIR="${HOME}/.mcp_agents/${PROJECT_HASH}"
mkdir -p "$AGENTS_DIR"

# Handle --list flag
if [ "$1" = "--list" ]; then
    echo "Registered agents for this project:"
    ls "$AGENTS_DIR"/*.agent 2>/dev/null | while read -r f; do
        name=$(basename "$f" .agent)
        info=$(cat "$f")
        echo "  - $name (id: $(echo "$info" | cut -d: -f1))"
    done
    exit 0
fi

# Handle --resume flag
if [ "$1" = "--resume" ]; then
    AGENT_NAME="$2"
    if [ -z "$AGENT_NAME" ]; then
        echo "Usage: register_agent.sh --resume <agent_name>" >&2
        exit 1
    fi
    
    AGENT_FILE="$AGENTS_DIR/${AGENT_NAME}.agent"
    if [ ! -f "$AGENT_FILE" ]; then
        echo "Agent '$AGENT_NAME' not found. Use --list to see available agents." >&2
        exit 1
    fi
    
    AGENT_ID=$(cut -d: -f1 < "$AGENT_FILE")
    
    curl -s -X POST "$MCP_SERVER_URL" \
        -H "Content-Type: application/json" \
        -H "X-Agent-Id: $AGENT_ID" \
        -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"update_agent_status","arguments":{"status":"online"}}}' > /dev/null
    
    echo "$AGENT_NAME" > "$AGENTS_DIR/.current"
    echo "Resumed as $AGENT_NAME (id: $AGENT_ID)"
    exit 0
fi

# Check if server is reachable
if ! curl -s "${MCP_SERVER_URL%/mcp}/mcp/health" > /dev/null 2>&1; then
    echo "Warning: MCP server not reachable at $MCP_SERVER_URL" >&2
    exit 0
fi

# Register new agent
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

if echo "$RESULT" | grep -q '"error"'; then
    echo "Registration failed: $RESULT" >&2
    exit 1
fi

INNER_JSON=$(echo "$RESULT" | sed 's/.*"text":"//; s/"}\]}}$//' | sed 's/\\"/"/g' | sed 's/\\\\/\\/g')
AGENT_ID=$(echo "$INNER_JSON" | grep -oE '"agent":\{"id":[0-9]+' | grep -oE '[0-9]+$')
AGENT_NAME=$(echo "$INNER_JSON" | grep -oE '"agent":\{[^}]*"name":"[^"]*"' | grep -oE '"name":"[^"]*"' | sed 's/"name":"//; s/"$//')
ROOM_ID=$(echo "$INNER_JSON" | grep -oE '"room":\{"id":[0-9]*' | grep -oE '[0-9]+$')

echo "${AGENT_ID}:${ROOM_ID}" > "$AGENTS_DIR/${AGENT_NAME}.agent"
chmod 600 "$AGENTS_DIR/${AGENT_NAME}.agent"
echo "$AGENT_NAME" > "$AGENTS_DIR/.current"

echo "Registered as $AGENT_NAME (id: $AGENT_ID, room: $ROOM_ID)"
