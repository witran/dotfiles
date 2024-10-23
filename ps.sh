#!/bin/sh

function bash_iterm_title {
  if [ "$1" ]
  then
    unset PROMPT_COMMAND
    echo -ne "\033]0;${*}\007"
  else
    export PROMPT_COMMAND='echo -ne "\033]0;${PWD##*/}\007"'
  fi
}

function bash_prompt {
  local BLACK="\[\033[0;30m\]"
  local BLACKBOLD="\[\033[1;30m\]"
  local RED="\[\033[0;31m\]"
  local REDBOLD="\[\033[1;31m\]"
  local GREEN="\[\033[0;32m\]"
  local GREENBOLD="\[\033[1;32m\]"
  local YELLOW="\[\033[0;33m\]"
  local YELLOWBOLD="\[\033[1;33m\]"
  local BLUE="\[\033[0;34m\]"
  local BLUEBOLD="\[\033[1;34m\]"
  local PURPLE="\[\033[0;35m\]"
  local PURPLEBOLD="\[\033[1;35m\]"
  local CYAN="\[\033[0;36m\]"
  local CYANBOLD="\[\033[1;36m\]"
  local WHITE="\[\033[0;37m\]"
  local WHITEBOLD="\[\033[1;37m\]"
  local RESETCOLOR="\[\e[00m\]"

  export PS1="$RED\u $GREEN\w $RESETCOLOR$BLUEBOLD\$(git rev-parse --abbrev-ref HEAD 2> /dev/null)\n$WHITE> $RESETCOLOR"
  export PS2="$ $RESETCOLOR"
}

function zsh_prompt {
  autoload -U colors && colors
  autoload -Uz vcs_info
  precmd { vcs_info }
  export PS1=""
}

if [[ $0 == *"zsh"* ]]; then
  #zsh_prompt
  echo "zsh"
else
  bash_iterm_title
  bash_prompt
fi

