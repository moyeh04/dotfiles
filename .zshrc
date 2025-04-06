# Remember to create the symlink when setting up a new device.
# ln -s ~/.config/zsh/.zshrc ~/.zshrc

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname "$ZINIT_HOME")"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

#:$PATH -> First in order
#$PATH: -> Latest in order
export PATH="$HOME/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/lib/ruby/gems/3.4.0/bin:$PATH"



# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab


# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::command-not-found

# Load completions
autoload -U compinit && compinit

zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=15000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias  ls='eza --color'
alias  ll='eza -alh --icons --git'
alias  lt='eza --tree --level=2 --long --icons --git'
alias  help='run-help'
alias  code='code -r .'
alias  v='nvim'
alias  c='cd'
alias  cb='cd ..'
alias  mod='chmod u+x'
alias  s='cd -'
alias  ts='tmux source ~/.tmux.conf'
alias  cl='clear'
alias  cat='bat'
alias  lg='lazygit'
alias  shmx='shmux load "ALX_Workflow"'
alias  up='sudo apt update && sudo apt upgrade -y && brew doctor && brew update && brew upgrade && exec zsh'
alias  b='betty *'
alias  p='python3'
alias  pip='pip3'

# Shell Integrations
# Ensure Homebrew is prioritized in the PATH and load shell integrations.
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
source <(fzf --zsh)
eval "$(zoxide init --cmd cd zsh)"
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/zen.omp.json)"
source ~/.config/shmux/shmux.sh

# Source the custom Python environment fix script
if [ -f "$HOME/.config/zsh/.pyenv" ]; then
   source "$HOME/.config/zsh/.pyenv"
fi
