# API

`turbo-term` has no library or CLI flags. The "API" is the script's
invocation contract and the files it touches.

## Invocation

```bash
zsh ./setup.sh
```

- No flags, no positional args, no env vars.
- Must run interactively (the backup step prompts for confirmation).
- Requires network access (Homebrew, casks, Oh My Zsh installer).

## Exit codes

| Code | Meaning |
|------|---------|
| `0`  | Setup completed (or every step was already in the desired state). |
| `1`  | Pre-flight failed: not macOS, or invoked from a non-Zsh shell. |
| `≠0` | A `brew install` / `curl` / `PlistBuddy` step failed. The script does **not** swallow underlying tool exit codes. |

## Files written

| Path | Action |
|------|--------|
| `~/.zshrc` | Append the `turbo-term managed block` exactly once. |
| `~/.zshrc.backup`, `~/.zprofile.backup` | Created from the originals on first run, with user confirmation. |
| `~/.p10k.zsh` | Copied from the official `p10k-lean.zsh` preset (only if absent). |
| `~/Library/Fonts/MesloLGS NF *.ttf` | **Removed** if present — the Homebrew cask's `MesloLGSDZNF-Regular` family wins. |
| `~/Library/Preferences/com.googlecode.iterm2.plist` | `Normal Font`, `Non Ascii Font`, dark color scheme on the Default bookmark. |
| LaunchServices DB | iTerm2 registered for `.sh`, `.command`, `public.shell-script`, `terminal:` URL. |

## External dependencies installed

`tmux vim neovim git fzf autojump zsh-syntax-highlighting
zsh-autosuggestions eza duti font-meslo-lg-nerd-font iterm2`
plus Oh My Zsh and Powerlevel10k under `~/.oh-my-zsh`.

## Idempotency contract

Re-running `setup.sh` on a configured machine must:

- Not duplicate the managed block in `~/.zshrc`.
- Not re-download fonts that already exist.
- Not overwrite `~/.p10k.zsh` if the user has customized it.
- Not re-prompt for backups if `*.backup` files already exist.
