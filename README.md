# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Works on **Linux** (Debian/Ubuntu/Fedora/Alpine, including devcontainers) and **macOS**.

## Packages

| Package   | What it manages                                                            |
| --------- | -------------------------------------------------------------------------- |
| `tmux`    | `~/.tmux.conf` — Dracula theme, TPM plugins                                |
| `zsh`     | `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, `~/.zsh_custom/` aliases & plugins |
| `p10k`    | `~/.p10k.zsh`, `~/.p10k-lean.zsh` — Powerlevel10k prompt configs           |
| `git`     | `~/.gitconfig`, `~/.config/git/ignore`                                     |
| `vim`     | `~/.vimrc`                                                                 |
| `ghostty` | `~/.config/ghostty/config` — Ghostty terminal config                       |

**Not managed by Stow** (installed by `install.sh` or kept local):

- `~/.oh-my-zsh/` — installed by the oh-my-zsh installer
- `~/.oh-my-zsh/custom/themes/powerlevel10k/` — cloned by `install.sh`
- `~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/` — cloned by `install.sh`
- `~/.oh-my-zsh/custom/plugins/zsh-completions/` — cloned by `install.sh`
- `~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/` — cloned by `install.sh`
- `~/.tmux/plugins/` — installed automatically by TPM via `install.sh`
- `~/.zsh_custom/.env.zsh` — machine-local credentials, never committed
- `~/.zsh_local` — machine-local PATH/alias overrides, never committed
- `~/.gitconfig.local` — machine-local git identity (email, signing key); lives at
  `~/.dotfiles/git/.gitconfig.local` (gitignored) and is stow-linked into `$HOME`

---

## Quick Start (New Machine)

```bash
# 1. Clone the repo
git clone https://github.com/ismailtzn/.dotfiles.git ~/.dotfiles

# 2. Run the bootstrap script
cd ~/.dotfiles
bash install.sh
```

The script will:

1. Install GNU Stow (via apt / apk / dnf on Linux, Homebrew on macOS)
2. Install oh-my-zsh
3. Clone powerlevel10k, zsh-autosuggestions, zsh-completions, zsh-syntax-highlighting
4. Clone TPM (Tmux Plugin Manager) — only if tmux is installed
5. Create a stub `~/.zsh_custom/.env.zsh` for machine-local credentials
6. Back up any existing dotfiles to `~/dotfiles-backup-YYYYMMDD/`
7. Stow all packages (create symlinks in `$HOME`)
8. Install tmux plugins automatically via TPM
9. Set zsh as your default shell

Pass `--dry-run` to preview all steps without making changes:

```bash
bash install.sh --dry-run
```

### After install

1. Set git identity (email, optional signing key). The local file lives **inside**
   `~/.dotfiles/git/` (gitignored) so stow symlinks it to `~/.gitconfig.local`:

   ```bash
   cp ~/.dotfiles/git/.gitconfig.local.example ~/.dotfiles/git/.gitconfig.local
   # edit ~/.dotfiles/git/.gitconfig.local
   cd ~/.dotfiles && stow --restow --no-folding git
   ```

   `install.sh` does the copy automatically on first run.

2. Fill in credentials:

   ```bash
   cp ~/.dotfiles/zsh/.zsh_custom/.env.example ~/.zsh_custom/.env.zsh
   # then edit ~/.zsh_custom/.env.zsh
   ```

3. Create machine-local overrides (Flutter SDK, CUDA, etc.):

   ```bash
   cp ~/.dotfiles/zsh/.zsh_custom/.local.zsh.example ~/.zsh_local
   # then edit ~/.zsh_local
   ```

4. If tmux plugin installation failed, start tmux and press `prefix+I` (default prefix is `Ctrl-b`).

5. If the Powerlevel10k prompt looks wrong, re-run the wizard:

   ```bash
   p10k configure
   ```

---

## macOS vs Linux notes

| Feature                 | macOS                                                   | Linux                          |
| ----------------------- | ------------------------------------------------------- | ------------------------------ |
| Package manager         | Homebrew (`brew`) — install first                       | apt / apk / dnf                |
| Homebrew location       | `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel) | `/home/linuxbrew/.linuxbrew`   |
| File opener (`o` alias) | `open`                                                  | `xdg-open`                     |
| Clipboard               | `pbcopy` / `pbpaste`                                    | `xclip` or `wl-copy`           |
| fzf shell integration   | `/opt/homebrew/opt/fzf/shell/`                          | `/usr/share/doc/fzf/examples/` |
| Ghostty config          | `~/.config/ghostty/config`                              | `~/.config/ghostty/config`     |

---

## Devcontainer / VS Code Remote

Add these to your user `settings.json` to apply dotfiles automatically in every devcontainer:

```json
"dotfiles.repository": "ismailtzn/.dotfiles",
"dotfiles.targetPath": "~/dotfiles",
"dotfiles.installCommand": "install.sh"
```

`install.sh` detects the environment and adapts:

- **No sudo / already root** — uses `apt-get`, `apk`, or `dnf` without `sudo` as appropriate
- **oh-my-zsh unavailable** — `.zshrc` falls back to a minimal zsh config (completions only, no theme)
- **`chsh` fails** — warns instead of exiting; run `exec zsh` or open a new terminal to use zsh
- **tmux not installed** — skips TPM setup silently

---

## Backup

Before stowing, `install.sh` copies any existing plain files (non-symlinks) that would be overwritten to `~/dotfiles-backup-YYYYMMDD/`. The backup preserves the original directory structure relative to `$HOME`.

---

## Adding a New Config

1. Create the package directory mirroring `$HOME`:

   ```bash
   mkdir -p ~/.dotfiles/<package>/path/to/
   mv ~/path/to/configfile ~/.dotfiles/<package>/path/to/configfile
   ```

2. Stow it:

   ```bash
   cd ~/.dotfiles
   stow --no-folding <package>
   ```

3. Commit:

   ```bash
   git add <package>/
   git commit -m "feat: add <tool> config"
   ```

## Re-stow After Changes

```bash
cd ~/.dotfiles
stow --restow --no-folding <package>
# or re-stow everything:
for pkg in tmux zsh p10k git vim ghostty; do stow --restow --no-folding $pkg; done
```
