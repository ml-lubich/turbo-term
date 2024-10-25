#!/bin/zsh

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script can only be run on macOS."
    exit 1
fi

# Ensure the script is running in Zsh
if [ -n "$BASH_VERSION" ]; then
    echo "Switching to Zsh..."
    exec zsh "$0" "$@"
    exit
fi

# Backup .zshrc and .zprofile
read -q "yn?Do you want to backup your current .zshrc and .zprofile? (y/n) "
echo
if [[ "$yn" =~ [Yy] ]]; then
    cp ~/.zshrc ~/.zshrc.backup && cp ~/.zprofile ~/.zprofile.backup
    echo "Backups created at ~/.zshrc.backup and ~/.zprofile.backup"
else
    echo "Skipping backup."
fi

# Function to add Homebrew to PATH only if it's not already present
add_homebrew_to_path() {
    if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
        echo "Adding Homebrew to PATH in .zprofile and .zshrc..."
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo "Homebrew is already in the PATH!"
    fi
}

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    add_homebrew_to_path
else
    echo "Homebrew is already installed!"
    add_homebrew_to_path
fi

# Install Zsh and Oh My Zsh
if ! command -v zsh &> /dev/null; then
    echo "Installing Zsh..."
    brew install zsh
else
    echo "Zsh is already installed!"
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh is already installed!"
fi

# Install Powerlevel10k theme for Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/custom/themes/powerlevel10k
else
    echo "Powerlevel10k theme is already installed!"
fi

# Install useful plugins and tools
echo "Installing useful plugins and tools..."
brew install fzf autojump zsh-syntax-highlighting zsh-autosuggestions

# Install tmux for terminal multiplexing
brew install tmux

# Install Vim or Neovim
brew install vim neovim

# Install Git if not installed
brew install git

# Install fzf for fuzzy search and setup
$(brew --prefix)/opt/fzf/install

echo "All tools are installed!"

# Configuring Zsh environment
echo "Configuring your Zsh environment..."

# Overwrite the ~/.zshrc file
cat <<EOL > ~/.zshrc

# Set Homebrew path for Apple Silicon
export PATH="/opt/homebrew/bin:\$PATH"

# Enable Powerlevel10k instant prompt (Should be placed at the top)
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation
export ZSH="\$HOME/.oh-my-zsh"

# Load Oh My Zsh configuration and plugins
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git z fzf autojump)

source \$ZSH/oh-my-zsh.sh

# Manually source zsh-autosuggestions and zsh-syntax-highlighting from Homebrew
source /opt/homebrew/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# FZF configuration (Ensure it's installed)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# User Aliases
alias ll='ls -lah'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'
alias gl='git pull'
alias gcb='git checkout -b'
alias gpush='git push origin \$(git_current_branch)'
alias ..='cd ..'

# Custom Functions
mygit() {
  cd ~/Desktop/git && code .
}

project1() { cd ~/projects/project1; }
project2() { cd ~/projects/project2; }

# Enable Vim keybindings in Zsh
bindkey -v

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history

# Auto-correction and completion
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

# Disable dirty check for faster Git operations
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Zsh completion settings
zstyle ':completion:*' rehash true
zstyle ':completion:*' menu select

# Source Powerlevel10k configuration if it exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

EOL

# Apply changes
source ~/.zshrc

echo "Your Zsh environment is configured. Happy coding!"
