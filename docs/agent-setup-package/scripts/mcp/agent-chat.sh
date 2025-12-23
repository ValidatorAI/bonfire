#!/bin/bash
# MCP Agent Chat - Unified CLI
# Usage: agent-chat.sh <command> [args...]
#
# Commands:
#   status              - Show agent profile and reservations
#   chat <message>      - Send message to project room
#   reserve <pattern>   - Reserve files (optional: reason)
#   release [id|all]    - Release reservations (default: all)
#   agents              - List active agents in project

set -e

COMMAND="${1:-}"
shift 2>/dev/null || true

MCP_SERVER_URL="${MCP_SERVER_URL:-http://localhost:3000/mcp}"
PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"
AGENT_ID_FILE="${HOME}/.mcp_agent_id_$(echo "$PROJECT_PATH" | md5sum | cut -d' ' -f1)"
TOKEN_FILE="${HOME}/.mcp_agent_token_$(echo "$PROJECT_PATH" | md5sum | cut -d' ' -f1)"

# Helper: Get agent ID for header-based auth
get_agent_id() {
    if [ -n "$MCP_AGENT_ID" ]; then
        echo "$MCP_AGENT_ID"
    elif [ -f "$AGENT_ID_FILE" ]; then
        cat "$AGENT_ID_FILE"
    else
        echo "Error: Not registered. Run register_agent.sh first." >&2
        exit 1
    fi
}

# Helper: Make MCP call and extract inner JSON
mcp_call() {
    local tool_name="$1"
    local arguments="$2"
    local agent_id=$(get_agent_id)

    local response=$(curl -s -X POST "$MCP_SERVER_URL" \
        -H "Content-Type: application/json" \
        -H "X-Agent-Id: $agent_id" \
        -d '{
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {
                "name": "'"$tool_name"'",
                "arguments": '"$arguments"'
            }
        }')

    # Extract inner JSON from result.content[0].text
    # Response format: {"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"{...}"}]}}
    echo "$response" | sed 's/.*"text":"//; s/"}\]}}$//' | sed 's/\\"/"/g' | sed 's/\\\\/\\/g'
}

# Helper: Escape string for JSON
json_escape() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g; s/\t/\\t/g'
}

# Command: status
cmd_status() {
    echo "=== Agent Profile ==="
    local profile=$(mcp_call "get_agent_profile" "{}")

    # Extract and display profile info (flat structure)
    local agent_name=$(echo "$profile" | grep -oE '"name":"[^"]*"' | head -1 | sed 's/"name":"//; s/"$//')
    local agent_status=$(echo "$profile" | grep -oE '"status":"[^"]*"' | head -1 | sed 's/"status":"//; s/"$//')
    local model=$(echo "$profile" | grep -oE '"model":"[^"]*"' | head -1 | sed 's/"model":"//; s/"$//')
    local task=$(echo "$profile" | grep -oE '"task_description":"[^"]*"' | head -1 | sed 's/"task_description":"//; s/"$//')

    echo "Name: ${agent_name:-Unknown}"
    echo "Status: ${agent_status:-unknown}"
    echo "Model: ${model:-unknown}"
    echo "Task: ${task:-None}"

    echo ""
    echo "=== Reservations ==="
    local reservations=$(mcp_call "list_reservations" "{}")

    if echo "$reservations" | grep -q '"reservations":\[\]'; then
        echo "No active reservations"
    else
        # Parse and display reservations
        echo "$reservations" | grep -oE '"id":[0-9]+|"patterns":\[[^]]*\]|"reason":"[^"]*"' |
        while read -r line; do
            echo "  $line"
        done
    fi
}

# Command: chat
cmd_chat() {
    local message="$*"
    if [ -z "$message" ]; then
        echo "Usage: agent-chat.sh chat <message>" >&2
        exit 1
    fi

    # Get room ID from profile (nested under "rooms" array or project room)
    local profile=$(mcp_call "get_agent_profile" "{}")
    local room_id=$(echo "$profile" | grep -oE '"room":\{"id":[0-9]+' | grep -oE '[0-9]+$')

    # Fallback: try rooms array
    if [ -z "$room_id" ]; then
        room_id=$(echo "$profile" | grep -oE '"rooms":\[.*?"id":[0-9]+' | grep -oE '"id":[0-9]+' | head -1 | grep -oE '[0-9]+')
    fi

    if [ -z "$room_id" ]; then
        echo "Error: Could not determine room ID" >&2
        exit 1
    fi

    local message_escaped=$(json_escape "$message")
    local result=$(mcp_call "send_message" '{"room_id": '"$room_id"', "body": "'"$message_escaped"'"}')

    if echo "$result" | grep -q '"error"'; then
        echo "Failed to send message: $result" >&2
        exit 1
    fi

    echo "Message sent to room $room_id"
}

# Command: reserve
cmd_reserve() {
    local pattern="$1"
    local reason="${2:-Working on files}"

    if [ -z "$pattern" ]; then
        echo "Usage: agent-chat.sh reserve <pattern> [reason]" >&2
        echo "Example: agent-chat.sh reserve 'app/models/**/*.rb' 'Refactoring'" >&2
        exit 1
    fi

    local pattern_escaped=$(json_escape "$pattern")
    local reason_escaped=$(json_escape "$reason")

    # Check for conflicts first
    local check=$(mcp_call "check_conflicts" '{"patterns": ["'"$pattern_escaped"'"]}')
    if echo "$check" | grep -q '"has_conflicts":true'; then
        echo "Warning: Conflicts with existing reservations" >&2
        echo "Use 'agent-chat.sh agents' to see who holds them" >&2
    fi

    # Reserve
    local result=$(mcp_call "reserve_files" '{"patterns": ["'"$pattern_escaped"'"], "reason": "'"$reason_escaped"'", "exclusive": true}')

    if echo "$result" | grep -q '"success":false'; then
        echo "Reservation failed due to conflicts" >&2
        exit 1
    fi

    if echo "$result" | grep -q '"error"'; then
        echo "Failed to reserve: $result" >&2
        exit 1
    fi

    local res_id=$(echo "$result" | grep -oE '"reservation_id":[0-9]+' | grep -oE '[0-9]+')
    local expires=$(echo "$result" | grep -oE '"expires_at":"[^"]*"' | sed 's/"expires_at":"//;s/"//')

    echo "Reserved: $pattern"
    echo "Reservation ID: $res_id"
    echo "Expires: $expires"
    echo "Reason: $reason"
}

# Command: release
cmd_release() {
    local reservation_arg="${1:-all}"

    if [ "$reservation_arg" = "all" ]; then
        # Get all our reservations
        local list=$(mcp_call "list_reservations" "{}")
        local ids=$(echo "$list" | grep -oE '"id":[0-9]+' | grep -oE '[0-9]+')

        if [ -z "$ids" ]; then
            echo "No active reservations to release"
            exit 0
        fi

        local released=0
        for id in $ids; do
            local result=$(mcp_call "release_reservation" '{"reservation_id": '"$id"'}')
            if echo "$result" | grep -q '"released":true'; then
                echo "Released reservation $id"
                released=$((released + 1))
            fi
        done

        echo "Released $released reservation(s)"
    else
        # Release specific ID
        local result=$(mcp_call "release_reservation" '{"reservation_id": '"$reservation_arg"'}')

        if echo "$result" | grep -q '"error"'; then
            echo "Failed to release: $result" >&2
            exit 1
        fi

        echo "Released reservation $reservation_arg"
    fi
}

# Command: agents
cmd_agents() {
    local result=$(mcp_call "list_agents" '{"include_self": true}')

    echo "=== Active Agents ==="

    if echo "$result" | grep -q '"agents":\[\]'; then
        echo "No other agents active"
        exit 0
    fi

    # Simple parsing: extract agent names and status
    # The response has agents array with objects containing name, status, etc.
    local names=$(echo "$result" | grep -oE '"name":"[^"]*"' | sed 's/"name":"//g; s/"//g')
    local statuses=$(echo "$result" | grep -oE '"status":"[^"]*"' | sed 's/"status":"//g; s/"//g')

    # Display each agent
    echo "$names" | while read -r name; do
        if [ -n "$name" ]; then
            echo "- $name"
        fi
    done
}

# Main dispatch
case "$COMMAND" in
    status)
        cmd_status
        ;;
    chat)
        cmd_chat "$@"
        ;;
    reserve)
        cmd_reserve "$@"
        ;;
    release)
        cmd_release "$@"
        ;;
    agents)
        cmd_agents
        ;;
    help|--help|-h|"")
        echo "MCP Agent Chat - Unified CLI"
        echo ""
        echo "Usage: agent-chat.sh <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  status              Show agent profile and reservations"
        echo "  chat <message>      Send message to project room"
        echo "  reserve <pattern>   Reserve files (optional: reason)"
        echo "  release [id|all]    Release reservations (default: all)"
        echo "  agents              List active agents in project"
        echo ""
        echo "Examples:"
        echo "  agent-chat.sh status"
        echo "  agent-chat.sh chat 'Starting work on auth module'"
        echo "  agent-chat.sh reserve 'app/models/**/*.rb' 'Refactoring'"
        echo "  agent-chat.sh release all"
        echo "  agent-chat.sh agents"
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        echo "Run 'agent-chat.sh help' for usage" >&2
        exit 1
        ;;
esac
