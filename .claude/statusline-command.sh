#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract version and model
version=$(echo "$input" | jq -r '.version')
model=$(echo "$input" | jq -r '.model.display_name')

cwd=$(pwd)

git_info=""
branch=$(git status --porcelain=v2 --branch 2>/dev/null | grep -m1 '^# branch.head' | cut -d' ' -f3)
if [ -n "$branch" ] && [ "$branch" != "(detached)" ]; then
    git_info=" \033[1;35m🔀 $branch\033[m"
fi

printf '\033[1;34m[%s] 🤖 %s \033[m \033[0;32m📁 %s\033[m%s' \
    "$version" \
    "$model" \
    "$cwd" \
    "$git_info"
