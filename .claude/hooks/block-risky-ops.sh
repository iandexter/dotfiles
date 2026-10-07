#!/usr/bin/env bash
# PreToolUse Bash hook: gate supply-chain / deploy / publish operations behind
# an explicit per-op opt-in. These are deliberate acts, not casual side effects.
#
# Blocks (unless the matching ALLOW_* env var is set to 1 in the session env;
# like the other ALLOW_* hooks, the var is read at session start):
#   - package installs that run lifecycle scripts (npm/yarn/pnpm install|add|ci
#     without --ignore-scripts)                      -> ALLOW_NPM_SCRIPTS=1
#   - remote package execution (npx, pnpm dlx, yarn dlx)  -> ALLOW_NPX=1
#   - package publish (npm/yarn/pnpm publish)             -> ALLOW_PUBLISH=1
#   - deploys (wrangler/netlify/vercel/firebase/gh-pages,  -> ALLOW_DEPLOY=1
#     gcloud app deploy, aws deploy, aws s3 sync)
#
# NOT covered here: git push. Normal push is a routine op; force-push is covered
# by the deny rules, and protected-remote push by validate-universe-git.sh.
#
# SSOT: ~/etc/dotfiles/.claude/hooks/block-risky-ops.sh ; deployed by claude-build.

set -uo pipefail
cmd=$(jq -r '.tool_input.command // .command // ""' 2>/dev/null)
[[ -z "$cmd" ]] && exit 0
# Unwrap wrapped invocations (bash -c, env, command, docker/podman run, ...) so they can't bypass the matchers; see lib-bash-normalize.sh.
_nd="$(dirname "${BASH_SOURCE[0]:-$0}")"; [[ -f "$_nd/lib-bash-normalize.sh" ]] && { . "$_nd/lib-bash-normalize.sh"; cmd="$cmd"$'\n'"$(normalize_bash_cmd "$cmd")"; }

block() { echo "Blocked: $1 Re-run with $2=1 set in the environment to allow." >&2; exit 2; }

# 1. Package install that runs lifecycle scripts (arbitrary-code supply-chain surface).
if echo "$cmd" | grep -Eq '(^|[;&|])[[:space:]]*(npm[[:space:]]+(install|i|ci|add)|yarn[[:space:]]+(install|add)|pnpm[[:space:]]+(install|i|add))([[:space:]]|$)'; then
  if ! echo "$cmd" | grep -Eq -- '--ignore-scripts'; then
    [[ "${ALLOW_NPM_SCRIPTS:-0}" == "1" ]] || block "package install runs lifecycle scripts (supply-chain risk). Add --ignore-scripts, or allow." "ALLOW_NPM_SCRIPTS"
  fi
fi

# 2. Remote package execution.
if echo "$cmd" | grep -Eq '(^|[;&|])[[:space:]]*(npx|pnpm[[:space:]]+dlx|yarn[[:space:]]+dlx)([[:space:]]|$)'; then
  [[ "${ALLOW_NPX:-0}" == "1" ]] || block "npx/dlx executes remote package code without an install step." "ALLOW_NPX"
fi

# 3. Publish to a registry.
if echo "$cmd" | grep -Eq '(^|[;&|])[[:space:]]*(npm|yarn|pnpm)[[:space:]]+publish([[:space:]]|$)'; then
  [[ "${ALLOW_PUBLISH:-0}" == "1" ]] || block "package publish pushes to a public registry." "ALLOW_PUBLISH"
fi

# 4. Deploys / publish-to-host.
if echo "$cmd" | grep -Eq '(wrangler[[:space:]]+(pages[[:space:]]+)?(deploy|publish)|netlify[[:space:]]+deploy|vercel[[:space:]]+(deploy|--prod)|firebase[[:space:]]+deploy|(^|[[:space:]])gh-pages([[:space:]]|$)|gcloud[[:space:]]+app[[:space:]]+deploy|aws[[:space:]]+deploy|aws[[:space:]]+s3[[:space:]]+sync)'; then
  [[ "${ALLOW_DEPLOY:-0}" == "1" ]] || block "deploy / publish-to-host command." "ALLOW_DEPLOY"
fi

exit 0
