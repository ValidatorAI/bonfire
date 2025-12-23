#!/bin/bash
# Send a message to the project room
# Usage: scripts/mcp/send_message.sh "Your message here"

set -e

MESSAGE="${1:-}"
if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <message>" >&2
    exit 1
fi

MCP_SERVER_URL="${MCP_SERVER_URL:-http://localhost:3000/mcp}"
PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"
TOKEN_FILE="${HOME}/.mcp_agent_token_$(echo "$PROJECT_PATH" | md5sum | cut -d' ' -f1)"

# Get token
if [ -f "$TOKEN_FILE" ]; then
    MCP_TOKEN=$(cat "$TOKEN_FILE")
elif [ -n "$MCP_TOKEN" ]; then
    : # Use environment variable
else
    echo "Error: Not registered. Run register_agent.sh first." >&2
    exit 1
fi

# Get room ID from agent profile
PROFILE=$(curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MCP_TOKEN" \
    -d '{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "get_agent_profile",
            "arguments": {}
        }
    }')

# Extract first room_id (project room)
ROOM_ID="${MCP_ROOM_ID:-}"
if [ -z "$ROOM_ID" ]; then
    ROOM_ID=$(echo "$PROFILE" | grep -oE '"room_id":[0-9]+' | head -1 | grep -oE '[0-9]+')
fi

if [ -z "$ROOM_ID" ]; then
    echo "Error: Could not determine room ID" >&2
    exit 1
fi

# Escape message for JSON
MESSAGE_ESCAPED=$(echo "$MESSAGE" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g')

# Send message
RESULT=$(curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MCP_TOKEN" \
    -d '{
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {
            "name": "send_message",
            "arguments": {
                "room_id": '"$ROOM_ID"',
                "body": "'"$MESSAGE_ESCAPED"'"
            }
        }
    }')

if echo "$RESULT" | grep -q '"error"'; then
    echo "Failed to send message: $RESULT" >&2
    exit 1
fi

echo "Message sent to room $ROOM_ID"
