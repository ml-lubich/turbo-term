# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
