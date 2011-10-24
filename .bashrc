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
# Locale
export LC_ALL=C
