# Testing

`turbo-term` is a single Zsh script with no automated test framework.
Verification is a documented manual procedure plus a syntax gate that
runs on any host (macOS or Linux).

## Definition of Done

A change to `setup.sh` is not done until **all** of the following pass:

1. **Static syntax check (mandatory, host-agnostic):**
   ```bash
   zsh -n setup.sh
   ```
   Must exit `0`.

2. **Re-run idempotency (mandatory on a configured machine):**
   ```bash
   zsh ./setup.sh
   grep -c 'turbo-term managed block' ~/.zshrc   # must print 2 (begin + end markers)
   ```
   On macOS additionally:
   ```bash
   ls "$HOME/Library/Fonts" | grep -c '^MesloLGS NF '   # must print 0
   ```
   On Linux additionally:
   ```bash
   fc-list | grep -ci meslolgs   # must be > 0
   ```

3. **Fresh-machine smoke (when reasonably possible):**
   - Run `setup.sh` on a clean macOS VM **and** on a clean Linux VM
     (Debian/Ubuntu, Fedora, or Arch).
   - Open a new terminal — the prompt is Powerlevel10k "lean", icons
     render.
   - `command -v eza tmux nvim fzf` all resolve.
   - macOS only: `command -v duti` resolves;
     `defaults read com.googlecode.iterm2 'New Bookmarks' | grep -E 'Normal Font|Background Color'`
     shows `MesloLGSDZNF-Regular 13` and the dark color dict.

4. **Icon sanity:** in a new terminal window, `echo $'\uf015 \uf07b \ue0a0'`
   must render three Nerd Font glyphs (house, folder, git branch),
   not boxes/question marks.

## Negative fixtures (intentionally NOT tested)

- Windows / WSL — script asserts `darwin*` or `linux*` and exits on
  anything else.
- Linux distros without apt/dnf/pacman — script logs a warning, sets
  `DISTRO=unknown`, and skips package installs (Oh My Zsh +
  Powerlevel10k + managed `~/.zshrc` still install).
- Offline mode — Homebrew / apt / curl steps will fail; expected.

## Verification command (one-liner, safe everywhere)

```bash
zsh -n setup.sh && echo "syntax OK"
```

That is the only command safe to run in CI / from another agent.
Anything beyond it mutates the host machine.
