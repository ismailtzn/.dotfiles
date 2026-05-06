# Devcontainer CLI helpers — auto-apply dotfiles to spun-up containers.
# Override any of these in ~/.zsh_local or ~/.zsh_custom/.env.zsh.
export DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/ismailtzn/.dotfiles.git}"
export DOTFILES_INSTALL_SCRIPT="${DOTFILES_INSTALL_SCRIPT:-install.sh}"
export DOTFILES_TARGET_PATH="${DOTFILES_TARGET_PATH:-~/dotfiles}"

# devup [path]  → bring up devcontainer with dotfiles auto-applied
devup() {
  devcontainer up \
    --workspace-folder "${1:-.}" \
    --dotfiles-repository "$DOTFILES_REPO" \
    --dotfiles-target-path "$DOTFILES_TARGET_PATH" \
    --dotfiles-install-command "$DOTFILES_INSTALL_SCRIPT"
}

# devup-fresh [path] → recreate container from scratch (drops state, re-runs dotfiles install)
devup-fresh() {
  devcontainer up \
    --workspace-folder "${1:-.}" \
    --remove-existing-container \
    --dotfiles-repository "$DOTFILES_REPO" \
    --dotfiles-target-path "$DOTFILES_TARGET_PATH" \
    --dotfiles-install-command "$DOTFILES_INSTALL_SCRIPT"
}

# devzsh [path] → exec zsh inside the running devcontainer (with TTY + TERM passthrough)
# Uses docker exec -it directly so $TERM/$COLORTERM reach zsh; otherwise p10k
# falls back to no-color/no-glyph mode.
devzsh() {
  local folder="${1:-$PWD}"
  folder="${folder:A}"
  local cid
  cid=$(docker ps -q --filter "label=devcontainer.local_folder=$folder" | head -n1)
  if [[ -z "$cid" ]]; then
    echo "No running devcontainer for $folder. Run devup first." >&2
    return 1
  fi
  local user
  user=$(docker inspect -f '{{.Config.User}}' "$cid" 2>/dev/null)
  local -a userarg
  [[ -n "$user" ]] && userarg=(--user "$user")
  docker exec -it \
    "${userarg[@]}" \
    -e TERM="$TERM" \
    -e COLORTERM="${COLORTERM:-truecolor}" \
    -w "/workspaces/$(basename "$folder")" \
    "$cid" zsh -l
}

# devrm [path] → remove the devcontainer for this workspace (next devup recreates it)
devrm() {
  local folder="${1:-$PWD}"
  folder="${folder:A}"
  local cids
  cids=$(docker ps -aq --filter "label=devcontainer.local_folder=$folder")
  if [[ -z "$cids" ]]; then
    echo "No devcontainer found for $folder"
    return 1
  fi
  echo "$cids" | xargs docker rm -f
}

alias devbuild="devcontainer build --workspace-folder ."
