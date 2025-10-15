export PATH=$PATH:$HOME/bin
[[ -d $HOME/.local/bin ]] && export PATH=$PATH:$HOME/.local/bin
# Aliases
test -e $HOME/.aliases && . $HOME/.aliases || true
if [[ -e $HOME/.aliases.d ]] ; then
    for a in $HOME/.aliases.d/* ; do
        source $a
    done
fi
if [[ -e $HOME/.local/.aliases.d ]] ; then
    for a in $HOME/.local/.aliases.d/* ; do
        source $a
    done
fi
# Prompt
export PS1='\[\033[1;32m\]$USER@\[\033[1;31m\]$HOSTNAME\[\033[1;32m\]:\[\033[0;32m\]$PWD [\!:$?]
\$\[\033[m\] '
# History
export HISTCONTROL=ignoreboth
export HISTSIZE=10000000
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
    if [[ -f $(brew --prefix)/etc/profile.d/bash_completion.sh ]] ; then
        source $(brew --prefix)/etc/profile.d/bash_completion.sh
    fi
    if command -v pyenv &>/dev/null ; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
        if command -v pyenv virtualenv &>/dev/null ; then
            eval "$(pyenv virtualenv-init -)"
        fi
        export PYENV_VIRTUALENV_DISABLE_PROMPT=1
    fi
    [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && .  "/usr/local/etc/profile.d/bash_completion.sh"
    [[ -d /Library/TeX/texbin ]] && export PATH=$PATH:/Library/TeX/texbin
    [[ -d $HOME/bin/platform-tools ]] && export PATH=$PATH:$HOME/bin/platform-tools
    if [[ -d /usr/local/opt/curl/bin ]] ; then
        export PATH=/usr/local/opt/curl/bin:$PATH
        export LDFLAGS="-L/usr/local/opt/curl/lib"
        export CPPFLAGS="-I/usr/local/opt/curl/include"
        export PKG_CONFIG_PATH="/usr/local/opt/curl/lib/pkgconfig"
    elif [[ -d $(brew --prefix)/opt/curl/bin ]] ; then
        export PATH="$(brew --prefix)/opt/curl/bin:$PATH"
        export LDFLAGS="-L$(brew --prefix)/opt/curl/lib"
        export CPPFLAGS="-I$(brew --prefix)/opt/curl/include"
        export PKG_CONFIG_PATH="$(brew --prefix)/opt/curl/lib/pkgconfig"
    fi
    if [[ -d /usr/local/opt/ruby ]] ; then
        export LDFLAGS="-L/usr/local/opt/ruby/lib"
        export CPPFLAGS="-I/usr/local/opt/ruby/include"
        export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"
        export PATH=/usr/local/opt/ruby/bin:$PATH:$HOME/.gem/ruby/2.6.0/bin
    fi
    if [[ -f /Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home/bin/java ]] ; then
        export JAVA_HOME=/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home
        export PATH=${JAVA_HOME}/bin:$PATH
    fi
    if [[ -d ~/bin/google-cloud-sdk ]] ; then
        export PATH=~/bin/google-cloud-sdk/bin:$PATH
    fi
    if [[ -d /usr/local/opt/gnu-sed ]] ; then
        export PATH=/usr/local/opt/gnu-sed/libexec/gnubin:$PATH
    fi
    if [[ -d $(brew --prefix)/bin/go ]] ; then
        export PATH=$(brew --prefix)/bin/go/bin:$PATH
    elif [[ -d $(go env GOPATH) ]] ; then
        export PATH=$(go env GOPATH)/bin:$PATH
    elif [[ -d ~/go ]] ; then
        export PATH=~/go/bin:$PATH
    fi
    if command -v pygmentize >/dev/null ; then
        unalias less 2>/dev/null
        alias ccat='pygmentize -g'
        alias cless='pygmentize -g | less -R'
        alias jless='pygmentize -l json | less -R'
        alias jqless='jq -r . | jless'
    fi
fi
# Vagrant
if which vagrant &>/dev/null ; then
    if [[ -d $HOME/projects/vagrant ]] ; then
        export VAGRANT_CWD=$HOME/projects/vagrant
    fi
fi
# https://github.com/chris-marsh/pureline
if [[ -f $HOME/.bash_powerline ]] ; then
    source $HOME/.bash_powerline
fi
# Password manager
if [[ -x $(which pass 2>/dev/null) && -d $HOME/.passwords ]] ; then
    export PASSWORD_STORE_DIR=$HOME/.passwords
    export PASSWORD_STORE_GIT=$HOME/.passwords
fi
# Node
if which node &>/dev/null ; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi
# Colors
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export LS_COLORS="di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
# Terraform
if which terraform &>/dev/null ; then
    complete -C $(which terraform) terraform
fi
# Dedupe PATH
export PATH=$(echo -n $PATH | awk -v RS=: '!($0 in a) {a[$0]; printf("%s%s", length(a) > 1 ? ":" : "", $0)}')
