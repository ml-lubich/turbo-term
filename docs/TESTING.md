# Testing

`turbo-term` is a single Zsh script with no automated test framework.
Verification is a documented manual procedure plus a syntax gate.

## Definition of Done

A change to `setup.sh` is not done until **all** of the following pass:

1. **Static syntax check (mandatory):**
   ```bash
   zsh -n setup.sh
   ```
   Must exit `0`.

2. **Re-run idempotency (mandatory on a configured machine):**
   ```bash
   zsh ./setup.sh
   grep -c 'turbo-term managed block' ~/.zshrc   # must print 2 (begin + end markers)
   ls "$HOME/Library/Fonts" | grep -c '^MesloLGS NF '   # must print 0
   ```

3. **Fresh-machine smoke (when reasonably possible):**
   - Run `setup.sh` on a clean macOS VM or fresh user account.
   - Open a new iTerm2 window — the prompt is Powerlevel10k "lean", icons render.
   - `command -v eza tmux nvim fzf duti` all resolve.
   - `defaults read com.googlecode.iterm2 'New Bookmarks' | grep -E 'Normal Font|Background Color'`
     shows `MesloLGSDZNF-Regular 13` and the dark color dict.

4. **Icon sanity:** in a new iTerm2 window, `echo $'\uf015 \uf07b \ue0a0'`
   must render three Nerd Font glyphs (house, folder, git branch),
   not boxes/question marks.

## Negative fixtures (intentionally NOT tested)

- Linux / WSL — script asserts `darwin*` and exits.
- Bash invocation — script refuses if `BASH_VERSION` is set.
- Offline mode — Homebrew/curl steps will fail; that is expected.

## Verification command (one-liner)

```bash
zsh -n setup.sh && echo "syntax OK"
```

That is the only command safe to run in CI / from another agent.
Anything beyond it mutates the host machine.
