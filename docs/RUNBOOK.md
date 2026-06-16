# Runbook

## First-time setup (macOS or Linux)

```bash
git clone https://github.com/ml-lubich/turbo-term.git
cd turbo-term
zsh ./setup.sh
```

During `p10k configure`, setup sends `y` to the Meslo Nerd Font prompt
when `expect` is present. Complete the remaining visual choices
manually.

Then:
- **macOS:** use the fresh iTerm2 window opened by `setup.sh`. Do not
  quit the terminal that is still running setup.
- **Linux:** open a new terminal window (or run `exec zsh`). Set your
  terminal emulator's font to **MesloLGS NF** (size 12–13). For
  GNOME Terminal: Preferences → Profile → Custom font. For
  Konsole/Alacritty/Kitty: edit the font in the profile/config file.
- **Windows via WSL:** run the script inside WSL, then set Windows
  Terminal's font face to **MesloLGS NF** for the WSL profile.

## Supported Linux distros

- Debian / Ubuntu (and derivatives) — uses `apt-get`.
- Fedora / RHEL — uses `dnf`.
- Arch / Manjaro — uses `pacman`.

Other distros: install `zsh git curl tmux vim neovim fzf autojump
expect zsh-syntax-highlighting zsh-autosuggestions eza` manually, then
re-run `setup.sh` — it will detect the missing pieces it cannot install
and still set up Oh My Zsh, Powerlevel10k, fonts, and the managed
`~/.zshrc` block.

## How to re-run safely

`setup.sh` is idempotent. Re-run it any time:

```bash
zsh ./setup.sh
```

It will:
- Skip already-installed packages (brew/apt/dnf/pacman).
- Run Homebrew package/cask installs without install confirmation
  prompts.
- Leave the existing `turbo-term managed block` in `~/.zshrc` alone.
- Leave `~/.p10k.zsh` alone if it already exists.
- Skip the backup prompt if `~/.zshrc.backup` already exists.

On Debian-family systems, use `fd` and `bat` normally after opening a new
shell; the managed block aliases them to `fdfind` and `batcat` when
needed.

## Common failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| Prompt shows boxes / `?` instead of icons (macOS) | Wrong terminal font or iTerm2 profile not refreshed | Re-run `setup.sh`, let setup send `y` in `p10k configure`, then use the fresh iTerm2 window. Verify the iTerm2 profile font is Meslo-based. |
| Prompt shows boxes / `?` instead of icons (Linux) | Terminal emulator is still using its default font | Set the terminal emulator's font to `MesloLGS NF`. Confirm install with `fc-list \| grep -i meslo`. If empty, run `fc-cache -f ~/.local/share/fonts`. |
| Prompt shows boxes / `?` instead of icons (WSL) | Windows Terminal profile still uses the default font | In Windows Terminal Settings, set the WSL profile font face to `MesloLGS NF`, then open a new WSL tab. |
| Powerlevel10k wizard fires on first launch | `~/.p10k.zsh` was missing when shell loaded | Run `p10k configure`; if `expect` is installed, setup sends `y` for Meslo Nerd Font, then you save the generated `~/.p10k.zsh`. |
| `~/.zshrc` looks duplicated | An older non-idempotent script run | Delete the duplicate `turbo-term managed block` (between the `# >>>` / `# <<<` markers) and re-run `setup.sh`. |
| `command not found: brew` after install (macOS) | New shell did not pick up `/opt/homebrew/bin` on PATH | Open a new terminal window, or `exec zsh`. |
| Login shell did not change to zsh (Linux) | `chsh` skipped because `/etc/shells` does not list `$(command -v zsh)` | Add the path manually: `echo $(command -v zsh) \| sudo tee -a /etc/shells`, then `chsh -s $(command -v zsh)`. |
| Double-clicking a `.sh` opens Terminal.app instead of iTerm2 (macOS) | LaunchServices cache stale | `lsregister -kill -r -domain local -domain user; killall Finder` then re-run the duti block in `setup.sh`. |
| iTerm2 colors look washed out / illegible | An older profile is loaded from a custom prefs folder | The script sets `PrefsCustomFolder=""` and `LoadPrefsFromCustomFolder=false`; re-run, then open a fresh iTerm2 window after setup completes. |
| `apt-get install eza` fails on older Debian/Ubuntu | `eza` is only in bookworm-backports and trixie+ | Enable backports, install eza manually, or skip — the managed block tolerates eza being absent. |

## Credential rotation

None required. `setup.sh` reads no secrets and writes no credentials.
The only network calls are to `brew.sh` (macOS), distro mirrors (Linux),
`github.com` (Oh My Zsh installer + Powerlevel10k clone +
powerlevel10k-media font CDN), and Homebrew/distro package CDNs.

## Adding a new tool

1. Add a `pkg_install` line in `setup.sh` with the package name on
   each platform (use `"-"` to skip a platform).
2. If it's a CLI you want aliased, add it inside the managed block
   between the `# >>> turbo-term managed block >>>` markers.
3. Update `docs/API.md` "External dependencies installed".
4. Add a `[Unreleased]` entry in `docs/CHANGELOG.md`.
5. Run `zsh -n setup.sh`.
