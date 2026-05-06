# Powerlevel10k lean config — used when the terminal does NOT support Nerd Fonts.
# Automatically selected by ~/.zshrc when $TERM == "linux" or other dumb/TTY environments.
# To regenerate: p10k configure (choose "Unicode" + "Compatible" when asked about fonts).

() {
  emulate -L zsh -o extended_glob

  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  autoload -Uz is-at-least && is-at-least 5.1 || return

  # Use compatible (no Nerd Font glyphs) mode
  typeset -g POWERLEVEL9K_MODE=compatible
  typeset -g POWERLEVEL9K_ICON_PADDING=none

  typeset -g POWERLEVEL9K_BACKGROUND=                            # transparent background
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=  # no surrounding spaces
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '  # space between segments
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=        # no powerline arrows

  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    my_docker    # docker container indicator
    dir          # current directory
    vcs          # git status
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                  # exit code of the last command
    command_execution_time  # duration of the last command
    background_jobs         # presence of background jobs
    virtualenv              # python virtual environment
    pyenv                   # python environment
    nvm                     # node.js version from nvm
    context                 # user@hostname (shown when SSH or non-default)
    time                    # current time
  )

  typeset -g POWERLEVEL9K_SHOW_RULER=false
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%F{%(?.green.red)}❯%f '
  typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL=

  # Prompt layout: two lines
  typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
  typeset -g POWERLEVEL9K_RPROMPT_ON_NEWLINE=false

  # ── dir ───────────────────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=blue
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=blue
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=blue
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=..
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=40

  # ── vcs ───────────────────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=green
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=yellow
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=yellow
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
  typeset -g POWERLEVEL9K_VCS_UNSTAGED_ICON='!'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='+'
  typeset -g POWERLEVEL9K_VCS_STASH_ICON='*'
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='<'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='>'

  # ── status ────────────────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=green
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=red
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=false

  # ── command_execution_time ────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=yellow

  # ── background_jobs ───────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=cyan

  # ── virtualenv / pyenv ────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=cyan
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV=false
  typeset -g POWERLEVEL9K_PYENV_FOREGROUND=cyan
  typeset -g POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW=false
  typeset -g POWERLEVEL9K_PYENV_SHOW_SYSTEM=false

  # ── nvm ───────────────────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_NVM_FOREGROUND=green
  typeset -g POWERLEVEL9K_NVM_PROMPT_ALWAYS_SHOW=false
  typeset -g POWERLEVEL9K_NVM_SHOW_SYSTEM=false

  # ── context (user@host) ───────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND=yellow
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=red
  typeset -g POWERLEVEL9K_CONTEXT_DEFAULT_CONTENT_EXPANSION='%n@%m'
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION=
  # Show context only in SSH or when root
  typeset -g POWERLEVEL9K_CONTEXT_SHOW_ON_COMMAND='sudo|ssh'

  # ── time ──────────────────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=244
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false

  # ── my_docker (container indicator) ───────────────────────────────────────────
  # Show "docker" only when running inside a Docker container.
  function prompt_my_docker() {
    [[ -f /.dockerenv ]] || return
    p10k segment -f blue -t 'docker'
  }
  function instant_prompt_my_docker() { prompt_my_docker }

  # ── Instant prompt ────────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  (( ! $+functions[p10k] )) || p10k reload
}
