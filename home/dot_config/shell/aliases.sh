# ~/.config/shell/aliases.sh
# Shared aliases + small alias-like functions for bash & zsh.

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias mk='mkdir -p'
alias c='clear'
alias path='printf "%s\n" $PATH | tr ":" "\n"'
alias reload='exec "$SHELL" -l'

# Listing — prefer eza (installed via brew), fall back to coreutils ls
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lhg --git --group-directories-first'
  alias la='eza -lahg --git --group-directories-first'
  alias lt='eza --tree --level=2'
else
  alias ll='ls -lhAF'
  alias la='ls -lA'
fi

# Networking
alias mip='dig +short myip.opendns.com @resolver1.opendns.com'

# Git (most-used; full set lives in ~/.gitconfig [alias])
alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline -20 --graph'

# repl: toggle the prompt between full and minimal, in place. Run `repl` to
# switch to the lean prompt (~/.config/starship-minimal.toml); run `repl` again
# to switch back to your full prompt. starship re-reads STARSHIP_CONFIG on every
# prompt, so it takes effect on the next line — no subshell, no exit needed.
repl() {
  local min="$HOME/.config/starship-minimal.toml"
  if [ "$STARSHIP_CONFIG" = "$min" ]; then
    unset STARSHIP_CONFIG
    printf 'repl: full prompt\n'
  else
    export STARSHIP_CONFIG="$min"
    printf 'repl: minimal prompt\n'
  fi
}
