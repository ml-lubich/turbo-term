# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Linux support** (Debian/Ubuntu via apt, Fedora via dnf, Arch via
  pacman). Cross-platform `pkg_install` helper abstracts the package
  manager so the rest of the script stays single-track.
- Linux font install path: downloads the four official MesloLGS NF
  variants to `~/.local/share/fonts` and runs `fc-cache -f`.
- Linux `chsh` step that switches the login shell to zsh when
  `/etc/shells` already lists it.
- Managed `~/.zshrc` block now probes for Homebrew under
  `/opt/homebrew`, `/usr/local`, **and** `/home/linuxbrew/.linuxbrew`,
  and sources zsh plugins / fzf keybindings from any standard install
  path on either OS.

### Changed
- Pre-flight no longer hard-fails on Linux. macOS-only steps (iTerm2,
  Terminal.app, duti, PlistBuddy) are now gated behind
  `if [[ "$OS" == "macos" ]]` and skipped on Linux.
- Backup prompt is skipped on re-run when `~/.zshrc.backup` already
  exists (was previously prompting every run).

## [0.1.0] - 2026-05-15

### Added
- Idempotent `~/.zshrc` managed block (`# >>> turbo-term managed block >>>`)
  that preserves user customizations across re-runs.
- Auto-install of the Powerlevel10k "lean" preset to `~/.p10k.zsh` so the
  first-launch configuration wizard never fires.
- iTerm2 dark color scheme (Dracula-ish) applied to the Default bookmark.
- iTerm2 registered as the macOS default handler for `.sh` / `.command` /
  `terminal:` via `duti`.
- `eza` install + `ls`/`ll`/`tree` aliases for icon-rendered directory
  listings.
- Non-interactive `fzf` install (`--all --no-bash --no-fish`).
- Five canonical engineering docs under `docs/` (this file plus
  ARCHITECTURE, API, TESTING, RUNBOOK).

### Changed
- iTerm2 profile font switched from `MesloLGS-NF` to
  `MesloLGSDZNF-Regular` (the Homebrew cask's PostScript name) so the
  full Nerd Font glyph range renders correctly.
- Font installation now removes any legacy `MesloLGS NF *.ttf` files in
  `~/Library/Fonts` that would shadow the cask font and break icons.

### Fixed
- Stray backtick syntax error in the iTerm2 plist block that prevented
  `setup.sh` from parsing under `zsh -n`.
