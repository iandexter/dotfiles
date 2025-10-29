#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract version and model
version=$(echo "$input" | jq -r '.version')
model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.current_dir // empty')
if [ -z "$cwd" ]; then
  cwd=$(pwd)
fi

# Replace $HOME with ~
cwd="${cwd/#$HOME/~}"

git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  # Get branch (skip optional locks for performance)
  branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

  # Get git diff stats (lines added/removed)
  diff_stats=$(git -C "$cwd" --no-optional-locks diff --numstat 2>/dev/null | awk '{added+=$1; removed+=$2; files++} END {print added, removed, files}')
  added=$(echo "$diff_stats" | awk '{print $1}')
  removed=$(echo "$diff_stats" | awk '{print $2}')
  files=$(echo "$diff_stats" | awk '{print $3}')

  # Default to 0 if empty
  added=${added:-0}
  removed=${removed:-0}
  files=${files:-0}

  git_info=$(printf ' \033[1;35m🔀 %s\033[m | \033[01;32m+%s\033[00m | \033[01;31m-%s\033[00m | F: \033[01;33m%s\033[00m' \
    "$branch" "$added" "$removed" "$files")
fi

printf '\033[1;34m[%s] 🤖 %s \033[m \033[0;32m📁 %s\033[m%s' \
    "$version" \
    "$model" \
    "$cwd" \
    "$git_info"
