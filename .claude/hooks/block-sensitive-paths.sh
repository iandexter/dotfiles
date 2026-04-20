#!/usr/bin/env bash
# Block Write/Edit operations targeting sensitive paths.
# Called as a PreToolUse hook for Write and Edit tools.

file_path=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // ""')

# Resolve ~ to $HOME for comparison
resolved="$file_path"

sensitive_patterns=(
  "$HOME/.ssh/"
  "$HOME/.aws/"
  "$HOME/.gnupg/"
  "$HOME/.claude/settings.local.json"
  "$HOME/.claude/policy-limits.json"
  "$HOME/.claude/plugins/"
  "$HOME/.claude/skills/"
  "$HOME/.bashrc"
  "$HOME/.bash_profile"
  "$HOME/.zshrc"
  "$HOME/.profile"
  "$HOME/.env"
  "$HOME/.netrc"
  "$HOME/.npmrc"
)

for pattern in "${sensitive_patterns[@]}"; do
  if [[ "$resolved" == "$pattern" || "$resolved" == "$pattern"* ]]; then
    if [[ "$resolved" == "$HOME/.claude/skills/"* ]]; then
      echo "Blocked: Write/Edit to derived skill path '$file_path'. Edit the SSOT at ~/projects/ instead, then run claude-build to deploy." >&2
    else
      echo "Blocked: Write/Edit to sensitive path '$file_path' requires manual approval. Remove this hook entry temporarily if you need to modify this file." >&2
    fi
    exit 2
  fi
done

exit 0
