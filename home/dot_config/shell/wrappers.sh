# ~/.config/shell/wrappers.sh
# Policy-enforcing command wrappers, shared by bash & zsh:
#   claude -> always sandboxed under nono
#   pnpm   -> always containerized under podman (never touches the host directly)

# --- Claude Code, sandboxed under nono --------------------------------------
# Runs claude inside the nono capability sandbox. The nono PROFILE is chosen
# per-folder: the first time you run `claude` somewhere, an fzf picker lists the
# available nono profiles; your choice is remembered (keyed by git root, or the
# cwd if not a repo) so you're never asked again there.
#   Escape hatch:     CLAUDE_NO_SANDBOX=1 claude ...        (no sandbox)
#   One-off profile:  NONO_CLAUDE_PROFILE=go-dev claude ... (doesn't persist)
#   Extra grants:     NONO_CLAUDE_EXTRA="--allow /path" claude
#   Re-choose folder: claude-reprofile                      (clears the memory)
_claude_profile_store="$HOME/.config/claude/nono-profiles"

_claude_folder_key() { git rev-parse --show-toplevel 2>/dev/null || pwd -P; }

_claude_lookup_profile() {  # $1=key -> prints profile, nonzero if absent
  [ -f "$_claude_profile_store" ] || return 1
  awk -F'\t' -v k="$1" '$1==k{print $2; f=1} END{exit !f}' "$_claude_profile_store"
}

_claude_pick_profile() {    # fzf over `nono profile list`; prints chosen name
  command -v fzf >/dev/null 2>&1 || { printf 'claude-code\n'; return 0; }
  local key sel
  key=$(_claude_folder_key)
  sel=$(nono profile list -s 2>/dev/null \
        | sed -nE 's/^    ([a-zA-Z0-9._-]+) +(.*)/\1\t\2/p' \
        | fzf --delimiter='\t' --with-nth=1,2 --height=40% --reverse \
              --prompt="nono profile for ${key/#$HOME/~} > ") || return 1
  printf '%s\n' "${sel%%$'\t'*}"
}

claude() {
  if [ -n "$CLAUDE_NO_SANDBOX" ] || ! command -v nono >/dev/null 2>&1; then
    command claude "$@"
    return
  fi
  local key profile
  key=$(_claude_folder_key)
  if [ -n "$NONO_CLAUDE_PROFILE" ]; then
    profile="$NONO_CLAUDE_PROFILE"                    # one-off override
  elif profile=$(_claude_lookup_profile "$key"); then
    :                                                 # remembered
  else
    profile=$(_claude_pick_profile) || { echo "claude: no profile selected, aborting" >&2; return 1; }
    mkdir -p "$(dirname "$_claude_profile_store")"
    printf '%s\t%s\n' "$key" "$profile" >> "$_claude_profile_store"
    echo "claude: nono profile '$profile' set for ${key/#$HOME/~} (remembered)" >&2
  fi
  # shellcheck disable=SC2086
  command nono run \
    --profile "$profile" \
    --allow "$PWD" \
    ${NONO_CLAUDE_EXTRA:-} \
    -- claude "$@"
}

# Forget the remembered nono profile for the current folder (re-asks next time).
claude-reprofile() {
  local key tmp; key=$(_claude_folder_key)
  [ -f "$_claude_profile_store" ] || { echo "no profiles stored yet"; return 0; }
  tmp=$(mktemp) && awk -F'\t' -v k="$key" '$1!=k' "$_claude_profile_store" > "$tmp" \
    && mv "$tmp" "$_claude_profile_store" \
    && echo "claude: cleared profile for ${key/#$HOME/~}; next 'claude' will ask again"
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
