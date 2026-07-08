# ~/.config/shell/functions.sh
# Personal utility functions, carried over from the old ~/.bash_functions and
# made portable across bash & zsh.

# Batch-resize every image of a type to a pixel width: imgdir png 800
imgdir() {
  if [ -z "$*" ]; then echo "usage: imgdir <ext> <width>"; return 1; fi
  if [ $# -eq 2 ]; then
    for x in *"$1"; do sips -Z "$2" "$x"; mv "$x" "${x%%.*}_${2}x.${x#*.}"; done
  fi
}

# Resize a single image: imgresize photo.jpg 800
imgresize() { sips -Z "$2" "$1"; mv "$1" "${1%%.*}_${2}x.${1#*.}"; }

# CSV helpers
csvCount() { [ $# -eq 1 ] && head -1 "$1" | sed 's/[^,]//g' | wc -c; }
csvls()    { [ $# -eq 1 ] && head -1 "$1"; }
csvquotes(){ sed 's/\"//g'; }

# Serve the macOS pasteboard over netcat: pbserv 9999
pbserv() {
  if [ $# -ne 1 ]; then echo "usage: pbserv <port>"; return 1; fi
  export pbport="$1"
  echo "Serving pbcopy on $pbport, ^C to end"
  while true; do nc -l "$pbport" | pbcopy; done
}

# Decrypt an EC2 Windows admin password to the clipboard
awsWinAuth() {
  if [ $# -ne 2 ]; then echo 'usage: awsWinAuth <instance-id> <ssh-key-path>'; return 1; fi
  aws ec2 get-password-data "--instance-id=$1" \
    | jq -r .PasswordData | base64 -D \
    | openssl rsautl -decrypt -inkey "$2" | pbcopy
}

# Tail a scratch log written to $TMPDIR/q (q-style debug logging)
qq() {
  clear
  logpath="${TMPDIR:-/tmp}/q"
  [ -f "$logpath" ] || echo 'Q LOG' > "$logpath"
  tail -100f -- "$logpath"
}
rmqq() {
  logpath="${TMPDIR:-/tmp}/q"
  [ -f "$logpath" ] && rm "$logpath"
  qq
}

# Strip ANSI color codes from stdin
ansi_strip() { gsed 's/\x1b\[[0-9;]*m//g'; }

# Show a user's AWS_* groups
aws_groups() { id "$1" | tr , '\n' | grep --color 'AWS_'; }

# Expand a CIDR to its host IPs (-l reads CIDRs from the clipboard)
cidr_range() {
  if [ $# -ne 1 ]; then echo "usage: cidr_range <cidr|-l>"; return 1; fi
  if [ "$1" = "-l" ]; then
    pbpaste | xargs -I {} nmap -sL {} | awk '{gsub(/[()]/,"")} /Nmap scan report/{print $NF}'
    return
  fi
  nmap -sL "$1" | awk '{gsub(/[()]/,"")} /Nmap scan report/{print $NF}'
}

# Prompt for a secret without echo and export it: setSecret MY_TOKEN
setSecret() {
  if [ $# -ne 1 ]; then echo "usage: setSecret <VAR_NAME>"; return 1; fi
  printf 'secret: '; read -rs "$1"; echo
  export "$1=${!1}"
}

# Count files by extension in a folder (defaults to .)
folderStats() {
  find "${1:-.}" -type f -maxdepth 1 | sed 's/.*\.//' | sort | uniq -c | sort -rn
}

# `gi t status` -> `git status` (fix the classic typo)
gi() { local a=("$@"); a[0]="${a[0]/t/}"; git "${a[@]}"; }

# export -f is bash-only; guard so zsh doesn't choke
if [ -n "$BASH_VERSION" ]; then
  export -f cidr_range folderStats 2>/dev/null || true
fi
