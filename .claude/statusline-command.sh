#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract version and model
version=$(echo "$input" | jq -r '.version')
model=$(echo "$input" | jq -r '.model.display_name')

# Get current directory
cwd=$(pwd)

# Replace HOME with ~
cwd="${cwd/#$HOME/~}"

# Check if in a git repository and get branch
git_info=""
branch=$(git status --porcelain=v2 --branch 2>/dev/null | grep -m1 '^# branch.head' | cut -d' ' -f3)
if [ -n "$branch" ] && [ "$branch" != "(detached)" ]; then
    # Get git diff stats (lines added/removed/files changed)
    diff_stats=$(git diff --numstat 2>/dev/null | awk '{added+=$1; removed+=$2; files++} END {print added, removed, files}')
    added=$(echo "$diff_stats" | awk '{print $1}')
    removed=$(echo "$diff_stats" | awk '{print $2}')
    files=$(echo "$diff_stats" | awk '{print $3}')

    # Default to 0 if empty
    added=${added:-0}
    removed=${removed:-0}
    files=${files:-0}

    # Build git info with colors, only showing non-zero values
    git_info=" 🔀 $branch"
    [ "$added" != "0" ] && git_info="$git_info | $(printf '\033[32m+%s\033[0m' "$added")"
    [ "$removed" != "0" ] && git_info="$git_info | $(printf '\033[31m-%s\033[0m' "$removed")"
    [ "$files" != "0" ] && git_info="$git_info | $(printf '\033[33m~%s\033[0m' "$files")"
fi

# Print status line with colors and icons
printf '\033[1;34m[%s]\033[0m 🤖 \033[1;36m%s\033[0m 📁 \033[0;32m%s\033[0m%s' \
    "$version" \
    "$model" \
    "$cwd" \
    "$git_info"
