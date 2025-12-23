#!/bin/bash
# Cleanup MCP session - release reservations and send departure message
# Called automatically at session end via hooks

MCP_SERVER_URL="${MCP_SERVER_URL:-http://localhost:3000/mcp}"
PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"

PROJECT_HASH=$(echo "$PROJECT_PATH" | md5sum | cut -d' ' -f1)

# Find agent ID file for this session
if [ -n "$MCP_SESSION_ID" ]; then
    AGENT_ID_FILE="${HOME}/.mcp_agent_id_${PROJECT_HASH}_${MCP_SESSION_ID}"
else
    AGENT_ID_FILE=$(ls -t ${HOME}/.mcp_agent_id_${PROJECT_HASH}_* 2>/dev/null | head -1)
fi

# Get agent ID
if [ -n "$MCP_AGENT_ID" ]; then
    AGENT_ID="$MCP_AGENT_ID"
elif [ -n "$AGENT_ID_FILE" ] && [ -f "$AGENT_ID_FILE" ]; then
    AGENT_ID=$(cat "$AGENT_ID_FILE")
else
    echo "No agent registered for this session"
    exit 0
fi

# Release all reservations
curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -H "X-Agent-Id: $AGENT_ID" \
    -d '{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "update_agent_status",
            "arguments": {"status": "offline"}
        }
    }' > /dev/null 2>&1

# Clean up session files
if [ -n "$AGENT_ID_FILE" ] && [ -f "$AGENT_ID_FILE" ]; then
    rm -f "$AGENT_ID_FILE"
fi

if [ -n "$MCP_SESSION_ID" ]; then
    rm -f "${HOME}/.mcp_agent_token_${PROJECT_HASH}_${MCP_SESSION_ID}"
fi

echo "Session cleaned up"
