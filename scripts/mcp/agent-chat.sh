#!/bin/bash
# MCP Agent Chat - Unified CLI
# Usage: agent-chat.sh [--agent <name>] <command> [args...]

set -e

MCP_SERVER_URL="${MCP_SERVER_URL:-http://localhost:3000/mcp}"
PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"
PROJECT_HASH=$(echo "$PROJECT_PATH" | md5sum | cut -d' ' -f1)
AGENTS_DIR="${HOME}/.mcp_agents/${PROJECT_HASH}"

# Parse --agent flag
AGENT_NAME=""
if [ "$1" = "--agent" ]; then
    AGENT_NAME="$2"
    shift 2
fi

COMMAND="${1:-}"
shift 2>/dev/null || true

# Get agent ID - from specified name, current marker, or fail
get_agent_id() {
    local name="$AGENT_NAME"
    
    if [ -z "$name" ] && [ -f "$AGENTS_DIR/.current" ]; then
        name=$(cat "$AGENTS_DIR/.current")
    fi
    
    if [ -z "$name" ]; then
        echo "Error: No agent specified. Use --agent <name> or run register_agent.sh first." >&2
        exit 1
    fi
    
    local agent_file="$AGENTS_DIR/${name}.agent"
    if [ ! -f "$agent_file" ]; then
        echo "Error: Agent '$name' not found. Run: scripts/mcp/register_agent.sh --list" >&2
        exit 1
    fi
    
    cut -d: -f1 < "$agent_file"
}

# MCP call helper
mcp_call() {
    local tool_name="$1"
    local arguments="$2"
    local agent_id=$(get_agent_id)

    local response=$(curl -s -X POST "$MCP_SERVER_URL" \
        -H "Content-Type: application/json" \
        -H "X-Agent-Id: $agent_id" \
        -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"'"$tool_name"'","arguments":'"$arguments"'}}')

    echo "$response" | sed 's/.*"text":"//; s/"}\]}}$//' | sed 's/\\"/"/g' | sed 's/\\\\/\\/g'
}

json_escape() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g; s/\t/\\t/g'
}

# Extract room ID from profile - handles both formats
get_room_id() {
    local profile="$1"
    local room_id
    
    # Try direct room object
    room_id=$(echo "$profile" | grep -oE '"room":\{"id":[0-9]+' | grep -oE '[0-9]+$')
    
    # Fallback: rooms array - use sed for reliable extraction
    if [ -z "$room_id" ]; then
        room_id=$(echo "$profile" | sed -n 's/.*"rooms":\[{"id":\([0-9]*\).*/\1/p')
    fi
    
    echo "$room_id"
}

cmd_status() {
    local profile=$(mcp_call "get_agent_profile" "{}")
    local name=$(echo "$profile" | grep -oE '"name":"[^"]*"' | head -1 | sed 's/"name":"//; s/"$//')
    local status=$(echo "$profile" | grep -oE '"status":"[^"]*"' | head -1 | sed 's/"status":"//; s/"$//')
    local model=$(echo "$profile" | grep -oE '"model":"[^"]*"' | head -1 | sed 's/"model":"//; s/"$//')
    local task=$(echo "$profile" | grep -oE '"task_description":"[^"]*"' | head -1 | sed 's/"task_description":"//; s/"$//')

    echo "=== Agent Profile ==="
    echo "Name: ${name:-Unknown}"
    echo "Status: ${status:-unknown}"
    echo "Model: ${model:-unknown}"
    echo "Task: ${task:-None}"

    echo ""
    echo "=== Reservations ==="
    local reservations=$(mcp_call "list_reservations" "{}")
    if echo "$reservations" | grep -q '"reservations":\[\]'; then
        echo "No active reservations"
    else
        echo "$reservations" | grep -oE '"id":[0-9]+|"patterns":\[[^]]*\]|"reason":"[^"]*"' | while read -r line; do
            echo "  $line"
        done
    fi
}

cmd_chat() {
    local message="$*"
    [ -z "$message" ] && { echo "Usage: agent-chat.sh chat <message>" >&2; exit 1; }

    local profile=$(mcp_call "get_agent_profile" "{}")
    local room_id=$(get_room_id "$profile")
    [ -z "$room_id" ] && { echo "Error: Could not determine room ID" >&2; exit 1; }

    local msg_escaped=$(json_escape "$message")
    mcp_call "send_message" '{"room_id":'"$room_id"',"body":"'"$msg_escaped"'"}' > /dev/null
    echo "Message sent"
}

cmd_messages() {
    local limit="${1:-20}"
    
    local profile=$(mcp_call "get_agent_profile" "{}")
    local room_id=$(get_room_id "$profile")
    [ -z "$room_id" ] && { echo "Error: Could not determine room ID" >&2; exit 1; }

    local result=$(mcp_call "fetch_messages" '{"room_id":'"$room_id"',"limit":'"$limit"'}')

    echo "=== Recent Messages ==="
    # Parse messages - extract creator name and body
    echo "$result" | grep -oE '"body":"[^"]*"|"name":"[^"]*"' | while read -r line; do
        if echo "$line" | grep -q '"name"'; then
            name=$(echo "$line" | sed 's/"name":"//; s/"$//')
            printf "\n[%s]: " "$name"
        elif echo "$line" | grep -q '"body"'; then
            body=$(echo "$line" | sed 's/"body":"//; s/"$//')
            echo "$body"
        fi
    done
    echo ""
}

cmd_reserve() {
    local pattern="$1"
    local reason="${2:-Working on files}"
    [ -z "$pattern" ] && { echo "Usage: agent-chat.sh reserve <pattern> [reason]" >&2; exit 1; }

    local result=$(mcp_call "reserve_files" '{"patterns":["'"$(json_escape "$pattern")"'"],"reason":"'"$(json_escape "$reason")"'","exclusive":true}')
    
    if echo "$result" | grep -q '"success":false'; then
        echo "Reservation failed - conflicts exist" >&2
        exit 1
    fi
    
    local res_id=$(echo "$result" | grep -oE '"reservation_id":[0-9]+' | grep -oE '[0-9]+')
    echo "Reserved: $pattern (id: $res_id)"
}

cmd_release() {
    local arg="${1:-all}"
    if [ "$arg" = "all" ]; then
        local list=$(mcp_call "list_reservations" "{}")
        local ids=$(echo "$list" | grep -oE '"id":[0-9]+' | grep -oE '[0-9]+')
        [ -z "$ids" ] && { echo "No reservations to release"; exit 0; }
        for id in $ids; do
            mcp_call "release_reservation" '{"reservation_id":'"$id"'}' > /dev/null
            echo "Released $id"
        done
    else
        mcp_call "release_reservation" '{"reservation_id":'"$arg"'}' > /dev/null
        echo "Released $arg"
    fi
}

cmd_agents() {
    local result=$(mcp_call "list_agents" '{"include_self":true}')
    echo "=== Active Agents ==="
    echo "$result" | grep -oE '"name":"[^"]*"' | sed 's/"name":"//g; s/"//g' | while read -r n; do
        [ -n "$n" ] && echo "- $n"
    done
}

case "$COMMAND" in
    status) cmd_status ;;
    chat) cmd_chat "$@" ;;
    messages|msgs) cmd_messages "$@" ;;
    reserve) cmd_reserve "$@" ;;
    release) cmd_release "$@" ;;
    agents) cmd_agents ;;
    *)
        echo "Usage: agent-chat.sh [--agent <name>] <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  status              Show agent profile and reservations"
        echo "  chat <message>      Send message to project room"
        echo "  messages [limit]    Read recent messages (default: 20)"
        echo "  reserve <pattern>   Reserve files (optional: reason)"
        echo "  release [id|all]    Release reservations (default: all)"
        echo "  agents              List active agents in project"
        echo ""
        echo "Use --agent to specify which registered agent to act as."
        echo "Run 'register_agent.sh --list' to see available agents."
        ;;
esac
