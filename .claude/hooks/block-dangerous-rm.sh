#!/usr/bin/env bash
cmd=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.command // ""')

# Block rm with recursive+force in any order, any flag style
if echo "$cmd" | grep -Eq '(^|[;&|])\s*(sudo\s+)?rm\s' && \
   echo "$cmd" | grep -Eq -- '-[a-zA-Z]*r|--recursive' && \
   echo "$cmd" | grep -Eq -- '-[a-zA-Z]*f|--force'; then
  echo "Blocked: recursive forced rm commands are not allowed." >&2
  exit 2
fi

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

exit 0
