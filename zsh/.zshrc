# If you come from bash you might have to change your $PATH.
export PATH=$PATH:$HOME/bin:/usr/local/bin:/opt/homebrew/opt/python@3.11/libexec/bin
export TZ='Europe/Amsterdam'

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="robbyrussell"
source "/opt/homebrew/opt/spaceship/spaceship.zsh"

SPACESHIP_PROMPT_ORDER=(
  dir
  git
  line_sep
  char
)

SPACESHIP_DIR_TRUNC_REPO=true
SPACESHIP_DIR_COLOR="blue"
SPACESHIP_GIT_BRANCH_COLOR="magenta"
SPACESHIP_GIT_STATUS_COLOR="cyan"

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
)

source $ZSH/oh-my-zsh.sh

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
alias vim="nvim"
alias v="nvim"
alias gprune="git checkout main && git fetch --prune && git pull --rebase origin HEAD && git branch -l | xargs git branch -D"
alias ls='eza -lha --icons=auto'

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Zoxide for fast navigation
eval "$(zoxide init zsh --cmd cd)"

# Direnv for
eval "$(direnv hook zsh)"
