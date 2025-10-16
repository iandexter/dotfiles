#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract model display name
model=$(echo "$input" | jq -r '.model.display_name')

# Get current directory
cwd=$(pwd)

# Check if in a git repository and get branch (fast method)
git_info=""
branch=$(git status --porcelain=v2 --branch 2>/dev/null | grep -m1 '^# branch.head' | cut -d' ' -f3)
if [ -n "$branch" ] && [ "$branch" != "(detached)" ]; then
    git_info=" \033[1;35m $branch\033[m"
fi

# Print status line with colors:
# - Green for username
# - Red for hostname
# - Green for path
# - Purple for git branch (if present)
# - Blue for model
printf '\033[1;32m%s@\033[1;31m%s\033[1;32m:\033[0;32m%s%s \033[1;34m🤖 %s\033[m' \
    "$(whoami)" \
    "$(hostname -s)" \
    "$cwd" \
    "$git_info" \
    "$model"
