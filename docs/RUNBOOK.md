# Runbook

## First-time setup

```bash
git clone https://github.com/ml-lubich/turbo-term.git
cd turbo-term
zsh ./setup.sh
```

Then **quit iTerm2 fully (Cmd+Q)** and reopen it. Font and color scheme
changes only apply to fresh iTerm2 windows.

## How to re-run safely

`setup.sh` is idempotent. Re-run it any time:

```bash
zsh ./setup.sh
```

It will:
- Skip already-installed Homebrew packages.
- Leave the existing `turbo-term managed block` in `~/.zshrc` alone.
- Leave `~/.p10k.zsh` alone if it already exists.

## Common failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| Prompt shows boxes / `?` instead of icons | Wrong terminal font, or legacy `MesloLGS NF *.ttf` files in `~/Library/Fonts` shadowing the cask | Re-run `setup.sh` (it now purges the legacy files), then quit + reopen iTerm2. Verify the iTerm2 profile font is `MesloLGSDZNF-Regular 13`. |
| Powerlevel10k wizard fires on first launch | `~/.p10k.zsh` was missing when shell loaded | Re-run `setup.sh` to install the lean preset, or run `p10k configure` once and save. |
| `~/.zshrc` looks duplicated | An older non-idempotent script run | Delete the duplicate `turbo-term managed block` (between the `# >>>` / `# <<<` markers) and re-run `setup.sh`. |
| `command not found: brew` after install | New shell did not pick up `/opt/homebrew/bin` on PATH | Open a new terminal window, or `exec zsh`. |
| Double-clicking a `.sh` opens Terminal.app instead of iTerm2 | LaunchServices cache stale | `lsregister -kill -r -domain local -domain user; killall Finder` then re-run the duti block in `setup.sh`. |
| iTerm2 colors look washed out / illegible | An older profile is loaded from a custom prefs folder | The script sets `PrefsCustomFolder=""` and `LoadPrefsFromCustomFolder=false`; re-run, then **fully quit** iTerm2 before reopening. |

## Credential rotation

None required. `setup.sh` reads no secrets and writes no credentials.
The only network calls are to `brew.sh`, `github.com` (Oh My Zsh
installer + Powerlevel10k clone), and Homebrew bottle/cask CDNs.

## Adding a new tool

1. Add the formula/cask to the relevant `brew install` line in `setup.sh`.
2. If it's a CLI you want aliased, add it inside the managed block
   between the `# >>> turbo-term managed block >>>` markers.
3. Update `docs/API.md` "External dependencies installed".
4. Add a `[Unreleased]` entry in `docs/CHANGELOG.md`.
5. Run `zsh -n setup.sh`.
