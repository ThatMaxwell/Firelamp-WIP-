[[ $- != *i* ]] && return
alias ls='ls --color=auto'
PS1='\[\e[38;2;255;138;61m\]\u@\h\[\e[0m\] \w \[\e[38;2;255;179;71m\]>\[\e[0m\] '
