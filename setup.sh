#!/usr/bin/env zsh
# turbo-term setup.sh — idempotent terminal bootstrapper for macOS and Linux.
# Re-runnable. Preserves user customizations in ~/.zshrc.

set -euo pipefail

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------
OS=""
DISTRO=""
IS_WSL=0
case "$OSTYPE" in
    darwin*) OS="macos" ;;
    linux*)  OS="linux" ;;
    *)
        echo "Unsupported OS: $OSTYPE (supported: macOS, Linux)."
        exit 1
        ;;
esac

if [[ "$OS" == "linux" ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=1
    fi
    if command -v apt-get &>/dev/null;  then DISTRO="debian"
    elif command -v dnf &>/dev/null;     then DISTRO="fedora"
    elif command -v pacman &>/dev/null;  then DISTRO="arch"
    else
        echo "Linux detected but no supported package manager (apt/dnf/pacman)."
        echo "Install zsh, git, curl, fzf, tmux, vim manually, then re-run."
        DISTRO="unknown"
    fi
fi

echo "Detected: OS=$OS${DISTRO:+ DISTRO=$DISTRO}"

# Ensure the script is running in Zsh (re-exec under zsh if started via bash).
if [ -n "${BASH_VERSION:-}" ]; then
    echo "Switching to Zsh..."
    exec zsh "$0" "$@"
fi

# ---------------------------------------------------------------------------
# Sudo helper (Linux only). On macOS, Homebrew handles privilege itself.
# ---------------------------------------------------------------------------
SUDO=""
if [[ "$OS" == "linux" ]] && [ "$(id -u)" -ne 0 ]; then
    if command -v sudo &>/dev/null; then
        SUDO="sudo"
    else
        echo "WARNING: not root and sudo missing — package installs will fail."
    fi
fi

is_interactive_tty() {
    [[ -t 0 && -t 1 && -r /dev/tty ]]
}

install_p10k_font_with_expect() {
    command -v expect &>/dev/null || return 1
    expect <<'EXPECT'
set timeout 20
set saw_meslo 0
spawn env POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true zsh -ic "p10k configure"
expect {
    -re {Meslo Nerd Font} {
        set saw_meslo 1
        exp_continue
    }
    -re {Choice \[ynq\]:} {
        if {$saw_meslo == 0} {
            interact
            exit 0
        }
        send "y\r"
        interact
    }
    eof {
        catch wait result
        exit [lindex $result 3]
    }
    timeout {
        interact
    }
}
EXPECT
}

run_p10k_configure() {
    if ! is_interactive_tty; then
        echo "Skipping p10k configure (no interactive TTY)."
        return 0
    fi
    echo
    echo "Powerlevel10k will configure the prompt."
    echo "If the Meslo prompt appears, setup.sh sends 'y' automatically."
    local answer=""
    read "answer?Run 'p10k configure' now? (Y/n) "
    case "$answer" in [Nn]*) return 0 ;; esac
    install_p10k_font_with_expect || POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true zsh -ic 'p10k configure' </dev/tty >/dev/tty 2>&1
}

verify_macos_font() {
    fc-match 'MesloLGS NF' &>/dev/null && return 0
    find "$HOME/Library/Fonts" -iname '*Meslo*' -print -quit 2>/dev/null | grep -q . && return 0
    echo "WARNING: MesloLGS font not visible yet; open a fresh terminal after setup."
}

verify_linux_font() {
    command -v fc-list &>/dev/null || return 0
    fc-list | grep -qi 'MesloLGS' && return 0
    echo "WARNING: MesloLGS font not visible to fontconfig yet."
}

verify_meslo_font() {
    case "$OS" in
        macos) verify_macos_font ;;
        linux) verify_linux_font ;;
    esac
}

open_fresh_iterm_window() {
    [[ "$OS" == "macos" ]] || return 0
    command -v osascript &>/dev/null || return 0
    echo "Opening a fresh iTerm2 window for font/profile validation..."
    {
        sleep 1
        osascript <<'APPLESCRIPT' >/dev/null 2>&1
tell application "iTerm2"
    activate
    create window with default profile
end tell
APPLESCRIPT
    } &!
}

# ---------------------------------------------------------------------------
# Cross-platform package installer
# ---------------------------------------------------------------------------
pkg_install() {
    # Usage: pkg_install <macos-brew-pkg> <debian-pkg> <fedora-pkg> <arch-pkg>
    # Pass "-" to skip a platform.
    local mac_pkg="$1" deb_pkg="$2" fed_pkg="$3" arch_pkg="$4"
    case "$OS" in
        macos)
            [[ "$mac_pkg" == "-" ]] && return 0
            brew list "$mac_pkg" &>/dev/null && return 0
            HOMEBREW_NO_ASK=1 brew install --formula --no-ask "$mac_pkg"
            ;;
        linux)
            case "$DISTRO" in
                debian)
                    [[ "$deb_pkg" == "-" ]] && return 0
                    dpkg -s "$deb_pkg" &>/dev/null && return 0
                    $SUDO apt-get install -y "$deb_pkg"
                    ;;
                fedora)
                    [[ "$fed_pkg" == "-" ]] && return 0
                    rpm -q "$fed_pkg" &>/dev/null && return 0
                    $SUDO dnf install -y "$fed_pkg"
                    ;;
                arch)
                    [[ "$arch_pkg" == "-" ]] && return 0
                    pacman -Q "$arch_pkg" &>/dev/null && return 0
                    $SUDO pacman -S --noconfirm --needed "$arch_pkg"
                    ;;
            esac
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Backup .zshrc / .zprofile
# ---------------------------------------------------------------------------
if [ -f "$HOME/.zshrc" ] || [ -f "$HOME/.zprofile" ]; then
    if [ ! -f "$HOME/.zshrc.backup" ] && [ ! -f "$HOME/.zprofile.backup" ]; then
        read -q "yn?Back up current .zshrc and .zprofile? (y/n) "
        echo
        if [[ "$yn" =~ [Yy] ]]; then
            [ -f "$HOME/.zshrc" ]    && cp "$HOME/.zshrc"    "$HOME/.zshrc.backup"
            [ -f "$HOME/.zprofile" ] && cp "$HOME/.zprofile" "$HOME/.zprofile.backup"
            echo "Backups created at ~/.zshrc.backup and ~/.zprofile.backup"
        else
            echo "Skipping backup."
        fi
    else
        echo "Backups already exist; skipping."
    fi
fi

# ---------------------------------------------------------------------------
# macOS: install Homebrew
# Linux: refresh package metadata
# ---------------------------------------------------------------------------
if [[ "$OS" == "macos" ]]; then
    add_homebrew_to_path() {
        if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
            echo "Adding Homebrew to PATH in .zprofile..."
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    }
    if ! command -v brew &>/dev/null; then
        echo "Homebrew not found, installing..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    add_homebrew_to_path
elif [[ "$OS" == "linux" && "$DISTRO" == "debian" ]]; then
    $SUDO apt-get update -y
fi

# ---------------------------------------------------------------------------
# Core CLI tools (cross-platform)
# ---------------------------------------------------------------------------
echo "Installing core tools..."
pkg_install zsh        zsh        zsh        zsh
pkg_install git        git        git        git
pkg_install curl       curl       curl       curl
pkg_install tmux       tmux       tmux       tmux
pkg_install vim        vim        vim        vim
pkg_install neovim     neovim     neovim     neovim
pkg_install fzf        fzf        fzf        fzf
pkg_install autojump   autojump   autojump   autojump
pkg_install expect     expect      expect      expect
pkg_install ripgrep    ripgrep    ripgrep    ripgrep
pkg_install fd         fd-find     fd-find     fd
pkg_install bat        bat         bat         bat
pkg_install jq         jq          jq          jq
pkg_install htop       htop        htop        htop
pkg_install tree       tree        tree        tree
pkg_install wget       wget        wget        wget
# zsh plugins: Homebrew packages on mac, distro packages on Linux where available.
pkg_install zsh-syntax-highlighting  zsh-syntax-highlighting  zsh-syntax-highlighting  zsh-syntax-highlighting
pkg_install zsh-autosuggestions      zsh-autosuggestions      zsh-autosuggestions      zsh-autosuggestions
# eza (modern ls). Debian package is "eza" on bookworm-backports / trixie+.
pkg_install eza        eza        eza        eza

# ---------------------------------------------------------------------------
# Oh My Zsh
# ---------------------------------------------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed."
fi

# ---------------------------------------------------------------------------
# Powerlevel10k
# ---------------------------------------------------------------------------
P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    echo "Powerlevel10k already installed."
fi

# ---------------------------------------------------------------------------
# MesloLGS Nerd Font
#   macOS: Homebrew cask; p10k configure may also install official MesloLGS NF.
#   Linux: download official p10k variants to ~/.local/share/fonts and
#          refresh fontconfig cache.
# ---------------------------------------------------------------------------
echo "Installing MesloLGS Nerd Font..."
if [[ "$OS" == "macos" ]]; then
    if brew list --cask font-meslo-lg-nerd-font &>/dev/null; then
        echo "MesloLGS Nerd Font already installed."
    else
        HOMEBREW_NO_ASK=1 brew install --cask --no-ask font-meslo-lg-nerd-font
    fi
    echo "Powerlevel10k may also install official MesloLGS NF files during configure."
else
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    P10K_FONT_BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"
    installed_any=0
    for font_file in \
        "MesloLGS%20NF%20Regular.ttf" \
        "MesloLGS%20NF%20Bold.ttf" \
        "MesloLGS%20NF%20Italic.ttf" \
        "MesloLGS%20NF%20Bold%20Italic.ttf"; do
        decoded_name="${font_file//%20/ }"
        if [ ! -f "$FONT_DIR/$decoded_name" ]; then
            echo "Downloading $decoded_name ..."
            curl -fsSL "$P10K_FONT_BASE/$font_file" -o "$FONT_DIR/$decoded_name"
            installed_any=1
        fi
    done
    if [ "$installed_any" -eq 1 ] && command -v fc-cache &>/dev/null; then
        echo "Refreshing fontconfig cache..."
        fc-cache -f "$FONT_DIR"
    fi
    if [[ "$IS_WSL" -eq 1 ]]; then
        echo "WSL detected: set Windows Terminal font face to 'MesloLGS NF'."
    fi
    echo "MesloLGS NF installed to $FONT_DIR. Configure your terminal emulator"
    echo "to use 'MesloLGS NF' (size 12-13)."
fi
verify_meslo_font

# ---------------------------------------------------------------------------
# macOS-only: iTerm2 + Terminal.app + duti default-handler wiring
# ---------------------------------------------------------------------------
if [[ "$OS" == "macos" ]]; then
    if [ ! -d "/Applications/iTerm.app" ] && ! brew list --cask iterm2 &>/dev/null; then
        echo "Installing iTerm2..."
        HOMEBREW_NO_ASK=1 brew install --cask --no-ask iterm2
    else
        echo "iTerm2 already installed."
    fi

    echo "Configuring iTerm2 default profile without quitting the running terminal..."

    defaults write com.googlecode.iterm2 PrefsCustomFolder -string ""
    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool false

    ITERM_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    if [ -f "$ITERM_PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Set :\"New Bookmarks\":0:\"Normal Font\" 'MesloLGSDZNFM-Regular 13'" "$ITERM_PLIST" 2>/dev/null \
            || /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"Normal Font\" string 'MesloLGSDZNFM-Regular 13'" "$ITERM_PLIST"
        /usr/libexec/PlistBuddy -c "Set :\"New Bookmarks\":0:\"Non Ascii Font\" 'MesloLGSDZNFM-Regular 13'" "$ITERM_PLIST" 2>/dev/null \
            || /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"Non Ascii Font\" string 'MesloLGSDZNFM-Regular 13'" "$ITERM_PLIST"
        /usr/libexec/PlistBuddy -c "Set :\"New Bookmarks\":0:\"Use Non-ASCII Font\" true" "$ITERM_PLIST" 2>/dev/null \
            || /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"Use Non-ASCII Font\" bool true" "$ITERM_PLIST"
        echo "iTerm2 default profile font set to MesloLGSDZNFM-Regular 13pt."

        set_iterm_color() {
            local key="$1" r="$2" g="$3" b="$4"
            /usr/libexec/PlistBuddy -c "Delete :\"New Bookmarks\":0:\"$key\"" "$ITERM_PLIST" 2>/dev/null || true
            /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\" dict" "$ITERM_PLIST"
            /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\":\"Color Space\" string sRGB" "$ITERM_PLIST"
            /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\":\"Red Component\"   real $r" "$ITERM_PLIST"
            /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\":\"Green Component\" real $g" "$ITERM_PLIST"
            /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\":\"Blue Component\"  real $b" "$ITERM_PLIST"
            /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:\"$key\":\"Alpha Component\" real 1"  "$ITERM_PLIST"
        }
        set_iterm_color "Background Color" 0.117 0.121 0.149
        set_iterm_color "Foreground Color" 0.972 0.972 0.949
        set_iterm_color "Cursor Color"     0.972 0.972 0.949
        set_iterm_color "Selection Color"  0.266 0.278 0.352
        echo "iTerm2 default profile set to dark theme."
    else
        echo "iTerm2 plist not found yet. Launch iTerm2 once, then re-run."
    fi

    osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "Terminal"
    set default settings to settings set "Pro"
    set startup settings to settings set "Pro"
    set font name of settings set "Pro" to "MesloLGS NF"
    set font size of settings set "Pro" to 13
end tell
APPLESCRIPT

    echo "Setting iTerm2 as the default terminal handler..."
    if ! command -v duti &>/dev/null; then
        HOMEBREW_NO_ASK=1 brew install --formula --no-ask duti
    fi
    ITERM_BUNDLE_ID="com.googlecode.iterm2"
    duti -s "$ITERM_BUNDLE_ID" public.unix-executable           all 2>/dev/null || true
    duti -s "$ITERM_BUNDLE_ID" com.apple.terminal.shell-script  all 2>/dev/null || true
    duti -s "$ITERM_BUNDLE_ID" public.shell-script              all 2>/dev/null || true
    duti -s "$ITERM_BUNDLE_ID" terminal                             2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# fzf keybindings + completion (non-interactive)
# ---------------------------------------------------------------------------
if [[ "$OS" == "macos" ]]; then
    "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish || true
elif [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    echo "fzf keybindings provided by distro package; will be sourced from ~/.zshrc."
fi

# ---------------------------------------------------------------------------
# Idempotent ~/.zshrc managed block
# ---------------------------------------------------------------------------
echo "Configuring ~/.zshrc (managed block)..."
ZSHRC="$HOME/.zshrc"
TURBO_BEGIN="# >>> turbo-term managed block >>>"
[ -f "$ZSHRC" ] || touch "$ZSHRC"

if grep -q "$TURBO_BEGIN" "$ZSHRC"; then
    echo "turbo-term managed block already present in ~/.zshrc; leaving it."
else
    echo "Appending turbo-term managed block to ~/.zshrc..."
    cat <<'EOL' >> "$ZSHRC"

# >>> turbo-term managed block >>>
# Managed by turbo-term/setup.sh. Edit between the markers ABOVE/BELOW only.

# Homebrew on PATH (covers Apple Silicon, Intel mac, and Linuxbrew).
for brew_prefix in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [ -x "$brew_prefix/bin/brew" ]; then
        eval "$($brew_prefix/bin/brew shellenv)"
        break
    fi
done

# Powerlevel10k instant prompt (must stay near the top of the managed block).
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git z fzf autojump)
source "$ZSH/oh-my-zsh.sh"

# zsh-autosuggestions / zsh-syntax-highlighting from any of the common
# install locations (Homebrew on macOS/Linuxbrew, apt on Debian/Ubuntu,
# dnf on Fedora, pacman on Arch).
for autosug in \
    /opt/homebrew/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/local/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /home/linuxbrew/.linuxbrew/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; do
    [ -r "$autosug" ] && { source "$autosug"; break; }
done
for syntax in \
    /opt/homebrew/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/local/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /home/linuxbrew/.linuxbrew/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
    [ -r "$syntax" ] && { source "$syntax"; break; }
done

# fzf — try the user-installed file first, then distro-provided examples.
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
else
    [ -r /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
    [ -r /usr/share/doc/fzf/examples/completion.zsh ]   && source /usr/share/doc/fzf/examples/completion.zsh
    [ -r /usr/share/fzf/key-bindings.zsh ]              && source /usr/share/fzf/key-bindings.zsh
    [ -r /usr/share/fzf/completion.zsh ]                && source /usr/share/fzf/completion.zsh
fi

# Modern ls replacement: eza (per-file icons + git status).
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --git'
    alias ll='eza -l -a --icons --git --group-directories-first'
    alias tree='eza --tree --icons'
fi

# Debian exposes these binaries under alternate names.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    alias fd='fdfind'
fi
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
fi

# Common git aliases
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'
alias gl='git pull'
alias gcb='git checkout -b'
alias ..='cd ..'

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history

# Completion
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
zstyle ':completion:*' rehash true
zstyle ':completion:*' menu select

# Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# <<< turbo-term managed block <<<
EOL
fi

# ---------------------------------------------------------------------------
# Powerlevel10k interactive prompt setup.
# ---------------------------------------------------------------------------
run_p10k_configure

# ---------------------------------------------------------------------------
# Make zsh the user's login shell (Linux only — macOS already defaults zsh).
# ---------------------------------------------------------------------------
if [[ "$OS" == "linux" ]]; then
    ZSH_BIN="$(command -v zsh)"
    if [ -n "$ZSH_BIN" ] && [ "$SHELL" != "$ZSH_BIN" ]; then
        echo "Changing login shell to $ZSH_BIN ..."
        if grep -q "^$ZSH_BIN$" /etc/shells 2>/dev/null; then
            chsh -s "$ZSH_BIN" || echo "chsh failed; run manually: chsh -s $ZSH_BIN"
        else
            echo "$ZSH_BIN not in /etc/shells; skipping chsh."
        fi
    fi
fi

open_fresh_iterm_window

cat <<'NOTICE'

============================================================
  Setup complete.
============================================================

Next steps:
  1. macOS: use the fresh iTerm2 window opened by setup.sh. Do not
     quit the terminal that is running setup.sh.
     Linux: open a new terminal window (or run 'exec zsh').
            Set your terminal emulator's font to 'MesloLGS NF'.
     WSL: set Windows Terminal font face to 'MesloLGS NF'.
  2. setup.sh sends 'y' to the p10k Meslo prompt when expect is present.
  3. Validate icons with:  echo $'\uf015 \uf07b \ue0a0'
  4. To reload your shell without reopening:  exec zsh

============================================================
NOTICE
