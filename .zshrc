# Cursor shell integration should only run in interactive TTY sessions.
if [[ -o interactive && -t 0 && -z "${VSCODE_RESOLVING_ENVIRONMENT:-}" && -x "$HOME/.local/bin/agent" ]]; then
  eval "$("$HOME/.local/bin/agent" shell-integration zsh)"
fi

export PATH="$HOME/miniconda/bin:$PATH"

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Machine-specific overrides
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
