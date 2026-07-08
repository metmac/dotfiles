# ~/.config/shell/env.sh
# Shared *environment* for bash & zsh. POSIX-only — no shell-specific syntax so
# both shells (and /bin/sh) can source it safely. Sourced by login profiles AND
# interactive rc files, so it must be self-sufficient (a non-login interactive
# shell never runs the login profile's brew shellenv).

# Homebrew — put it on PATH here so starship/mise resolve in EVERY interactive
# shell, not just login ones. Guarded so login profiles don't run it twice.
if [ -z "$HOMEBREW_PREFIX" ]; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

export EDITOR="${EDITOR:-vim}"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-R"
export BASH_SILENCE_DEPRECATION_WARNING=1

# Colorized ls — BSD (macOS) vs GNU. Use the shell built-in $OSTYPE so this
# doesn't depend on `uname` being on PATH yet.
case "$OSTYPE" in
  darwin*)
    export CLICOLOR=1
    export LSCOLORS="GxFxCxDxBxegedabagaced"
    ;;
esac

# --- PATH: idempotent prepend (only adds existing dirs, never duplicates) ---
_path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) [ -d "$1" ] && PATH="$1:$PATH" ;;
  esac
}

_path_prepend "$HOME/.local/bin"   # pipx, user scripts
_path_prepend "$HOME/.cargo/bin"   # rust
_path_prepend "$HOME/.pixi/bin"    # pixi-managed global tools (incl. python)
export PATH

# Language runtimes are owned by mise (go, node, ...) and pixi (python).
# Deliberately NO nvm / pyenv / gvm / conda init here — that was the old mess.

# History
export HISTSIZE=100000
export HISTFILESIZE=100000
