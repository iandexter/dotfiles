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
    # Use yellow for dirty branch, magenta for clean
    if [ "$added" != "0" ] || [ "$removed" != "0" ] || [ "$files" != "0" ]; then
        git_info=$(printf ' 🔀 \033[1;33m%s\033[0m' "$branch")
    else
        git_info=$(printf ' 🔀 \033[1;35m%s\033[0m' "$branch")
    fi
    [ "$added" != "0" ] && git_info="$git_info | $(printf '\033[32m+%s\033[0m' "$added")"
    [ "$removed" != "0" ] && git_info="$git_info | $(printf '\033[31m-%s\033[0m' "$removed")"
    [ "$files" != "0" ] && git_info="$git_info | $(printf '\033[33m~%s\033[0m' "$files")"
fi

# Extract cost data from JSON
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
api_duration_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // 0')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Format durations (ms to seconds with 1 decimal)
duration_s=$(awk "BEGIN {printf \"%.1f\", $duration_ms/1000}")
api_duration_s=$(awk "BEGIN {printf \"%.1f\", $api_duration_ms/1000}")

# Build cost info section
cost_info=""
if [ "$cost_usd" != "0" ] || [ "$duration_ms" != "0" ]; then
    cost_info=$(printf ' 💰 \033[1;33m$%.4f\033[0m ⏱️  \033[1;36m%ss\033[0m \033[0;37m(API: %ss)\033[0m 📝 \033[32m+%s\033[0m/\033[31m-%s\033[0m' \
        "$cost_usd" \
        "$duration_s" \
        "$api_duration_s" \
        "$lines_added" \
        "$lines_removed")
fi

# Print status line with colors and icons
printf '\033[1;34m[%s]\033[0m 🤖 \033[1;36m%s\033[0m 📁 \033[0;32m%s\033[0m%s%s' \
    "$version" \
    "$model" \
    "$cwd" \
    "$git_info" \
    "$cost_info"
