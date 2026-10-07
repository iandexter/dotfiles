#!/usr/bin/env bash
# Block Bash commands that WRITE to sensitive paths.
# Called as a PreToolUse hook for the Bash tool, chained after the existing
# Bash guards (block-dangerous-rm.sh, validate-universe-git.sh).
#
# Why: block-sensitive-paths.sh protects ~/.ssh, ~/.aws, ~/.claude/settings.local.json,
# etc. — but only for the Write and Edit tools. A shell command (cp, mv, >, tee,
# sed -i, dd) can write those same paths untouched. This closes that bypass.
#
# Heuristic, not a parser. Each normalized sub-command is judged on its own: it
# is a write only if a redirect (> or >>) points AT a sensitive path, or it
# starts with a write verb (tee/cp/mv/install/ln/rsync/truncate/chmod/chown,
# sed -i, dd of=) and names a sensitive path. Read-only commands (cat, grep, ls,
# diff) that merely reference a sensitive path are allowed, including when they
# carry unrelated redirects such as `2>/dev/null` or `2>&1`. Errs toward
# blocking; if a legitimate command trips it, split the write out or unset the
# hook briefly.

cmd=$(jq -r '.tool_input.command // .command // ""' 2>/dev/null)
# Unwrap wrapped invocations (bash -c, env, docker/podman run, ...) so they cannot bypass the matcher; see lib-bash-normalize.sh.
# normalize_bash_cmd splits on ; & | and newlines, so $segments holds one sub-command per line.
_nd="$(dirname "${BASH_SOURCE[0]:-$0}")"; segments="$cmd"; [[ -f "$_nd/lib-bash-normalize.sh" ]] && { . "$_nd/lib-bash-normalize.sh"; segments="$(normalize_bash_cmd "$cmd")"; }

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

# Write verbs, as the FIRST token of a sub-command (optionally behind sudo), or
# after find -exec/-execdir. Anchoring at the start keeps `grep install ~/.npmrc`
# a read.
verb='(tee|cp|mv|install|ln|rsync|truncate|chmod|chown)'
sudo_prefix='(sudo[[:space:]]+(-[^[:space:]]+[[:space:]]+)*)?'
verb_re="^${sudo_prefix}${verb}([[:space:]]|\$)|-exec(dir)?[[:space:]]+${verb}([[:space:]]|\$)"
sed_i_re='^(sudo[[:space:]]+)?sed[[:space:]]+(.*[[:space:]])?(-[A-Za-z]*i[^[:space:]]*|--in-place[^[:space:]]*)([[:space:]]|$)'
dd_re='^(sudo[[:space:]]+)?dd[[:space:]]+(.*[[:space:]])?of='

while IFS= read -r seg; do
  [[ -z "$seg" ]] && continue
  for pattern in "${sensitive_patterns[@]}"; do
    [[ "$seg" == *"$pattern"* ]] || continue
    write=0
    # Redirect whose target is the sensitive path (quoted "$pattern" is literal in =~).
    [[ "$seg" =~ \>\>?[[:space:]]*"$pattern" ]] && write=1
    # Write verb as the command (or under find -exec) that names the path.
    [[ "$write" == 0 ]] && echo "$seg" | grep -Eq -- "$verb_re" && write=1
    [[ "$write" == 0 ]] && echo "$seg" | grep -Eq -- "$sed_i_re" && write=1
    [[ "$write" == 0 ]] && echo "$seg" | grep -Eq -- "$dd_re" && write=1
    if [[ "$write" == 1 ]]; then
      echo "Blocked: Bash command appears to write to sensitive path '$pattern'. The Write/Edit guard does not cover shell writes; this hook closes that gap. If this is a legitimate write, unset this hook entry temporarily, or perform it manually." >&2
      exit 2
    fi
  done
done <<< "$segments"

exit 0
