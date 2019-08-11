export PATH=$PATH:$HOME/bin
# Aliases
test -e ~/.aliases && . ~/.aliases || true
test -e ~/.aliases.d && . ~/.aliases.d/* || true
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
LC_CTYPE=UTF-8
export PYTHONIOENCODING=utf-8
# Timeout
unset TMOUT
# GPG
if [[ -e "${HOME}/.gpg-agent-info" ]] ; then
    . "${HOME}/.gpg-agent-info"
    export GPG_AGENT_INFO
    export SSH_AUTH_SOCK
    export SSH_AGENT_PID
fi
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$HOME/.gnupg/S.gpg-agent.ssh
if ps -ef | grep -q [g]pg-agent ; then
    echo "gpg-agent is already running"
else
    if [[ ! -e $HOME/.gnupg/gpg-agent.conf ]] ; then
        eval $(gpg-agent --daemon --quiet --default-cache-ttl 6000 \
            --ignore-cache-for-signing --no-allow-external-cache \
            --enable-ssh-support)
    else
        eval $(gpg-agent --options $HOME/.gnupg/gpg-agent.conf)
    fi
fi
export GPG_KEY=0x126A3EDFFB6E402E
# Mac optimizations
if [[ $(uname) = 'Darwin' ]] ; then
    export LC_ALL=en_GB.UTF-8
    export LANG=en_GB.UTF-8
    if [[ -f $(brew --prefix)/etc/bash_completion ]] ; then
        . $(brew --prefix)/etc/bash_completion
        ### if which kubectl > /dev/null ; then . <(kubectl completion bash) ; fi
    fi
    ### if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
    export PATH=$PATH:/Library/TeX/texbin:$HOME/bin/platform-tools:$HOME/.gem/ruby/2.0.0/bin
fi
# https://github.com/riobard/bash-powerline
if [[ -f $HOME/.bash_powerline ]] ; then
    source $HOME/.bash_powerline
fi
# Password manager
if [[ -x $(which pass 2>/dev/null) && -d $HOME/.passwords ]] ; then
    export PASSWORD_STORE_DIR=$HOME/.passwords
    export PASSWORD_STORE_GIT=$HOME/.passwords
fi
