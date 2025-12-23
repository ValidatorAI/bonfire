#!/bin/bash
# Cleanup MCP session - release reservations and send departure message
# Called automatically at session end via hooks

set -e

MCP_SERVER_URL="${MCP_SERVER_URL:-http://localhost:3000/mcp}"
PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"
TOKEN_FILE="${HOME}/.mcp_agent_token_$(echo "$PROJECT_PATH" | md5sum | cut -d' ' -f1)"

# Get token
if [ -f "$TOKEN_FILE" ]; then
    MCP_TOKEN=$(cat "$TOKEN_FILE")
elif [ -n "$MCP_TOKEN" ]; then
    : # Use environment variable
else
    # Not registered, nothing to clean up
    exit 0
fi

# Check if server is reachable
if ! curl -s "${MCP_SERVER_URL%/mcp}/mcp/health" > /dev/null 2>&1; then
    # Server not running, clean up local state only
    rm -f "$TOKEN_FILE" 2>/dev/null || true
    exit 0
fi

# Get our reservations
RESULT=$(curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MCP_TOKEN" \
    -d '{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "list_reservations",
            "arguments": {}
        }
    }')

# Extract reservation IDs (simple parsing)
# Look for our agent's reservations and release them
RESERVATION_IDS=$(echo "$RESULT" | grep -oE '"id":[0-9]+' | grep -oE '[0-9]+')

for RESERVATION_ID in $RESERVATION_IDS; do
    curl -s -X POST "$MCP_SERVER_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $MCP_TOKEN" \
        -d '{
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {
                "name": "release_reservation",
                "arguments": {
                    "reservation_id": '"$RESERVATION_ID"'
                }
            }
        }' > /dev/null 2>&1 || true
done

# Get room ID from agent profile
PROFILE=$(curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MCP_TOKEN" \
    -d '{
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": {
            "name": "get_agent_profile",
            "arguments": {}
        }
    }')

# Extract room_id (first room is usually the project room)
ROOM_ID=$(echo "$PROFILE" | grep -oE '"room_id":[0-9]+' | head -1 | grep -oE '[0-9]+')

if [ -n "$ROOM_ID" ]; then
    # Send departure message
    curl -s -X POST "$MCP_SERVER_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $MCP_TOKEN" \
        -d '{
            "jsonrpc": "2.0",
            "id": 4,
            "method": "tools/call",
            "params": {
                "name": "send_message",
                "arguments": {
                    "room_id": '"$ROOM_ID"',
                    "body": "Session ended, signing off."
                }
            }
        }' > /dev/null 2>&1 || true
fi

# Clean up local token file
rm -f "$TOKEN_FILE" 2>/dev/null || true

echo "MCP session cleaned up"
