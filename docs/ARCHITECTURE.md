# Architecture

`turbo-term` is a single-script macOS terminal bootstrapper. There is no
runtime, no daemon, no package — just an idempotent `zsh` install script.

## Module map

```
turbo-term/
├── setup.sh        # the entire installer (only executable)
├── README.md       # landing page + diagrams
└── docs/           # canonical engineering docs (this folder)
```

## Layers

`setup.sh` runs top-down in these phases:

1. **Pre-flight** — assert macOS + Zsh.
2. **Backup** — copy existing `~/.zshrc`, `~/.zprofile` to `*.backup` files.
3. **Homebrew** — install if missing.
4. **CLI tools** — `tmux vim neovim git fzf autojump` + zsh plugins.
5. **Fonts** — install the `font-meslo-lg-nerd-font` Homebrew cask;
   purge any legacy `MesloLGS NF *.ttf` files in `~/Library/Fonts` that
   would shadow it.
6. **iTerm2** — install cask, write font + dark color scheme into the
   default profile via `defaults` and `PlistBuddy`.
7. **LaunchServices** — install `duti` and register iTerm2 as the
   default handler for `.sh` / `.command` / `terminal:` URLs.
8. **Oh My Zsh + Powerlevel10k** — install theme + the
   `powerlevel10k/config/p10k-lean.zsh` preset to `~/.p10k.zsh` so the
   first-run wizard never fires.
9. **`~/.zshrc`** — append a single managed block delimited by
   `# >>> turbo-term managed block >>>` / `# <<< turbo-term managed
   block <<<`. The script is idempotent: re-runs do not duplicate the
   block and do not destroy user customizations outside the markers.

## Invariants

- **Idempotent.** Re-running `setup.sh` must not corrupt `~/.zshrc`
  or duplicate font files.
- **Non-destructive.** User edits outside the managed block survive.
- **Font precedence.** Only the cask's `MesloLGSDZNF-Regular`
  PostScript family is allowed. The legacy `MesloLGS-NF-Regular` files
  from `powerlevel10k-media` must not be present, or icons break.
- **No hidden state.** Everything the script does is visible by reading
  `setup.sh`. No external config files, no env vars required.

## Data flow

```
fresh shell  ──► setup.sh ──► Homebrew ──► tools + fonts + casks
                       │
                       ├──► PlistBuddy ──► ~/Library/Preferences/com.googlecode.iterm2.plist
                       ├──► duti       ──► LaunchServices DB
                       └──► append     ──► ~/.zshrc managed block + ~/.p10k.zsh
```
