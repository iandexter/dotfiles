#!/usr/bin/env bash
cmd=$(jq -r '.tool_input.command // .command // ""' 2>/dev/null)
# Unwrap wrapped invocations (bash -c, env, docker/podman run, ...) so they can't bypass the matchers; see lib-bash-normalize.sh.
# segs holds one sub-command per line; without the lib, fall back to splitting on ; & |.
_nd="$(dirname "${BASH_SOURCE[0]:-$0}")"
if [[ -f "$_nd/lib-bash-normalize.sh" ]]; then
  . "$_nd/lib-bash-normalize.sh"; segs=$(normalize_bash_cmd "$cmd")
else
  segs=$(printf '%s' "$cmd" | tr ';&|' '\n\n\n')
fi
cmd="$cmd"$'\n'"$segs"

# Block rm with recursive+force in any order, any flag style. Flags are read
# per rm sub-command, so hyphenated words elsewhere in the line (hostnames like
# omnigent-arclet, --format on a later git call) no longer count as -r or -f.
while IFS= read -r seg; do
  [[ "$seg" =~ ^[[:space:]]*(sudo[[:space:]]+)?rm[[:space:]] ]] || continue
  read -ra toks <<< "$seg"   # read -a does not glob, unlike for tok in $seg
  rec=0 force=0
  for tok in "${toks[@]:1}"; do
    case "$tok" in
      --) break ;;
      --recursive) rec=1 ;;
      --force) force=1 ;;
      --*) ;;
      -*) [[ "$tok" == *[rR]* ]] && rec=1; [[ "$tok" == *f* ]] && force=1 ;;
    esac
  done
  if (( rec && force )); then
    echo "Blocked: recursive forced rm commands are not allowed." >&2
    exit 2
  fi
done <<< "$segs"

# Block rm --no-preserve-root
if echo "$cmd" | grep -Eq '(^|[;&|])\s*(sudo\s+)?rm\s.*--no-preserve-root'; then
  echo "Blocked: rm --no-preserve-root is not allowed." >&2
  exit 2
fi

# Block sudo entirely
if echo "$cmd" | grep -Eq '(^|[;&|])\s*sudo\s'; then
  echo "Blocked: sudo commands are not allowed." >&2
  exit 2
fi

# Block piped code execution: curl|bash, wget|bash, curl|sh, eval "$(curl ...)"
if echo "$cmd" | grep -Eq 'curl\s.*\|\s*(ba)?sh|wget\s.*\|\s*(ba)?sh'; then
  echo "Blocked: piping remote content to a shell is not allowed." >&2
  exit 2
fi
if echo "$cmd" | grep -Eq 'eval\s+"\$\(curl|eval\s+"\$\(wget'; then
  echo "Blocked: eval of remote content is not allowed." >&2
  exit 2
fi

# Block bare pip/pip3 install outside a venv
# Allowed if VIRTUAL_ENV is set or command explicitly uses a venv python path
if echo "$cmd" | grep -Eq '(^|[;&|])\s*pip3?\s+install\s'; then
  if [[ -z "${VIRTUAL_ENV:-}" ]] && ! echo "$cmd" | grep -Eq 'pyenv\s+shell|\.venv|/envs/'; then
    echo "Blocked: pip install outside a virtual environment. Use 'pyenv shell scratch' or activate a venv first." >&2
    exit 2
  fi
fi

# Block rsync --delete (destination-wiping). Triggered a hook wipe on
# 20 Apr 2026 when a sparse source rsync'd over a populated destination.
# Allowed if --dry-run is also present, or if caller sets ALLOW_RSYNC_DELETE=1
# as an explicit opt-in.
if echo "$cmd" | grep -Eq '(^|[;&|])\s*rsync\s' && \
   echo "$cmd" | grep -Eq -- '(^|\s)(--delete|--del($|\s)|--delete-before|--delete-during|--delete-after|--delete-excluded)'; then
  if echo "$cmd" | grep -Eq -- '(^|\s)(--dry-run|-n($|\s))'; then
    : # dry run is safe
  elif [[ "${ALLOW_RSYNC_DELETE:-0}" == "1" ]]; then
    : # explicit opt-in
  else
    echo "Blocked: rsync with --delete is destructive. Add --dry-run to preview, or set ALLOW_RSYNC_DELETE=1 to confirm intent." >&2
    exit 2
  fi
fi

exit 0
