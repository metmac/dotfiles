#!/usr/bin/env bash
# cc-status.sh <state>
# Records a Claude Code session's state, keyed by its tmux pane, for the tmux
# status bar (read by cc-tmux.sh). Lives in ~/.claude so it runs from inside the
# nono sandbox (the claude-code profile grants ~/.claude). Also does best-effort
# zellij tab rename + a desktop notification whose click focuses the terminal.
#
# Hooks: UserPromptSubmit -> working   Notification -> approval   Stop -> done

state="${1:-idle}"
base=$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")
pane="${TMUX_PANE:-nopane}"
dir="$HOME/.claude/panes"
mkdir -p "$dir" 2>/dev/null || true

# 1) per-pane state file — tmux status bar reads this
case "$state" in
  working|approval|done) printf '%s' "$state" > "$dir/${pane}.state" 2>/dev/null || true ;;
  *)                     : > "$dir/${pane}.state" 2>/dev/null || true ;;
esac

# 2) zellij: rename the focused tab (best effort)
if [ -n "$ZELLIJ" ] && command -v zellij >/dev/null 2>&1; then
  case "$state" in working) g="⟳" ;; approval) g="⚠" ;; done) g="✓" ;; *) g="●" ;; esac
  zellij action rename-tab "${g} ${base}" >/dev/null 2>&1 || true
fi

# 3) nudge tmux to redraw so the change shows promptly (best effort)
if [ -n "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
  tmux refresh-client -S >/dev/null 2>&1 || true
fi

# 4) desktop notification for approval; clicking focuses the terminal (ghostty).
#    Override the target app with CC_TERM_BUNDLE if you use a different terminal.
#    Run fully backgrounded + time-boxed so a slow/blocking notifier can NEVER
#    hang the hook (which would freeze Claude on every approval).
if [ "$state" = "approval" ]; then
  bundle="${CC_TERM_BUNDLE:-com.mitchellh.ghostty}"
  {
    if command -v terminal-notifier >/dev/null 2>&1; then
      terminal-notifier -title "Claude — $base" -message "needs your approval" \
        -sender "$bundle" -activate "$bundle" -sound default >/dev/null 2>&1
    elif [ "$(uname)" = "Darwin" ]; then
      osascript -e "display notification \"needs your approval\" with title \"Claude — $base\"" >/dev/null 2>&1
    fi
  } >/dev/null 2>&1 &
  disown 2>/dev/null || true
fi

exit 0
