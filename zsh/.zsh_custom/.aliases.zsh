
alias cdw="cd ~/work/"
alias tm="tmux a || tmux"
alias c="code ."
alias venv_activate="source .venv/bin/activate"

# Cross-platform file/URL opener
if [[ "$(uname -s)" == "Darwin" ]]; then
  alias o="open"
else
  alias o="xdg-open"
fi

alias wq=':'      # does nothing
alias w!=':'      # does nothing
alias got="git"
alias gıt="git"

runAppUnderBuild() {
  local t
  t="$(find build -maxdepth 1 -type l -printf '%f\n' | head -n 1)"
  if [ -z "$t" ]; then
    echo "No top-level symlink found in ./build" >&2
    return 1
  fi
  "./build/$t" "$@"
}
