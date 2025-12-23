#!/bin/bash
# Reserve files for editing
# Usage: scripts/mcp/reserve_files.sh <pattern> [reason]
# Example: scripts/mcp/reserve_files.sh "app/models/**/*.rb" "Refactoring models"

set -e

PATTERN="${1:-}"
REASON="${2:-Working on files}"

if [ -z "$PATTERN" ]; then
    echo "Usage: $0 <pattern> [reason]" >&2
    echo "Example: $0 'app/models/**/*.rb' 'Refactoring models'" >&2
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

# Escape pattern for JSON
PATTERN_ESCAPED=$(echo "$PATTERN" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
REASON_ESCAPED=$(echo "$REASON" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

# First check for conflicts
CHECK_RESULT=$(curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MCP_TOKEN" \
    -d '{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "check_conflicts",
            "arguments": {
                "patterns": ["'"$PATTERN_ESCAPED"'"]
            }
        }
    }')

if echo "$CHECK_RESULT" | grep -q '"has_conflicts":true'; then
    echo "Warning: Conflicts detected with existing reservations" >&2
    echo "Use /agents to see who holds conflicting reservations" >&2
    echo "Proceeding anyway (will create non-exclusive reservation if exclusive fails)..." >&2
fi

# Reserve files
RESULT=$(curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MCP_TOKEN" \
    -d '{
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {
            "name": "reserve_files",
            "arguments": {
                "patterns": ["'"$PATTERN_ESCAPED"'"],
                "reason": "'"$REASON_ESCAPED"'",
                "exclusive": true
            }
        }
    }')

if echo "$RESULT" | grep -q '"success":false'; then
    echo "Exclusive reservation failed due to conflicts" >&2
    echo "Conflicts: $(echo "$RESULT" | grep -oE '"conflicts":\[[^]]*\]')" >&2
    exit 1
fi

if echo "$RESULT" | grep -q '"error"'; then
    echo "Failed to reserve: $RESULT" >&2
    exit 1
fi

# Extract reservation info
RESERVATION_ID=$(echo "$RESULT" | grep -oE '"reservation_id":[0-9]+' | grep -oE '[0-9]+')
EXPIRES_AT=$(echo "$RESULT" | grep -oE '"expires_at":"[^"]*"' | sed 's/"expires_at":"//;s/"//')

echo "Reserved: $PATTERN"
echo "Reservation ID: $RESERVATION_ID"
echo "Expires: $EXPIRES_AT"
echo "Reason: $REASON"
