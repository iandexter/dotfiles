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
#   - git push --force / -f in any flag position             -> ALLOW_FORCE_PUSH=1
#     (--force-with-lease / --force-if-includes allowed)
#   - git commit --no-verify / -n, git push --no-verify       -> ALLOW_NO_VERIFY=1
#     (these skip git's own commit-msg / pre-commit / pre-push hooks)
#
# NOT covered here: plain git push. Normal push is a routine op. Protected-remote
# push is handled by validate-universe-git.sh.
#
# SSOT: ~/etc/dotfiles/.claude/hooks/block-risky-ops.sh ; deployed by claude-build.

set -uo pipefail
cmd=$(jq -r '.tool_input.command // .command // ""' 2>/dev/null)
[[ -z "$cmd" ]] && exit 0
# Unwrap wrapped invocations (bash -c, env, command, docker/podman run, ...) so they can't bypass the matchers; see lib-bash-normalize.sh.
_nd="$(dirname "${BASH_SOURCE[0]:-$0}")"; norm=""; [[ -f "$_nd/lib-bash-normalize.sh" ]] && { . "$_nd/lib-bash-normalize.sh"; norm="$(normalize_bash_cmd "$cmd")"; cmd="$cmd"$'\n'"$norm"; }

block() { echo "Blocked: $1 Re-run with $2=1 set in the environment to allow." >&2; exit 2; }

# True if $1 is a `git [global-opts] <subcmd>` invocation. The subcommand is
# anchored (git, then any global options, then the subcommand), so a commit
# message / PR body that merely mentions the subcommand is NOT matched.
git_subcmd() {
  echo "$1" | grep -Eq "^([^[:space:]]*/)?git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--[A-Za-z][A-Za-z-]*(=[^[:space:]]*)?|-[A-Za-z]+))*[[:space:]]+$2([[:space:]]|\$)"
}

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

# 5. Force push (rewrites remote history). The deny rule Bash(git push --force *)
#    only catches the flag right after `push`; a flag at the end (git push origin
#    main --force) or a wrapped form (bash -c "git push -f") slips past it. This
#    closes both. --force-with-lease / --force-if-includes are the safe forms and
#    are allowed. Checked per normalized sub-command so a nearby `-f` on an
#    adjacent command (e.g. `git push && rm -f x`) can't false-trip.
#    `push` must be the git SUBCOMMAND (git [global-opts] push ...), so a commit
#    message or PR body that merely mentions "git push --force" is not blocked;
#    anchoring there removes the self-trip that forced `git commit -F <file>`.
while IFS= read -r _seg; do
  [[ "$_seg" == *git* && "$_seg" == *push* ]] || continue
  echo "$_seg" | grep -Eq -- '--force-with-lease|--force-if-includes' && continue
  if git_subcmd "$_seg" push && \
     echo "$_seg" | grep -Eq -- '(--force($|[[:space:]=])|(^|[[:space:]])-[A-Za-z]*f[A-Za-z]*([[:space:]]|$))'; then
    [[ "${ALLOW_FORCE_PUSH:-0}" == "1" ]] || block "git push --force rewrites remote history. Use --force-with-lease, or allow." "ALLOW_FORCE_PUSH"
  fi
done <<< "$norm"

# 6. --no-verify / -n skips git's own hooks (commit-msg validator, pre-commit,
#    pre-push). Subcommand-anchored like section 5. `git push -n` is --dry-run,
#    not a skip, so -n is scoped to commit only. Caveat: a commit MESSAGE that
#    literally contains a bare `-n` token or `--no-verify` over-blocks (same
#    quoted-data bias as the other guards) — use git commit -F <file>, or allow.
while IFS= read -r _seg; do
  case "$_seg" in *git*) ;; *) continue ;; esac
  if git_subcmd "$_seg" commit && \
     echo "$_seg" | grep -Eq -- '(--no-verify|(^|[[:space:]])-[A-Za-z]*n[A-Za-z]*([[:space:]]|$))'; then
    [[ "${ALLOW_NO_VERIFY:-0}" == "1" ]] || block "git commit --no-verify/-n skips git's own hooks (commit-msg, pre-commit)." "ALLOW_NO_VERIFY"
  fi
  if git_subcmd "$_seg" push && echo "$_seg" | grep -Eq -- '--no-verify'; then
    [[ "${ALLOW_NO_VERIFY:-0}" == "1" ]] || block "git push --no-verify skips the pre-push hook." "ALLOW_NO_VERIFY"
  fi
done <<< "$norm"

exit 0
