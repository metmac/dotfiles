#!/usr/bin/env bash
# Claude Code status line — inspired by Starship config

input=$(cat)

dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

model=$(echo "$input" | jq -r '.model.display_name // ""')

# Git repo name and branch — skip optional locks
repo_label=""
if toplevel=$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" rev-parse --show-toplevel 2>/dev/null); then
  repo_name=$(basename "$toplevel")
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || GIT_OPTIONAL_LOCKS=0 git -C "$dir" rev-parse --short HEAD 2>/dev/null)
  repo_label="${repo_name} → ${branch}"
else
  repo_label=$(basename "$dir")
fi

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
quota_five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
quota_week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# ANSI colors — dark grays, each section distinct
RESET='\033[0m'
BG_REPO='\033[48;2;50;50;50m'    # medium-dark gray
FG_REPO='\033[38;2;200;200;200m' # light gray text
BG_MODEL='\033[48;2;38;38;38m'   # darker gray
FG_MODEL='\033[38;2;170;170;170m'
BG_CTX='\033[48;2;28;28;28m'     # even darker gray
FG_CTX='\033[38;2;150;150;150m'
BG_QUOTA='\033[48;2;20;20;20m'   # darkest gray
FG_QUOTA='\033[38;2;140;140;140m'

out=""

# Repo/directory segment — no leading space
out="$(printf "${BG_REPO}${FG_REPO}%s " "$repo_label")${RESET}"

# Model segment
if [ -n "$model" ]; then
  out="${out}$(printf "${BG_MODEL}${FG_MODEL} %s " "$model")${RESET}"
fi

# Context usage segment
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  out="${out}$(printf "${BG_CTX}${FG_CTX} ctx:%s%% " "$used_int")${RESET}"
fi

# Claude quota usage segment
quota_str=""
if [ -n "$quota_five" ]; then
  quota_str="5h:$(printf '%.0f' "$quota_five")%"
fi
if [ -n "$quota_week" ]; then
  [ -n "$quota_str" ] && quota_str="$quota_str "
  quota_str="${quota_str}7d:$(printf '%.0f' "$quota_week")%"
fi
if [ -n "$quota_str" ]; then
  out="${out}$(printf "${BG_QUOTA}${FG_QUOTA} quota:%s " "$quota_str")${RESET}"
fi

# --- also emit a per-pane line for the tmux status bar (cc-tmux.sh reads it) ---
# tmux color codes, keyed by the tmux pane so the bar can show the focused pane.
if [ -n "$TMUX_PANE" ]; then
  panedir="$HOME/.claude/panes"
  mkdir -p "$panedir" 2>/dev/null || true
  {
    [ -n "$model" ]      && printf '#[fg=#769ff0]%s' "$model"
    [ -n "$used" ]       && printf '#[fg=#6c7086] · #[fg=#a0a9cb]ctx %s%%' "$(printf '%.0f' "$used")"
    [ -n "$cost" ]       && printf '#[fg=#6c7086] · #[fg=#c3e88d]$%.2f' "$cost"
    [ -n "$repo_label" ] && printf '#[fg=#6c7086] · #[fg=#ffc777]%s' "$repo_label"
    printf '#[default]'
  } > "$panedir/${TMUX_PANE}.line" 2>/dev/null || true
fi

printf "%b" "$out"
