#!/usr/bin/env bash
# Audit log: records all Bash tool invocations to a daily log file.
# Called as a PostToolUse hook for Bash.

LOG_DIR="$HOME/.claude/audit"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/$(date -u '+%Y-%m-%d').log"
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

cmd=$(jq -r '.tool_input.command // .command // "(empty)"' 2>/dev/null)
# Truncate long commands to 500 chars for log readability
cmd_truncated="${cmd:0:500}"

echo "$TIMESTAMP | bash | $cmd_truncated" >> "$LOG_FILE"

exit 0
