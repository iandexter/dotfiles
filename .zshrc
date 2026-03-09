# Cursor shell integration should only run in interactive TTY sessions.
if [[ -o interactive && -t 0 && -z "${VSCODE_RESOLVING_ENVIRONMENT:-}" && -x "$HOME/.local/bin/agent" ]]; then
  eval "$("$HOME/.local/bin/agent" shell-integration zsh)"
fi

export PATH="$HOME/miniconda/bin:$PATH"

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

export UV_EXTRA_INDEX_URL="/Users/ian.marquez/projects/databricks/ds-projects/packages/py_wheels/simple/"
export PIP_EXTRA_INDEX_URL="/Users/ian.marquez/projects/databricks/ds-projects/packages/py_wheels/simple/"
