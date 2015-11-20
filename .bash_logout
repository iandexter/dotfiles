if [[ $(w -h | wc -l) -le 2 ]] ; then
    killall -u $(whoami) gpg-agent &>/dev/null
fi
history -a &>/dev/null
