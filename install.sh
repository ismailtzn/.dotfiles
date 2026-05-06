#!/usr/bin/env bash
# install.sh — Bootstrap dotfiles for ismail-tuzun
# Works on Linux (including devcontainers, Alpine, Fedora) and macOS.
# Usage (from the dotfiles directory): bash install.sh [options]
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Stow packages — single source of truth (used by usage, backup, stow loops)
STOW_PACKAGES=(tmux zsh p10k git vim ghostty)

# Devcontainer / VS Code dotfiles settings (override via env)
: "${DOTFILES_REPO:=https://github.com/ismailtzn/.dotfiles.git}"
: "${DOTFILES_INSTALL_SCRIPT:=install.sh}"
: "${DOTFILES_TARGET_PATH:=~/dotfiles}"

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
Usage: bash install.sh [OPTIONS]

Bootstrap dotfiles on a new machine using GNU Stow.

OPTIONS:
  -h, --help      Show this help message and exit
      --dry-run   Preview all steps without making any changes
      --restow    Only re-stow packages (skip installations, just update symlinks)
      --no-chsh   Skip changing default shell to zsh (useful in non-interactive
                  contexts like devcontainer dotfiles install where chsh hangs
                  waiting for a password). Auto-skipped when stdin is not a TTY.

WHAT IT DOES:
  1.  Install GNU Stow (via apt / apk / dnf on Linux, Homebrew on macOS)
  2.  Install oh-my-zsh (skipped if already present)
  3.  Clone Powerlevel10k, zsh-autosuggestions, zsh-completions,
      zsh-syntax-highlighting into the oh-my-zsh custom directory
  4.  Clone TPM (Tmux Plugin Manager) — only if tmux is installed
  5.  Create ~/.zsh_custom/.env.zsh from .env.example if not already present
  6.  Back up any existing plain dotfiles to ~/dotfiles-backup-YYYYMMDD/
  7.  Stow all packages: ${STOW_PACKAGES[*]}
  8.  Install tmux plugins via TPM
  9.  Set zsh as the default shell

QUICK START:
  git clone https://github.com/ismailtzn/.dotfiles.git ~/.dotfiles
  cd ~/.dotfiles
  bash install.sh

EXAMPLES:
  bash install.sh              # full install
  bash install.sh --dry-run   # preview without changes
  bash install.sh --restow    # only re-stow symlinks
  bash install.sh --help      # show this message

After install, fill in:
  \$EDITOR ~/.dotfiles/git/.gitconfig.local  # git identity (email, signing key)
  \$EDITOR ~/.zsh_custom/.env.zsh            # credentials

For machine-specific config (Flutter SDK, CUDA paths, etc.) use:
  cp ~/.dotfiles/zsh/.zsh_custom/.local.zsh.example ~/.zsh_local
  \$EDITOR ~/.zsh_local
EOF
}

DRY_RUN=false
RESTOW_ONLY=false
SKIP_CHSH=false
for arg in "$@"; do
    case "$arg" in
        -h|--help)    usage; exit 0 ;;
        --dry-run)    DRY_RUN=true ;;
        --restow)     RESTOW_ONLY=true ;;
        --no-chsh)    SKIP_CHSH=true ;;
        *)            echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
    esac
done

# Auto-skip chsh when stdin isn't a TTY — chsh prompts for a password
# under PAM and would hang forever in a devcontainer dotfiles-install context.
if [[ ! -t 0 ]]; then
    SKIP_CHSH=true
fi

log()  { echo "[dotfiles] $*"; }
warn() { echo "[dotfiles] WARNING: $*" >&2; }
run()  {
    if $DRY_RUN; then
        echo "[dry-run] $*"
    else
        eval "$*"
    fi
}

OS="$(uname -s)"
log "OS: $OS"

# ── Environment detection ─────────────────────────────────────────────────────
IS_ROOT=false; [[ "$(id -u)" == "0" ]] && IS_ROOT=true
HAS_SUDO=false; command -v sudo &>/dev/null && HAS_SUDO=true
HAS_APT=false;  command -v apt-get &>/dev/null && HAS_APT=true
HAS_APK=false;  command -v apk &>/dev/null && HAS_APK=true
HAS_DNF=false;  command -v dnf &>/dev/null && HAS_DNF=true

log "Root: $IS_ROOT | Sudo: $HAS_SUDO | apt: $HAS_APT | apk: $HAS_APK | dnf: $HAS_DNF"

# Install packages using whatever privilege+manager combo is available.
install_packages() {
    local pkgs="$*"
    if [[ "$OS" == "Darwin" ]]; then
        command -v brew &>/dev/null || { warn "Homebrew not found. Install it first: https://brew.sh"; return 1; }
        run "brew install $pkgs"
    elif $HAS_APT; then
        if $IS_ROOT; then
            run "apt-get update -qq && apt-get install -y $pkgs"
        elif $HAS_SUDO; then
            run "sudo apt-get update -qq && sudo apt-get install -y $pkgs"
        else
            warn "apt-get found but no root/sudo to install: $pkgs"; return 1
        fi
    elif $HAS_APK; then
        if $IS_ROOT; then
            run "apk add --no-cache $pkgs"
        elif $HAS_SUDO; then
            run "sudo apk add --no-cache $pkgs"
        else
            warn "apk found but no root/sudo to install: $pkgs"; return 1
        fi
    elif $HAS_DNF; then
        if $IS_ROOT; then
            run "dnf install -y $pkgs"
        elif $HAS_SUDO; then
            run "sudo dnf install -y $pkgs"
        else
            warn "dnf found but no root/sudo to install: $pkgs"; return 1
        fi
    else
        warn "No supported package manager found. Please install manually: $pkgs"
        return 1
    fi
}

# ── 1. Dependencies ───────────────────────────────────────────────────────────
if $RESTOW_ONLY; then
    log "Restow-only mode: skipping installations, jumping to stow..."
fi

if ! $RESTOW_ONLY; then
    if ! command -v stow &>/dev/null; then
        log "Installing stow..."
        if ! install_packages stow curl git zsh; then
            log "ERROR: Could not install stow. Please install it manually and re-run."
            exit 1
        fi
    else
        log "stow already installed: $(stow --version | head -1)"
    fi
fi

# ── 2. Oh My Zsh ──────────────────────────────────────────────────────────────
if ! $RESTOW_ONLY && command -v zsh &>/dev/null; then
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log "Installing oh-my-zsh..."
        if $DRY_RUN; then
            echo "[dry-run] sh -c \"\$(curl -fsSL .../install.sh)\" \"\" --unattended"
        else
            # Bypass run/eval — the installer body contains spaces & shell metachars
            # that eval would re-parse. Run sh -c directly with proper quoting.
            if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
                log "oh-my-zsh installed."
            else
                warn "oh-my-zsh installation failed. Zsh will start with a minimal fallback config."
            fi
        fi
    else
        log "oh-my-zsh already installed."
    fi
elif ! $RESTOW_ONLY; then
    warn "zsh not found. Skipping oh-my-zsh installation."
fi

# oh-my-zsh installer creates ~/.zshrc — remove it so stow can symlink ours
if ! $RESTOW_ONLY && [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    log "Removing oh-my-zsh generated ~/.zshrc (will be replaced by stow)"
    run rm "$HOME/.zshrc"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ── 3. Clone plugins and theme ────────────────────────────────────────────────
clone_if_missing() {
    local url="$1" dest="$2"
    if [[ -d "$dest/.git" ]]; then
        log "Already present: $(basename "$dest")"
        return
    fi
    log "Cloning $(basename "$dest")..."
    if ! run git clone --depth=1 "$url" "$dest"; then
        warn "Failed to clone $(basename "$dest"). Skipping."
    fi
}

if ! $RESTOW_ONLY && [[ -d "$HOME/.oh-my-zsh" ]]; then
    clone_if_missing "https://github.com/romkatv/powerlevel10k.git" \
        "$ZSH_CUSTOM/themes/powerlevel10k"
    clone_if_missing "https://github.com/zsh-users/zsh-autosuggestions" \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    clone_if_missing "https://github.com/zsh-users/zsh-completions" \
        "$ZSH_CUSTOM/plugins/zsh-completions"
    clone_if_missing "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
elif ! $RESTOW_ONLY; then
    log "Skipping zsh plugin cloning (oh-my-zsh not installed)."
fi

# ── 4. TPM (Tmux Plugin Manager) ─────────────────────────────────────────────
if ! $RESTOW_ONLY && command -v tmux &>/dev/null; then
    clone_if_missing "https://github.com/tmux-plugins/tpm" \
        "$HOME/.tmux/plugins/tpm"
elif ! $RESTOW_ONLY; then
    log "tmux not found. Skipping TPM installation."
fi

# ── 5. .env.zsh stub ──────────────────────────────────────────────────────────
ENV_FILE="$HOME/.zsh_custom/.env.zsh"
ENV_EXAMPLE="$DOTFILES_DIR/zsh/.zsh_custom/.env.example"
if ! $RESTOW_ONLY && [[ ! -f "$ENV_FILE" ]]; then
    log "Creating $ENV_FILE from .env.example — fill in your credentials"
    run mkdir -p "$HOME/.zsh_custom"
    if ! $DRY_RUN; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
    fi
elif ! $RESTOW_ONLY; then
    log "$ENV_FILE already exists — not overwriting."
fi

# ── 5b. .gitconfig.local stub (lives inside dotfiles/, gitignored, stow-linked) ──
GITLOCAL_FILE="$DOTFILES_DIR/git/.gitconfig.local"
GITLOCAL_EXAMPLE="$DOTFILES_DIR/git/.gitconfig.local.example"
if ! $RESTOW_ONLY && [[ ! -f "$GITLOCAL_FILE" && -f "$GITLOCAL_EXAMPLE" ]]; then
    log "Creating $GITLOCAL_FILE from example — fill in your git identity"
    if ! $DRY_RUN; then
        cp "$GITLOCAL_EXAMPLE" "$GITLOCAL_FILE"
    fi
elif ! $RESTOW_ONLY && [[ -f "$GITLOCAL_FILE" ]]; then
    log "$GITLOCAL_FILE already exists — not overwriting."
fi

# ── 6. Back up existing dotfiles ─────────────────────────────────────────────
backup_dotfiles() {
    local backup_dir
    backup_dir="$HOME/dotfiles-backup-$(date +%Y%m%d)"
    local backed_up=0
    for pkg in "${STOW_PACKAGES[@]}"; do
        [[ -d "$DOTFILES_DIR/$pkg" ]] || continue
        while IFS= read -r src; do
            local rel="${src#"$DOTFILES_DIR"/"$pkg"/}"
            local target="$HOME/$rel"
            if [[ -f "$target" && ! -L "$target" ]]; then
                local dest_dir
                dest_dir="$backup_dir/$(dirname "$rel")"
                mkdir -p "$dest_dir"
                cp "$target" "$backup_dir/$rel"
                rm "$target"
                log "  Backed up and removed: ~/$rel"
                ((backed_up++)) || true
            fi
        done < <(find "$DOTFILES_DIR/$pkg" -type f 2>/dev/null)
    done
    if [[ $backed_up -gt 0 ]]; then
        log "Backup created at $backup_dir ($backed_up file(s))"
    else
        log "No existing dotfiles to back up."
    fi
}

log "Backing up any existing dotfiles..."
if ! $DRY_RUN; then
    backup_dotfiles
else
    echo "[dry-run] backup_dotfiles (would copy existing plain files to ~/dotfiles-backup-YYYYMMDD/)"
fi

# ── 7. Stow all packages ──────────────────────────────────────────────────────
log "Stowing packages..."
cd "$DOTFILES_DIR"
for pkg in "${STOW_PACKAGES[@]}"; do
    log "  stow $pkg"
    run stow --restow --no-folding --dir="$DOTFILES_DIR" --target="$HOME" "$pkg" \
        2> >(grep -v "^BUG in find_stowed_path" >&2)
done

# ── 8. Install tmux plugins via TPM ──────────────────────────────────────────
TPM_INSTALL="$HOME/.tmux/plugins/tpm/bin/install_plugins"
if [[ -x "$TPM_INSTALL" ]]; then
    log "Installing tmux plugins via TPM..."
    run "$TPM_INSTALL"
else
    log "TPM install script not found. After starting tmux, press prefix+I to install plugins."
fi

# ── 9. Set default shell to zsh ──────────────────────────────────────────────
if ! $RESTOW_ONLY && command -v zsh &>/dev/null; then
    ZSH_BIN="$(command -v zsh)"
    if $SKIP_CHSH; then
        log "Skipping chsh (--no-chsh or non-interactive). Run 'exec zsh' to use zsh."
    elif [[ "$(basename "$SHELL")" != "zsh" ]]; then
        log "Setting zsh as default shell..."
        if ! grep -qxF "$ZSH_BIN" /etc/shells 2>/dev/null; then
            log "Adding $ZSH_BIN to /etc/shells..."
            if $DRY_RUN; then
                echo "[dry-run] echo '$ZSH_BIN' >> /etc/shells"
            elif $IS_ROOT; then
                echo "$ZSH_BIN" >> /etc/shells
            elif $HAS_SUDO; then
                echo "$ZSH_BIN" | sudo tee -a /etc/shells > /dev/null
            else
                warn "$ZSH_BIN is not in /etc/shells. To fix manually: echo '$ZSH_BIN' | sudo tee -a /etc/shells"
            fi
        fi
        # Close stdin so chsh can't hang on a password prompt even if PAM asks.
        if run chsh -s "$ZSH_BIN" </dev/null 2>/dev/null; then
            log "Default shell set to zsh."
        else
            warn "Could not change default shell (chsh failed — this is normal in containers)."
            warn "Run 'exec zsh' or open a new terminal to use zsh."
        fi
    else
        log "zsh is already the default shell."
    fi
fi

# ── 10. VS Code user settings (dotfiles auto-apply in remote/devcontainer) ───
update_vscode_settings() {
    local settings_file
    if [[ "$OS" == "Darwin" ]]; then
        settings_file="$HOME/Library/Application Support/Code/User/settings.json"
    else
        settings_file="$HOME/.config/Code/User/settings.json"
    fi

    local settings_dir
    settings_dir="$(dirname "$settings_file")"
    if [[ ! -d "$settings_dir" ]]; then
        log "VS Code user dir not found ($settings_dir). Skipping settings update."
        return
    fi

    if [[ -f "$settings_file" ]] && grep -q '"dotfiles\.repository"' "$settings_file"; then
        log "VS Code settings.json already has dotfiles.repository — leaving alone."
        return
    fi

    if [[ ! -f "$settings_file" ]]; then
        log "Creating VS Code settings.json with dotfiles configuration..."
        if ! $DRY_RUN; then
            cat > "$settings_file" <<EOF
{
  "dotfiles.repository": "$DOTFILES_REPO",
  "dotfiles.targetPath": "$DOTFILES_TARGET_PATH",
  "dotfiles.installCommand": "$DOTFILES_INSTALL_SCRIPT"
}
EOF
        fi
        return
    fi

    if ! command -v jq &>/dev/null; then
        warn "jq not found. Cannot safely merge into existing $settings_file."
        warn "Add manually:"
        warn "  \"dotfiles.repository\": \"$DOTFILES_REPO\","
        warn "  \"dotfiles.targetPath\": \"$DOTFILES_TARGET_PATH\","
        warn "  \"dotfiles.installCommand\": \"$DOTFILES_INSTALL_SCRIPT\""
        return
    fi

    local tmp
    tmp="$(mktemp)"
    if jq --arg r "$DOTFILES_REPO" --arg t "$DOTFILES_TARGET_PATH" --arg i "$DOTFILES_INSTALL_SCRIPT" \
        '. + {"dotfiles.repository":$r,"dotfiles.targetPath":$t,"dotfiles.installCommand":$i}' \
        "$settings_file" > "$tmp" 2>/dev/null; then
        if $DRY_RUN; then
            echo "[dry-run] merge dotfiles keys into $settings_file"
            rm -f "$tmp"
        else
            mv "$tmp" "$settings_file"
            log "Updated VS Code settings.json with dotfiles keys."
        fi
    else
        rm -f "$tmp"
        warn "jq could not parse $settings_file (likely contains JSONC comments)."
        warn "Add manually:"
        warn "  \"dotfiles.repository\": \"$DOTFILES_REPO\","
        warn "  \"dotfiles.targetPath\": \"$DOTFILES_TARGET_PATH\","
        warn "  \"dotfiles.installCommand\": \"$DOTFILES_INSTALL_SCRIPT\""
    fi
}

if ! $RESTOW_ONLY; then
    update_vscode_settings
fi

log ""
log "Done! Start a new shell session to load your configuration."
log "Remember to:"
log "  1. Edit ~/.dotfiles/git/.gitconfig.local (email, signing key) — stow-linked to ~/.gitconfig.local"
log "  2. Edit ~/.zsh_custom/.env.zsh with your credentials"
