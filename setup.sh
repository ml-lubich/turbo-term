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

# Install MesloLGS Nerd Font (required by Powerlevel10k for icons/glyphs)
# Homebrew merged the cask-fonts tap into homebrew/cask, so this works directly.
echo "Installing MesloLGS Nerd Font (required by Powerlevel10k)..."
if brew list --cask font-meslo-lg-nerd-font &>/dev/null; then
    echo "MesloLGS Nerd Font already installed!"
else
    brew install --cask font-meslo-lg-nerd-font
fi

# Also fetch the four official Powerlevel10k MesloLGS NF variants directly,
# in case the cask is unavailable. These are the exact files p10k recommends.
FONT_DIR="$HOME/Library/Fonts"
mkdir -p "$FONT_DIR"
P10K_FONT_BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"
for font_file in \
    "MesloLGS%20NF%20Regular.ttf" \
    "MesloLGS%20NF%20Bold.ttf" \
    "MesloLGS%20NF%20Italic.ttf" \
    "MesloLGS%20NF%20Bold%20Italic.ttf"; do
    decoded_name="${font_file//%20/ }"
    if [ ! -f "$FONT_DIR/$decoded_name" ]; then
        echo "Downloading $decoded_name ..."
        curl -fsSL "$P10K_FONT_BASE/$font_file" -o "$FONT_DIR/$decoded_name"
    else
        echo "$decoded_name already present in $FONT_DIR"
    fi
done
echo "MesloLGS NF installed."

# Install iTerm2 and configure it to use MesloLGS NF
if [ ! -d "/Applications/iTerm.app" ] && ! brew list --cask iterm2 &>/dev/null; then
    echo "Installing iTerm2..."
    brew install --cask iterm2
else
    echo "iTerm2 already installed!"
fi

echo "Configuring iTerm2 default profile to use MesloLGS NF 13pt..."
# Quit iTerm2 if running so it does not overwrite our prefs on exit
osascript -e 'tell application "iTerm2" to quit' >/dev/null 2>&1 || true
sleep 1

# Make sure iTerm2 uses ~/Library/Preferences/com.googlecode.iterm2.plist
# (not a custom folder) and re-read it on next launch.
defaults write com.googlecode.iterm2 PrefsCustomFolder -string ""
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool false

# Patch the Default bookmark (profile) font keys. iTerm2 stores fonts as
# "<PostScript name> <size>". MesloLGS NF PostScript name is "MesloLGS-NF".
ITERM_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
if [ -f "$ITERM_PLIST" ]; then
    /usr/libexec/PlistBuddy -c "Set :\"New Bookmarks\":0:\"Normal Font\" 'MesloLGS-NF 13'" "$ITERM_PLIST" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"Normal Font\" string 'MesloLGS-NF 13'" "$ITERM_PLIST"
    /usr/libexec/PlistBuddy -c "Set :\"New Bookmarks\":0:\"Non Ascii Font\" 'MesloLGS-NF 13'" "$ITERM_PLIST" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"Non Ascii Font\" string 'MesloLGS-NF 13'" "$ITERM_PLIST"
    /usr/libexec/PlistBuddy -c "Set :\"New Bookmarks\":0:\"Use Non-ASCII Font\" true" "$ITERM_PLIST" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"Use Non-ASCII Font\" bool true" "$ITERM_PLIST"
    echo "iTerm2 default profile font set to MesloLGS NF 13pt."
fi

# Force a proper dark color scheme on the iTerm2 Default profile so
# Powerlevel10k's colored segments stay readable. Values are 0.0-1.0 floats
# in iTerm2's "Background Color" / "Foreground Color" dict format.
if [ -f "$ITERM_PLIST" ]; then
    set_iterm_color() {
        # $1 = key (e.g. "Background Color"), $2/$3/$4 = R/G/B floats
        local key="$1" r="$2" g="$3" b="$4"
        /usr/libexec/PlistBuddy -c "Delete :\"New Bookmarks\":0:\"$key\"" "$ITERM_PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\" dict" "$ITERM_PLIST"
        /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\":\"Color Space\" string sRGB" "$ITERM_PLIST"
        /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\":\"Red Component\"   real $r" "$ITERM_PLIST"
        /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\":\"Green Component\" real $g" "$ITERM_PLIST"
        /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\":\"Blue Component\"  real $b" "$ITERM_PLIST"
        /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\":\"Alpha Component\" real 1"  "$ITERM_PLIST"
    }
    # Near-black background, off-white foreground (Dracula-ish).
    set_iterm_color "Background Color" 0.117 0.121 0.149
    set_iterm_color "Foreground Color" 0.972 0.972 0.949
    set_iterm_color "Cursor Color"     0.972 0.972 0.949
    set_iterm_color "Selection Color"  0.266 0.278 0.352
    echo "iTerm2 default profile set to dark theme."
else
    echo "iTerm2 plist not found yet. Launch iTerm2 once, then re-run this script,"
    echo "or set Settings > Profiles > Text > Font to 'MesloLGS NF' manually."
fi

# Also set the macOS built-in Terminal.app default profile to a dark theme
# ("Pro" ships with macOS and is dark) and switch its font to MesloLGS NF.
osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "Terminal"
    set default settings to settings set "Pro"
    set startup settings to settings set "Pro"
    set font name of settings set "Pro" to "MesloLGS NF"
    set font size of settings set "Pro" to 13
end tell
APPLESCRIPT

# Make iTerm2 the default terminal application on macOS.
# macOS does not expose a single "default terminal" toggle, so we register
# iTerm2 as the LaunchServices handler for the shell-script and terminal
# UTIs/URL schemes that Terminal.app normally owns. We use `duti` for this
# (the standard tool for setting macOS default-app handlers from CLI).
echo "Setting iTerm2 as the default terminal handler..."
if ! command -v duti &>/dev/null; then
    brew install duti
fi

ITERM_BUNDLE_ID="com.googlecode.iterm2"
# Shell scripts (.sh, .command, .tool) and the terminal: URL scheme.
duti -s "$ITERM_BUNDLE_ID" public.unix-executable           all 2>/dev/null || true
duti -s "$ITERM_BUNDLE_ID" com.apple.terminal.shell-script  all 2>/dev/null || true
duti -s "$ITERM_BUNDLE_ID" public.shell-script              all 2>/dev/null || true
duti -s "$ITERM_BUNDLE_ID" terminal                                       2>/dev/null || true

# Also flip iTerm2's own "default term" preference so it stops nagging on launch.
defaults write "$ITERM_BUNDLE_ID" "Default Bookmark Guid" -string "" 2>/dev/null || true
defaults write "$ITERM_BUNDLE_ID" NoSyncHaveRequestedFullDiskAccess -bool true 2>/dev/null || true
defaults write "$ITERM_BUNDLE_ID" NoSyncNeverRemindPrefsChangesLostForFile_selection -bool true 2>/dev/null || true

echo "iTerm2 is now the default terminal handler."
echo "Note: macOS has no global 'default terminal' switch — but .sh / .command files"
echo "and 'open -a Terminal' equivalents will now route to iTerm2."

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
