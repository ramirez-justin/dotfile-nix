#!/bin/bash

# Claude Code statusline script
# Reads JSON input from stdin and displays formatted statusline with development info

input=$(cat)

# Extract info from JSON
user=$(whoami)
current_dir=$(echo "$input" | jq -r '.workspace.current_dir' | sed "s|$HOME|~|")
model=$(echo "$input" | jq -r '.model.display_name')
session_id=$(echo "$input" | jq -r '.session.id' | cut -c1-8)
cost=$(echo "$input" | jq -r '.session.cost_estimate // 0')

# Get git info if in a git repo
git_info=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
      git_info="🔄 $branch*"
    else
      git_info="🌿 $branch"
    fi
  fi
fi

# Build status line with sections separated by |
sections=()

# User section
sections+=("👤 $user")

# Directory section
sections+=("📁 $current_dir")

# Git section (if available)
if [ -n "$git_info" ]; then
  sections+=("$git_info")
fi

# Model section
sections+=("🤖 $model")

# Session info
sections+=("🎯 $session_id")

# Cost info (if available and > 0)
if [ "$cost" != "0" ] && [ "$cost" != "null" ]; then
  sections+=("💰 \$$(printf '%.4f' "$cost")")
fi

# Join sections with | and format
result=$(IFS=' | '; echo "${sections[*]}")
printf "\033[2m%s\033[0m" "$result"