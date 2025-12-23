#!/bin/bash
# Release file reservations
# Usage: scripts/mcp/release_files.sh [reservation_id|all]
# Example: scripts/mcp/release_files.sh 123
# Example: scripts/mcp/release_files.sh all

set -e

RESERVATION_ARG="${1:-all}"

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

# Get our reservations first
LIST_RESULT=$(curl -s -X POST "$MCP_SERVER_URL" \
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

if [ "$RESERVATION_ARG" = "all" ]; then
    # Extract all reservation IDs
    RESERVATION_IDS=$(echo "$LIST_RESULT" | grep -oE '"id":[0-9]+' | grep -oE '[0-9]+')

    if [ -z "$RESERVATION_IDS" ]; then
        echo "No active reservations to release"
        exit 0
    fi

    RELEASED=0
    for RESERVATION_ID in $RESERVATION_IDS; do
        RESULT=$(curl -s -X POST "$MCP_SERVER_URL" \
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
            }')

        if echo "$RESULT" | grep -q '"success":true'; then
            echo "Released reservation $RESERVATION_ID"
            RELEASED=$((RELEASED + 1))
        fi
    done

    echo "Released $RELEASED reservation(s)"
else
    # Release specific reservation
    RESERVATION_ID="$RESERVATION_ARG"

    RESULT=$(curl -s -X POST "$MCP_SERVER_URL" \
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
        }')

    if echo "$RESULT" | grep -q '"error"'; then
        echo "Failed to release: $RESULT" >&2
        exit 1
    fi

    if echo "$RESULT" | grep -q '"success":false'; then
        echo "Could not release reservation $RESERVATION_ID (may not exist or belong to you)" >&2
        exit 1
    fi

    echo "Released reservation $RESERVATION_ID"
fi
