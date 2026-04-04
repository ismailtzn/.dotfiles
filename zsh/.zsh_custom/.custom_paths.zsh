# CUDA
if [[ -d /usr/local/cuda/bin ]]; then export PATH=/usr/local/cuda/bin:$PATH; fi
# export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# CUSTOM OPENCV
if [[ -d /usr/local/OpenCV ]]; then export PYTHONPATH=/usr/local/OpenCV/lib/python3.12/dist-packages/:$PYTHONPATH; fi


export NVM_DIR="$HOME/.nvm"
# Lazy-load nvm: only initialize on first use of nvm/node/npm/npx
_nvm_load() {
    unset -f nvm node npm npx _nvm_load 2>/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm()  { _nvm_load; nvm  "$@"; }
node() { _nvm_load; node "$@"; }
npm()  { _nvm_load; npm  "$@"; }
npx()  { _nvm_load; npx  "$@"; }

# pipx / local user bin
if [[ -d "$HOME/.local/bin" ]]; then export PATH="$PATH:$HOME/.local/bin"; fi


# Homebrew — detect location for Linux (Linuxbrew) and macOS (Apple Silicon / Intel)
_brew_init() {
    local brew_bin=""
    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        brew_bin=/home/linuxbrew/.linuxbrew/bin/brew       # Linuxbrew
    elif [[ -x /opt/homebrew/bin/brew ]]; then
        brew_bin=/opt/homebrew/bin/brew                    # macOS Apple Silicon
    elif [[ -x /usr/local/bin/brew ]]; then
        brew_bin=/usr/local/bin/brew                       # macOS Intel
    fi
    [[ -n "$brew_bin" ]] && eval "$("$brew_bin" shellenv zsh)"
}
_brew_init
unset -f _brew_init

