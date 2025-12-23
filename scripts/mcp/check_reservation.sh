#!/bin/bash
# Check for file reservation conflicts before editing
# Usage: scripts/mcp/check_reservation.sh <file_path>
# Called automatically by pre-edit hooks

set -e

FILE_PATH="${1:-}"
if [ -z "$FILE_PATH" ]; then
    echo "Usage: $0 <file_path>" >&2
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
    # Not registered, can't check - allow edit
    exit 0
fi

# Check if server is reachable
if ! curl -s "${MCP_SERVER_URL%/mcp}/mcp/health" > /dev/null 2>&1; then
    # Server not running, allow edit
    exit 0
fi

# Convert absolute path to relative if needed
if [[ "$FILE_PATH" == /* ]]; then
    FILE_PATH="${FILE_PATH#$PROJECT_PATH/}"
fi

# Check for conflicts
RESULT=$(curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MCP_TOKEN" \
    -d '{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "check_conflicts",
            "arguments": {
                "patterns": ["'"$FILE_PATH"'"]
            }
        }
    }')

# Check if there are conflicts
if echo "$RESULT" | grep -q '"has_conflicts":true'; then
    # Extract conflict info
    CONFLICTS=$(echo "$RESULT" | sed 's/.*"conflicts":\[\([^]]*\)\].*/\1/')

    echo "WARNING: File reservation conflict detected!" >&2
    echo "File: $FILE_PATH" >&2
    echo "Another agent has reserved files that may conflict." >&2
    echo "Use /agents to see who, and /chat to coordinate." >&2

    # Return non-zero but don't block (hook configured with onFailure: warn)
    exit 1
fi

# No conflicts
exit 0
