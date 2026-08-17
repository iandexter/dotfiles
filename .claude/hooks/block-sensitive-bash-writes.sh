#!/usr/bin/env bash
# Block Bash commands that WRITE to sensitive paths.
# Called as a PreToolUse hook for the Bash tool, chained after the existing
# Bash guards (block-dangerous-rm.sh, validate-universe-git.sh).
#
# Why: block-sensitive-paths.sh protects ~/.ssh, ~/.aws, ~/.claude/settings.local.json,
# etc. — but only for the Write and Edit tools. A shell command (cp, mv, >, tee,
# sed -i, dd) can write those same paths untouched. This closes that bypass.
#
# Heuristic, not a parser: it flags a command that mentions a sensitive path
# alongside a write verb/operator. Read-only commands (cat, grep, ls, diff) that
# merely reference a sensitive path are allowed. Errs toward blocking; if a
# legitimate command trips it, split the write out or unset the hook briefly.

cmd=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.command // ""')

# Keep this list in sync with block-sensitive-paths.sh (sensitive_patterns).
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
  "$HOME/.claude.json"
  "$HOME/.config/mcp/config.json"
  "$HOME/Downloads/ai/state/broker"
)

# Also match the ~-prefixed form, since commands often use the literal tilde.
extra=()
for p in "${sensitive_patterns[@]}"; do
  extra+=("${p/#$HOME/\~}")
done
sensitive_patterns+=("${extra[@]}")

# Does the command reference any sensitive path?
hit=""
for pattern in "${sensitive_patterns[@]}"; do
  if [[ "$cmd" == *"$pattern"* ]]; then
    hit="$pattern"
    break
  fi
done
[[ -z "$hit" ]] && exit 0

# It references a sensitive path. Block only if it also looks like a write.
# Write signals: output redirect (> >>), tee, cp/mv/install/ln into, sed -i,
# dd of=, truncate, chmod/chown on the path, or a heredoc redirect.
# Verbs are anchored with (^|space) so a command STARTING with cp/mv/etc. (the
# common case) is caught, not only mid-pipeline occurrences.
if echo "$cmd" | grep -qE '(>>?|(^|[[:space:]])(tee|cp|mv|install|ln|rsync|truncate|chmod|chown)[[:space:]]|sed[[:space:]]+-i|dd[[:space:]]+.*of=)'; then
  echo "Blocked: Bash command appears to write to sensitive path '$hit'. The Write/Edit guard does not cover shell writes; this hook closes that gap. If this is a legitimate write, unset this hook entry temporarily, or perform it manually." >&2
  exit 2
fi

exit 0
