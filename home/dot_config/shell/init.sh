# ~/.config/shell/init.sh
# Interactive shell integrations (prompt, version manager, completions).
# Sourced last by both ~/.bashrc and ~/.zshrc. Detects the running shell so the
# right init hooks are loaded without duplicating logic per rc file.

if [ -n "$ZSH_VERSION" ]; then
  command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
  command -v mise     >/dev/null 2>&1 && eval "$(mise activate zsh)"
elif [ -n "$BASH_VERSION" ]; then
  command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
  command -v mise     >/dev/null 2>&1 && eval "$(mise activate bash)"
fi

# fzf key-bindings + completion, if installed
if command -v fzf >/dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    source <(fzf --zsh) 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(fzf --bash)" 2>/dev/null || true
  fi
fi

# CLI tool completions (bd/beads, nono). Shell-aware; needs compinit (zsh) /
# bash-completion (bash) already loaded — the rc files order these before us.
for _cmd in bd nono; do
  command -v "$_cmd" >/dev/null 2>&1 || continue
  if [ -n "$ZSH_VERSION" ]; then
    source <("$_cmd" completion zsh) 2>/dev/null || true
  elif [ -n "$BASH_VERSION" ]; then
    source <("$_cmd" completion bash) 2>/dev/null || true
  fi
done
unset _cmd
