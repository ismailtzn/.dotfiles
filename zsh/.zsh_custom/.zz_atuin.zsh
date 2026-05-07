# Atuin — magical shell history (local-only; sync disabled in config.toml)
# Installed by install.sh via the official setup.atuin.sh script to ~/.atuin/bin

# Prepend atuin's bin dir if the official installer was used
if [[ -d "$HOME/.atuin/bin" ]]; then
  case ":$PATH:" in
    *":$HOME/.atuin/bin:"*) ;;
    *) export PATH="$HOME/.atuin/bin:$PATH" ;;
  esac
fi

# Bind Ctrl-R to atuin TUI; leave Up-arrow alone so zsh prefix-history still
# works. fzf's Ctrl-R binding (loaded earlier in .fzf.zsh) gets overwritten —
# atuin's history search is the better tool for this key.
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi
