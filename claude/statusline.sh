#!/bin/bash
input=$(cat)

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PROJECT_NAME=$(basename "$CURRENT_DIR")

# Abbreviate path: physical iCloud -> ~/icloud, then $HOME -> ~
DISPLAY_DIR="$CURRENT_DIR"
DISPLAY_DIR="${DISPLAY_DIR/#$HOME\/Library\/Mobile Documents\/com~apple~CloudDocs/$HOME/icloud}"
DISPLAY_DIR="${DISPLAY_DIR/#$HOME/~}"

# Colors (match zsh jayers theme)
BOLD_YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
DARK_GREY='\033[90m'
RESET='\033[0m'

USER=$(whoami)
HOST=$(hostname -s)

# Git info
GIT_PART=""
if git -C "$CURRENT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$CURRENT_DIR" branch --show-current 2>/dev/null)
    DIRTY=""
    if ! git -C "$CURRENT_DIR" diff-index --quiet HEAD -- 2>/dev/null; then
        DIRTY="${RED}*${RESET}"
    fi
    GIT_PART=" ${BLUE}git:(${GREEN}$BRANCH${BLUE})${RESET}$DIRTY"
fi

# Claude info (light grey, at the end) — show tokens used in thousands
TOKENS_USED=$(echo "$input" | jq -r '
  .context_window.current_usage //empty |
  ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))
')
TOKENS_USED=${TOKENS_USED:-0}
TOKENS_K=$(( TOKENS_USED / 1000 ))
CLAUDE_PART="${DARK_GREY}[${MODEL_DISPLAY} : ${TOKENS_K}k]${RESET}"

echo -e "${CLAUDE_PART} ${BOLD_YELLOW}${USER}@${HOST}${RESET}:${CYAN}${DISPLAY_DIR}${RESET}${GIT_PART}"
