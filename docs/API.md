# API

`turbo-term` has no library or CLI flags. The "API" is the script's
invocation contract and the files it touches.

## Invocation

```bash
zsh ./setup.sh
```

- No flags, no positional args, no env vars.
- Must run interactively (the backup step prompts for confirmation on
  first run).
- Requires network access (Homebrew or distro repos, Oh My Zsh
  installer, Powerlevel10k git clone, Nerd Font download on Linux).
- On Linux, expects `sudo` to be available unless invoked as root.

## Supported platforms

| OS | Detection | Package manager | Notes |
|----|-----------|-----------------|-------|
| macOS (Intel + Apple Silicon) | `$OSTYPE == darwin*` | Homebrew | Full feature set, including iTerm2 + Terminal.app + `duti` wiring. |
| Debian / Ubuntu | `apt-get` present | apt | No GUI terminal config; user sets terminal font manually. |
| Fedora / RHEL | `dnf` present | dnf | As above. |
| Arch / Manjaro | `pacman` present | pacman | As above. |

## Exit codes

| Code | Meaning |
|------|---------|
| `0`  | Setup completed (or every step was already in the desired state). |
| `1`  | Pre-flight failed: unsupported OS. |
| `≠0` | A `brew` / `apt` / `dnf` / `pacman` / `curl` / `PlistBuddy` step failed. The script does **not** swallow underlying tool exit codes. |

## Files written

| Path | Platforms | Action |
|------|-----------|--------|
| `~/.zshrc` | all | Append the `turbo-term managed block` exactly once. |
| `~/.zshrc.backup`, `~/.zprofile.backup` | all | Created from the originals on first run, with user confirmation. |
| `~/.p10k.zsh` | all | Copied from the official `p10k-lean.zsh` preset (only if absent). |
| `~/.oh-my-zsh/` | all | Installed by the upstream Oh My Zsh installer. |
| `~/Library/Fonts/MesloLGS NF *.ttf` | macOS | **Removed** if present — the Homebrew cask's `MesloLGSDZNF-Regular` family wins. |
| `~/.local/share/fonts/MesloLGS NF *.ttf` | Linux | Downloaded if missing; `fc-cache -f` refreshes the font cache. |
| `~/Library/Preferences/com.googlecode.iterm2.plist` | macOS | `Normal Font`, `Non Ascii Font`, dark color scheme on the Default bookmark. |
| LaunchServices DB | macOS | iTerm2 registered for `.sh`, `.command`, `public.shell-script`, `terminal:` URL. |
| `/etc/shells` user entry via `chsh` | Linux | Login shell switched to `zsh` (only if `/etc/shells` already lists it). |

## External dependencies installed

**Common (all platforms):** `zsh git curl tmux vim neovim fzf autojump
zsh-syntax-highlighting zsh-autosuggestions eza`, plus Oh My Zsh and
Powerlevel10k under `~/.oh-my-zsh`.

**macOS additionally:** `font-meslo-lg-nerd-font` (cask), `iterm2`
(cask), `duti`.

## Idempotency contract

Re-running `setup.sh` on a configured machine must:

- Not duplicate the managed block in `~/.zshrc`.
- Not re-download fonts that already exist.
- Not overwrite `~/.p10k.zsh` if the user has customized it.
- Not re-prompt for backups if `*.backup` files already exist.
- Not re-run `chsh` if zsh is already the login shell.
