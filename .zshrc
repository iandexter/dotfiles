# On Arca (Linux dbexec box whose default login shell is zsh), drop into bash
# for interactive sessions — the entire dotfiles toolchain is bash. The -t 0
# guard keeps non-interactive ssh/rsync (arca-sync, scp) in zsh so they don't
# break; exec replaces the process, so nothing below this runs on Arca. No-op
# on the laptop (uname=Darwin, no ~/.arca), which keeps its zsh setup.
if [[ "$(uname)" == "Linux" && -d "$HOME/.arca" && -t 0 ]]; then
  export LC_ALL=en_US.UTF-8
  export SHELL=/bin/bash
  exec /bin/bash
fi

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
