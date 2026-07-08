# dotfiles

Personal dotfiles for macOS (and Linux-friendly), managed with
[chezmoi](https://chezmoi.io). Bash is the primary shell; zsh works as a
first-class alternative.

## Layout

chezmoi's source tree lives under [`home/`](home/) (see `.chezmoiroot`). Names
follow chezmoi conventions: `dot_bashrc` → `~/.bashrc`, `dot_config/...` →
`~/.config/...`, and `*.tmpl` files are Go-templated (used for the macOS vs
Linux Homebrew prefix).

```
home/
  dot_bash_profile.tmpl     # bash login: brew env -> shared env -> rc
  dot_bashrc.tmpl           # bash interactive
  dot_zprofile.tmpl         # zsh login
  dot_zshrc                 # zsh interactive (parity with bash)
  dot_gitconfig
  dot_gitignore_global
  dot_vimrc
  dot_tmux.conf             # legacy; superseded by zellij
  dot_config/
    shell/
      env.sh                # POSIX env shared by bash & zsh (PATH, exports)
      aliases.sh            # shared aliases + `repl`
      functions.sh          # personal utility functions
      init.sh               # prompt + mise + completions (shell-detecting)
    starship.toml           # functional, low-noise prompt
    starship-minimal.toml   # lean prompt used by `repl`
```

Both shells source the same `~/.config/shell/*` files, so aliases/env/functions
stay in one place.

## Shell highlights

- **`repl`** — drops into a minimal-prompt subshell (lean `starship-minimal`).
  `exit` / Ctrl-D returns to the full prompt.
- **`reload`** — re-exec the login shell after config changes.

## Toolchain conventions (go-forward)

- **Homebrew** installs the package managers themselves (mise, pixi, chezmoi, …).
- **mise** owns the Go and Node toolchains (replaces the old nvm/brew-go/GVM tangle).
- **pixi** owns Python (replaces pyenv/conda).
- **pnpm** is the default frontend package manager, run **containerized** via Podman.
- **nono** sandboxes Claude Code (`claude` always launches under nono).
- **zellij** is the terminal multiplexer (ported from the old tmux config).

## Install

```sh
brew install chezmoi
chezmoi init --apply <this-repo>
```

To preview changes before applying: `chezmoi diff`.
