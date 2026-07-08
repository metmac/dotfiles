#!/usr/bin/env bash
# cc-tmux.sh <pane_id>
# Rendered by tmux's status-right (tmux runs it every status-interval, OUTSIDE
# the nono sandbox). Prints two things:
#   1. a GLOBAL count of Claude sessions currently awaiting approval
#   2. the FOCUSED pane's Claude status line (state glyph + model, ctx%, $, branch)
# All data comes from files under ~/.claude/panes/ written by the sandboxed
# hooks (cc-status.sh) and statusline (statusline-command.sh).

pane="$1"
dir="$HOME/.claude/panes"
now=$(date +%s)
out=""

[ -d "$dir" ] || { exit 0; }

# --- global: count sessions awaiting approval (ignore stale >5min = dead) ------
pending=0
for f in "$dir"/*.state; do
  [ -e "$f" ] || continue
  mtime=$(stat -f %m "$f" 2>/dev/null || echo 0)
  [ $(( now - mtime )) -gt 300 ] && continue
  [ "$(cat "$f" 2>/dev/null)" = "approval" ] && pending=$((pending + 1))
done
[ "$pending" -gt 0 ] && out="#[fg=#ff757f,bold]⚠ ${pending} pending#[default]  "

# --- pane-aware: this pane's state glyph + status line ------------------------
if [ -n "$pane" ]; then
  case "$(cat "$dir/${pane}.state" 2>/dev/null)" in
    working)  out="${out}#[fg=#ffc777]⟳ #[default]" ;;
    approval) out="${out}#[fg=#ff757f]⚠ #[default]" ;;
    done)     out="${out}#[fg=#c3e88d]✓ #[default]" ;;
  esac
  [ -f "$dir/${pane}.line" ] && out="${out}$(cat "$dir/${pane}.line" 2>/dev/null)"
fi

printf '%s' "$out"
