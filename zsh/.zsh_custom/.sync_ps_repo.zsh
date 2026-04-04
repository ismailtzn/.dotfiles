sync_ps_repo() {
  local upstream=""
  local upstream_branch=""
  local do_build=0
  local merge_args=()

  # First two positional arguments are upstream and upstream_branch
  if [[ $# -gt 0 && "$1" != --* ]]; then
    upstream="$1"
    shift
  fi

  if [[ $# -gt 0 && "$1" != --* ]]; then
    upstream_branch="$1"
    shift
  fi

  if [[ -z "$upstream" || -z "$upstream_branch" ]]; then
    echo "✗ Upstream remote and branch name required"
    echo "Usage: sync_ps_repo <upstream> <upstream-branch> [--build] [--merge-args <args...>]"
    return 1
  fi

  # Parse remaining options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build)
        do_build=1
        shift
        ;;
      --merge-args)
        shift
        while [[ $# -gt 0 ]]; do
          merge_args+=("$1")
          shift
        done
        ;;
      *)
        echo "✗ Unknown option: $1"
        echo "Usage: sync_ps_repo <upstream> <upstream-branch> [--build] [--merge-args <args...>]"
        return 1
        ;;
    esac
  done

  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
    echo "✗ Not inside a git repository"
    return 1
  }

  echo ""
  echo "  upstream : $upstream"
  echo "  branch   : $branch"
  echo "  merge    : ${merge_args[*]:-(default)}"
  echo "  build    : $([ $do_build -eq 1 ] && echo yes || echo no)"
  echo ""

  echo "→ Fetching origin..."
  git fetch || { echo "✗ git fetch failed"; return 1 }

  echo "→ Fetching $upstream..."
  git fetch "$upstream" || { echo "✗ git fetch $upstream failed"; return 1 }

  echo "→ Merging $upstream/$upstream_branch..."
  git merge "${merge_args[@]}" "$upstream/$upstream_branch" || { echo "✗ merge failed"; return 1 }

  if [[ $do_build -eq 1 ]]; then
    echo "→ Building..."
    cmake --build build || { echo "✗ cmake build failed"; return 1 }
  else
    echo "⊘ Skipping build (no --build flag)"
  fi

  echo ""
  echo "✓ Done!"
}
