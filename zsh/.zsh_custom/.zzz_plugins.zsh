
if [[ -f /etc/zsh_command_not_found ]]; then source /etc/zsh_command_not_found; fi

# zsh-syntax-highlighting: prefer the OMZ-cloned version, fall back to system path
_zsh_hl=""
[[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
    && _zsh_hl="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[[ -z "$_zsh_hl" && -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
    && _zsh_hl="/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
if [[ -n "$_zsh_hl" ]]; then source "$_zsh_hl"; fi
unset _zsh_hl

(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_pathseparator]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=none
ZSH_HIGHLIGHT_STYLES[precommand]=none
