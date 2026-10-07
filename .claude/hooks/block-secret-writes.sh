#!/usr/bin/env bash
# PreToolUse Write/Edit hook: block writing live secret MATERIAL into files.
# Scans the content being written (Write .content, Edit .new_string).
# Override: ALLOW_SECRET_WRITE=1 (read at session start).
#
# Deliberately NARROW. This user's IAM / token / SCIM / OIDC investigation docs
# routinely quote AKIA ids, JWTs, and token *prefixes* as evidence, so matching
# those would false-positive constantly. We match only material that is never
# legitimately written to a file: a private-key block, or a full-length live
# credential value in an assignment. Widen only with care.
#
# SSOT: ~/etc/dotfiles/.claude/hooks/block-secret-writes.sh ; deployed by claude-build.

set -uo pipefail
content=$(jq -r '.tool_input.content // .tool_input.new_string // ""' 2>/dev/null)
[[ -z "$content" ]] && exit 0
[[ "${ALLOW_SECRET_WRITE:-0}" == "1" ]] && exit 0

# Never-legitimate-in-a-file signatures (very low false-positive):
patterns=(
  'BEGIN ((RSA|EC|OPENSSH|DSA|PGP) )?PRIVATE KEY'              # private key block
  'aws_secret_access_key[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9/+]{40}'  # real 40-char AWS secret value
)
for p in "${patterns[@]}"; do
  if echo "$content" | grep -Eq "$p"; then
    echo "Blocked: content appears to contain live secret material (matched /$p/). If this is a redacted sample or test fixture, re-run with ALLOW_SECRET_WRITE=1 set in the environment." >&2
    exit 2
  fi
done
exit 0
