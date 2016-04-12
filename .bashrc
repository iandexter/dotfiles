# Aliases
test -s ~/.alias && . ~/.alias || true
# Prompt
export PS1='\[\033[1;32m\]$USER@\[\033[1;31m\]$HOSTNAME\[\033[1;32m\]:\[\033[0;32m\]$PWD [\!:$?]
\$\[\033[m\] '
# History
export HISTCONTROL=ignoreboth
export HISTSIZE=99999
export HISTTIMEFORMAT="%D %T "
shopt -s histappend
export PROMPT_COMMAND='history -a'
# Locale
export LC_ALL=C
# Timeout
unset TMOUT
# GPG
if [[ -e "${HOME}/.gpg-agent-info" ]] ; then
    . "${HOME}/.gpg-agent-info"
    export GPG_AGENT_INFO
    export SSH_AUTH_SOCK
    export SSH_AGENT_PID
fi
# Mac optimizations
if [[ $(uname) = 'Darwin' ]] ; then
    if ps -ef | grep -q [g]pg-agent ; then
        echo "gpg-agent is already running"
    else
        eval $(gpg-agent --daemon --allow-preset-passphrase --default-cache-ttl 6000 --use-standard-socket)
    fi
    if [[ -f $(brew --prefix)/etc/bash_completion ]] ; then
        . $(brew --prefix)/etc/bash_completion
    fi
fi
# Password manager
export PASSWORD_STORE_DIR=$HOME/.crypto/.passwords
export PASSWORD_STORE_GIT=$HOME/.crypto/.passwords
