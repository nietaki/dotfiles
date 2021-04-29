source "$HOME/.antigen/antigen.zsh"

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle shrink-path
# antigen bundle z

antigen bundle agkozak/zsh-z
antigen bundle zsh-users/zsh-completions

antigen theme bira
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="bira"

antigen apply

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"
case $TERM in
    xterm*)
        precmd () {
            print -Pn "\e]0;$(shrink_path -t -l)\a"
        }
        ;;
esac

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"


. $HOME/.asdf/asdf.sh

# this fixes bash completions fucking up
autoload bashcompinit
bashcompinit
. $HOME/.asdf/completions/asdf.bash

export EDITOR='nvim'
export VISUAL='nvim'

# export PATH="/$HOME/.pyenv/bin:$PATH"
export PATH="/$HOME/bin:$PATH"
# export PATH="/$HOME/apps/exercism:$PATH"
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"
#
#
# export PATH=$PATH:/usr/local/sbin:/snap/bin

eval "$(direnv hook zsh)"

# emulate sh -c 'source /etc/profile.d/apps-bin-path.sh'

# # for backend scripts and all-around convenience
# alias open=xdg-open

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# # [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

function exhe () {
  iex -e "require IEx.Helpers; IEx.Helpers.h($argv); :erlang.halt"
}

unsetopt AUTO_CD

# export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
# export SDKMAN_DIR="/$HOME/.sdkman"
# [[ -s "/$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "/ome/nietaki/.sdkman/bin/sdkman-init.sh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

function backend_console_old () {
  # first arg is the environment name, feat or live
  local pod_name
  pod_name=( $(kubectl get pods -n $1 -o name | egrep 'pod/backend-[0-9a-f]' | head -n 1) )
  echo "connecting to $pod_name in $1 environment"

  kubectl -n $1 exec -it $pod_name -- bash -c "_build/prod/rel/app/bin/app remote_console"
}

function backend_console () {
  local env=( ${1:-feat} )
  local pod_name=( $(kubectl get pods -n $env -l app=backend --field-selector status.phase=Running -o jsonpath="{.items[0].metadata.name}") )
  local command=( ${2:-remote_console} )
  echo "connecting to $pod_name in $env environment and running $command"

  kubectl -n $env exec -it $pod_name -- bash -c "_build/prod/rel/app/bin/app $command"
}

function gitroot () {
  cd $(git rev-parse --show-toplevel)
}

export PATH="/$HOME/Android/Sdk/platform-tools:$PATH"
export ERL_AFLAGS="-kernel shell_history enabled"

# convenience directory aliases
export repos="$HOME/repos"
export fresha="$repos/fresha"
export system="$fresha/system"
export df="$HOME/.homesick/repos/dotfiles"
export dotfiles="$df"
export puter="$HOME/repos/puter"

# docker helper aliases
alias dkc='docker-compose'
alias dkcr='dkc run --rm'
alias dkcu='dkc up -d'
alias dkcb='dkc build'
alias dkcl='dkc logs -f --tail 200'

source $HOME/.homesick/repos/homeshick/homeshick.sh

# Rust stuff

export PATH="$HOME/.cargo/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"

unsetopt autopushd

# Platform.io
export PATH="$PATH:$HOME/.platformio/penv/bin"
alias pi=platformio


# start a shell session authenticated to AWS
alias aws-shell='aws-vault exec -d 8h -n'

# login to AWS console
alias aws-login='aws-vault login -d 8h'

export PG_OF_PATH=/home/nietaki/repos/of
