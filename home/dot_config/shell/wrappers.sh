# ~/.config/shell/wrappers.sh
# Policy-enforcing command wrappers, shared by bash & zsh:
#   claude -> always sandboxed under nono
#   pnpm   -> always containerized under podman (never touches the host directly)

# --- Claude Code, sandboxed under nono --------------------------------------
# Runs claude inside the nono capability sandbox using nono's official
# `claude-code` profile (grants ~/.claude, ~/.claude.json, Keychains for auth,
# the tmp state dir, etc.), plus read+write on the current project. Network is
# allowed by default (claude needs the API).
#   Escape hatch:  CLAUDE_NO_SANDBOX=1 claude ...
#   Extra grants:  NONO_CLAUDE_EXTRA="--allow /path --allow-domain x" claude
# Requires the pack once:  nono pull always-further/claude
claude() {
  if [ -n "$CLAUDE_NO_SANDBOX" ] || ! command -v nono >/dev/null 2>&1; then
    command claude "$@"
    return
  fi
  # shellcheck disable=SC2086
  command nono run \
    --profile claude-code \
    --allow "$PWD" \
    ${NONO_CLAUDE_EXTRA:-} \
    -- claude "$@"
}

# --- pnpm, containerized under podman ---------------------------------------
# Always runs in a throwaway container. Mounts ONLY the current project dir, and
# FAILS CLOSED if you're at (or above) $HOME. Common dev-server ports are
# published on loopback only; override with PNPM_PORTS="3000 9000".
pnpm() {
  local img="localhost/pnpm-sandbox:latest"
  local cwd
  cwd="$(pwd -P)"

  # Fail closed: never mount $HOME itself, /, or anything outside the home tree.
  if [ "$cwd" = "$HOME" ] || [ "$cwd" = "/" ]; then
    printf 'pnpm(sandbox): refusing to mount %s — cd into a project subdir.\n' "$cwd" >&2
    return 1
  fi
  case "$cwd/" in
    "$HOME"/*) : ;;  # inside home tree: allowed
    *) printf 'pnpm(sandbox): cwd %s is outside your home tree; refusing.\n' "$cwd" >&2; return 1 ;;
  esac

  command -v podman >/dev/null 2>&1 || { printf 'pnpm(sandbox): podman not found.\n' >&2; return 1; }

  # Build the minimal pnpm image on first use.
  if ! podman image exists "$img" 2>/dev/null; then
    printf 'pnpm(sandbox): building %s (first run only)...\n' "$img" >&2
    podman build -t "$img" "$HOME/.config/pnpm-container" >&2 || return 1
  fi

  # Publish common dev-server ports on 127.0.0.1 only (limits Mac surface area).
  local ports="${PNPM_PORTS:-3000 5173 4321 8080}"
  local p
  local pub
  pub=()
  if [ -n "$ZSH_VERSION" ]; then
    for p in ${=ports}; do pub+=(-p "127.0.0.1:${p}:${p}"); done
  else
    for p in $ports; do pub+=(-p "127.0.0.1:${p}:${p}"); done
  fi

  local tflag=""
  [ -t 0 ] && tflag="-t"

  # shellcheck disable=SC2086
  podman run --rm -i $tflag \
    --security-opt no-new-privileges \
    -v "$cwd:/work" -w /work \
    -v pnpm-sandbox-store:/root/.local/share/pnpm \
    "${pub[@]}" \
    "$img" "$@"
}
