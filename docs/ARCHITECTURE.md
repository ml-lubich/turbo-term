# Architecture

`turbo-term` is a single-script terminal bootstrapper for **macOS and
Linux** (Debian/Ubuntu, Fedora, Arch). There is no runtime, no daemon,
no package — just an idempotent `zsh` install script.

## Module map

```
turbo-term/
├── setup.sh        # the entire installer (only executable)
├── README.md       # landing page + diagrams
└── docs/           # canonical engineering docs (this folder)
```

## Layers

`setup.sh` runs top-down in these phases:

1. **Pre-flight** — detect OS (`darwin*` → macos, `linux*` → linux);
   on Linux, detect distro family (apt / dnf / pacman). Re-exec under
   `zsh` if invoked from `bash`.
2. **Backup** — copy existing `~/.zshrc`, `~/.zprofile` to `*.backup`
   (only on first run; skipped if backups already exist).
3. **Package manager** — install Homebrew on macOS; refresh apt cache
   on Debian/Ubuntu. A `pkg_install` helper abstracts brew / apt /
   dnf / pacman so the rest of the script stays single-track.
4. **CLI tools** — `zsh git curl tmux vim neovim fzf autojump eza`
   plus zsh syntax-highlighting + autosuggestions plugins, installed
   via the appropriate package manager for the host.
5. **Fonts** —
   - macOS: `font-meslo-lg-nerd-font` Homebrew cask + purge of legacy
     `MesloLGS NF *.ttf` files in `~/Library/Fonts` that would shadow it.
   - Linux: download the four official Powerlevel10k MesloLGS NF
     variants into `~/.local/share/fonts` and run `fc-cache -f`.
6. **macOS-only desktop wiring** — install iTerm2 cask, write the
   font + dark color scheme into the default profile via `defaults`
   and `PlistBuddy`, switch Terminal.app to the dark **Pro** profile,
   and register iTerm2 (via `duti`) as the default handler for `.sh`,
   `.command`, and `terminal:` URLs. Skipped entirely on Linux.
7. **Oh My Zsh + Powerlevel10k** — install theme + the
   `powerlevel10k/config/p10k-lean.zsh` preset to `~/.p10k.zsh` so the
   first-run wizard never fires.
8. **`~/.zshrc`** — append a single managed block delimited by
   `# >>> turbo-term managed block >>>` /
   `# <<< turbo-term managed block <<<`. The managed block probes for
   Homebrew under `/opt/homebrew`, `/usr/local`, and
   `/home/linuxbrew/.linuxbrew`, and sources zsh plugins / fzf
   keybindings from any of the standard install paths on either OS.
9. **Linux-only** — if the user's login shell is not zsh, run `chsh`
   to switch it (only when `/etc/shells` lists the zsh binary).

## Invariants

- **Idempotent.** Re-running `setup.sh` must not corrupt `~/.zshrc`,
  duplicate font files, or re-run the backup prompt.
- **Non-destructive.** User edits outside the managed block survive
  every re-run.
- **Single managed block.** Exactly one block (begin + end markers)
  in `~/.zshrc`. Ever.
- **Font precedence (macOS).** Only the cask's `MesloLGSDZNF-Regular`
  PostScript family is allowed. The legacy `MesloLGS-NF-Regular` files
  must be absent, or icons break.
- **OS isolation.** macOS-only steps (iTerm2, Terminal.app, duti,
  PlistBuddy) live behind `if [[ "$OS" == "macos" ]]` and never run
  on Linux. Linux-only steps (apt update, chsh, fc-cache) never run
  on macOS.
- **No hidden state.** Everything is visible by reading `setup.sh`.
  No external config, no required env vars.

## Data flow

```
fresh shell
   │
   ▼
setup.sh ► detect OS / distro
   │
   ├─ macos  ► Homebrew ► tools + fonts + iTerm2 + duti + Terminal.app
   │
   └─ linux  ► apt|dnf|pacman ► tools + fonts + fc-cache + chsh
   │
   ▼
shared ► Oh My Zsh + Powerlevel10k + ~/.p10k.zsh + ~/.zshrc managed block
```

