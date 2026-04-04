# fzf key bindings and completion — detect source location across platforms
_fzf_init() {
    # fzf >= 0.48 ships a --zsh flag
    if command -v fzf &>/dev/null && fzf --zsh &>/dev/null 2>&1; then
        source <(fzf --zsh)
        return
    fi
    # Debian/Ubuntu apt package
    local apt_dir="/usr/share/doc/fzf/examples"
    if [[ -f "$apt_dir/key-bindings.zsh" ]]; then
        source "$apt_dir/key-bindings.zsh"
        if [[ -f "$apt_dir/completion.zsh" ]]; then source "$apt_dir/completion.zsh"; fi
        return
    fi
    # Homebrew (macOS or Linuxbrew)
    local brew_fzf=""
    for d in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
        [[ -f "$d/opt/fzf/shell/key-bindings.zsh" ]] && { brew_fzf="$d/opt/fzf/shell"; break; }
    done
    if [[ -n "$brew_fzf" ]]; then
        source "$brew_fzf/key-bindings.zsh"
        if [[ -f "$brew_fzf/completion.zsh" ]]; then source "$brew_fzf/completion.zsh"; fi
    fi
}
_fzf_init
unset -f _fzf_init

# Primeagen-style fzf options
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"

# Cross-platform clipboard helper
_fzf_copy_cmd() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "pbcopy"
    elif command -v xclip &>/dev/null; then
        echo "xclip -selection clipboard"
    elif command -v wl-copy &>/dev/null; then
        echo "wl-copy"
    else
        echo "cat"
    fi
}

# ctrl+r: fuzzy history search
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window down:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | $(_fzf_copy_cmd))+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command to clipboard'"

unset -f _fzf_copy_cmd
