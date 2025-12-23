#!/bin/bash
# MCP Agent Chat Installer
# Usage: ./install.sh <MCP_SERVER_URL>
# Example: ./install.sh http://localhost:3000/mcp

set -e

MCP_SERVER_URL="${1:-}"
PROJECT_DIR="${2:-$(pwd)}"

if [ -z "$MCP_SERVER_URL" ]; then
    echo "Usage: $0 <MCP_SERVER_URL> [PROJECT_DIR]"
    echo "Example: $0 http://localhost:3000/mcp"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing MCP Agent Chat..."
echo "  MCP Server: $MCP_SERVER_URL"
echo "  Project: $PROJECT_DIR"
echo ""

# Create directories
echo "Creating directories..."
mkdir -p "$PROJECT_DIR/.claude/commands"
mkdir -p "$PROJECT_DIR/scripts/mcp"

# Copy skill definitions
echo "Installing skills..."
cp "$SCRIPT_DIR/.claude/commands/"*.md "$PROJECT_DIR/.claude/commands/"

# Copy hook scripts
echo "Installing hook scripts..."
cp "$SCRIPT_DIR/scripts/mcp/"*.sh "$PROJECT_DIR/scripts/mcp/"
chmod +x "$PROJECT_DIR/scripts/mcp/"*.sh

# Create/update settings.json
echo "Configuring settings..."
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.local.json"

if [ -f "$SETTINGS_FILE" ]; then
    echo "  Note: settings.local.json exists, creating settings.mcp.json instead"
    SETTINGS_FILE="$PROJECT_DIR/.claude/settings.mcp.json"
fi

# Generate settings
cat > "$SETTINGS_FILE" << EOF
{
  "permissions": {
    "allow": [
      "Bash(scripts/mcp/*:*)"
    ]
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "scripts/mcp/register_agent.sh",
            "timeout": 10000
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "scripts/mcp/check_reservation.sh \"\$TOOL_INPUT_FILE_PATH\"",
            "timeout": 5000
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "scripts/mcp/check_reservation.sh \"\$TOOL_INPUT_FILE_PATH\"",
            "timeout": 5000
          }
        ]
      },
      {
        "matcher": "MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "scripts/mcp/check_reservation.sh \"\$TOOL_INPUT_FILE_PATH\"",
            "timeout": 5000
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "scripts/mcp/cleanup_session.sh",
            "timeout": 10000
          }
        ]
      }
    ]
  },
  "env": {
    "MCP_SERVER_URL": "$MCP_SERVER_URL",
    "PROJECT_PATH": "$PROJECT_DIR"
  }
}
EOF

echo ""
echo "Installation complete!"
echo ""
echo "Files installed:"
echo "  .claude/commands/*.md - Agent skills"
echo "  .claude/settings*.json - Configuration"
echo "  scripts/mcp/*.sh - Hook scripts"
echo ""

# Test connection
echo "Testing MCP server connection..."
HEALTH_URL="${MCP_SERVER_URL%/mcp}/mcp/health"
if curl -s "$HEALTH_URL" > /dev/null 2>&1; then
    echo "  MCP server is reachable"
else
    echo "  Warning: MCP server not reachable at $HEALTH_URL"
    echo "  Make sure the server is running before using agent features"
fi

echo ""
echo "Next steps:"
echo "  1. Open Claude Code in this project"
echo "  2. Agent will auto-register on session start"
echo "  3. Use /status to verify setup"
echo "  4. Use /chat to communicate with other agents"
