#!/usr/bin/env bash
# Shared helper for the Bash PreToolUse guards.
#
# normalize_bash_cmd "<raw command>" prints zero or more normalized sub-commands,
# one per line, with leading wrappers stripped and bash -c / sh -c /
# docker|podman run payloads unwrapped. Guards append this to the raw command and
# run their existing boundary-anchored greps against the combined, newline-joined
# blob: grep's ^ then re-anchors each unwrapped sub-command at a line start, so a
# wrapped invocation (bash -c "npm install", env npm i, podman run img npm i,
# command npm i) no longer slips past a matcher that keys on command boundaries.
#
# Heuristic, NOT a shell parser. Biased to over-expose: de-quoting can surface a
# trigger that lived inside a quoted string (e.g. `echo "...; rm -rf x"`), which
# makes a guard over-block. For a security guard, over-block is the correct bias.
# The container flag/image skip is approximate (valued flags like `-v a:b` can
# shift the image guess); it covers the common `run [--flags] <image> <cmd>` form.
#
# SSOT: ~/etc/dotfiles/.claude/hooks/lib-bash-normalize.sh ; deployed by claude-build.
# Not wired as a hook in settings.json — it is sourced by the guard scripts.

normalize_bash_cmd() {
  printf '%s' "${1:-}" | awk '
    BEGIN { RS = "\0" }
    {
      c = $0
      gsub(/"/, " ", c)            # drop double quotes
      gsub("\047", " ", c)         # drop single quotes (\047 = apostrophe)
      gsub(/&&|\|\|/, "\n", c)     # split on && and ||
      gsub(/[;&|]/, "\n", c)       # and on ; & |
      n = split(c, seg, /\n/)
      for (k = 1; k <= n; k++) {
        line = seg[k]
        sub(/^[[:space:]]+/, "", line)
        changed = 1
        while (changed) {
          changed = 0
          # leading VAR=val environment assignment
          if (match(line, /^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+/)) { line = substr(line, RLENGTH + 1); changed = 1; continue }
          # one-token wrappers that exec their argument
          if (match(line, /^(env|command|builtin|time|nice|nohup|xargs|noglob|setsid|ionice|\/usr\/bin\/env|\/bin\/env)[[:space:]]+/)) { line = substr(line, RLENGTH + 1); changed = 1; continue }
          # two-token wrappers: <wrapper> <arg> <cmd...>
          if (match(line, /^(timeout|stdbuf)[[:space:]]+[^[:space:]]+[[:space:]]+/)) { line = substr(line, RLENGTH + 1); changed = 1; continue }
          # bash/sh -c | -lc | -cl ... <payload>
          if (match(line, /^(ba)?sh[[:space:]]+-[a-z]*c[a-z]*[[:space:]]+/)) { line = substr(line, RLENGTH + 1); changed = 1; continue }
          # docker|podman run [flags] <image> <cmd...>
          if (match(line, /^(docker|podman)[[:space:]]+run[[:space:]]+/)) {
            rest = substr(line, RLENGTH + 1)
            m = split(rest, t, /[[:space:]]+/)
            i = 1
            while (i <= m && t[i] ~ /^-/) i++   # skip leading option flags (approx)
            i++                                  # skip the image token
            line = ""
            for (; i <= m; i++) line = line t[i] " "
            sub(/[[:space:]]+$/, "", line)
            changed = 1
            continue
          }
        }
        sub(/^[[:space:]]+/, "", line)
        if (line != "") print line
      }
    }
  '
}
