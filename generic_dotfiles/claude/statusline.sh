#!/bin/bash
# Reads JSON from stdin (provided by Claude Code harness) and echoes
# a single-line colored statusline.
input=$(cat)

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')

# Leaf-only path (with $HOME -> ~ special case) to match zsh %1~
if [ "$CURRENT_DIR" = "$HOME" ]; then
    DISPLAY_DIR="~"
else
    DISPLAY_DIR=$(basename "$CURRENT_DIR")
fi

# Model name abbreviation
case "$MODEL_DISPLAY" in
    *Opus*1M*)    MODEL_ABBREV="Opus1M" ;;
    *Opus*)       MODEL_ABBREV="Opus" ;;
    *Sonnet*1M*)  MODEL_ABBREV="Sonnet1M" ;;
    *Sonnet*)     MODEL_ABBREV="Sonnet" ;;
    *Haiku*)      MODEL_ABBREV="Haiku" ;;
    *)            MODEL_ABBREV="$MODEL_DISPLAY" ;;
esac

# Colors (match zsh jayers theme)
BOLD_YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
DARK_GREY='\033[90m'
BOLD_ORANGE='\033[1;38;5;208m'
RESET='\033[0m'

HOST=$(hostname -s)

# SSH detection: orange hostname when remote, bold yellow when local
if [ -n "$SSH_CONNECTION" ]; then
  HOST_COLOR="$BOLD_ORANGE"
else
  HOST_COLOR="$BOLD_YELLOW"
fi

# Build the git segment (or empty if not in a git repo)
git_segment() {
    local dir="$1"
    local git_dir
    git_dir=$(git -C "$dir" rev-parse --git-dir 2>/dev/null) || return
    case "$git_dir" in
        /*) ;;
        *) git_dir="$dir/$git_dir" ;;
    esac

    local status_output
    status_output=$(git -C "$dir" status --porcelain=v2 --branch --untracked-files=normal 2>/dev/null) || return

    local branch="" ahead=0 behind=0 detached=""
    local has_staged=0 has_unstaged=0 has_untracked=0
    local line
    while IFS= read -r line; do
        case "$line" in
            "# branch.head "*)
                branch="${line#\# branch.head }"
                [ "$branch" = "(detached)" ] && detached=1
                ;;
            "# branch.ab "*)
                local ab="${line#\# branch.ab }"
                ahead="${ab#+}"
                ahead="${ahead%% *}"
                behind="${ab##*-}"
                ;;
            "1 "*|"2 "*)
                local xy="${line:2:2}"
                [ "${xy:0:1}" != "." ] && has_staged=1
                [ "${xy:1:1}" != "." ] && has_unstaged=1
                ;;
            "u "*)
                has_unstaged=1
                ;;
            "? "*)
                has_untracked=1
                ;;
        esac
    done <<< "$status_output"

    if [ -n "$detached" ]; then
        local sha
        sha=$(git -C "$dir" rev-parse --short=7 HEAD 2>/dev/null)
        branch="HEAD@${sha}"
    elif [ "${#branch}" -gt 25 ]; then
        branch="${branch:0:24}…"
    fi

    local state=""
    if [ -d "$git_dir/rebase-merge" ]; then
        local msgnum end
        msgnum=$(cat "$git_dir/rebase-merge/msgnum" 2>/dev/null)
        end=$(cat "$git_dir/rebase-merge/end" 2>/dev/null)
        if [ -n "$msgnum" ] && [ -n "$end" ]; then
            state="|REBASE ${msgnum}/${end}"
        else
            state="|REBASE"
        fi
    elif [ -d "$git_dir/rebase-apply" ]; then
        local next last
        next=$(cat "$git_dir/rebase-apply/next" 2>/dev/null)
        last=$(cat "$git_dir/rebase-apply/last" 2>/dev/null)
        if [ -n "$next" ] && [ -n "$last" ]; then
            state="|REBASE ${next}/${last}"
        else
            state="|REBASE"
        fi
    elif [ -f "$git_dir/MERGE_HEAD" ]; then
        state="|MERGING"
    elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
        state="|CHERRY-PICK"
    elif [ -f "$git_dir/REVERT_HEAD" ]; then
        state="|REVERTING"
    elif [ -f "$git_dir/BISECT_LOG" ]; then
        state="|BISECTING"
    fi

    local stash_count
    stash_count=$(git -C "$dir" rev-list --walk-reflogs --count refs/stash 2>/dev/null)
    stash_count=${stash_count:-0}

    local out=" ${BLUE}("
    if [ -n "$detached" ]; then
        out+="${YELLOW}${branch}${BLUE}"
    else
        out+="${GREEN}${branch}${BLUE}"
    fi
    [ -n "$state" ] && out+="${RED}${state}${BLUE}"
    if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
        out+="${YELLOW}↑${ahead}↓${behind}${BLUE}"
    elif [ "$ahead" -gt 0 ]; then
        out+="${GREEN}↑${ahead}${BLUE}"
    elif [ "$behind" -gt 0 ]; then
        out+="${YELLOW}↓${behind}${BLUE}"
    fi
    out+=")${RESET}"
    [ $has_staged -eq 1 ] && out+="${GREEN}+${RESET}"
    [ $has_unstaged -eq 1 ] && out+="${RED}*${RESET}"
    [ $has_untracked -eq 1 ] && out+="${YELLOW}?${RESET}"
    [ "$stash_count" -gt 0 ] && out+="${MAGENTA}⚑${stash_count}${RESET}"

    printf '%s' "$out"
}
GIT_PART=$(git_segment "$CURRENT_DIR")

# Claude info (light grey, compact) — show tokens used in thousands
TOKENS_USED=$(echo "$input" | jq -r '
  .context_window.current_usage //empty |
  ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))
')
TOKENS_USED=${TOKENS_USED:-0}
TOKENS_K=$(( TOKENS_USED / 1000 ))
CLAUDE_PART="${DARK_GREY}[${MODEL_ABBREV}:${TOKENS_K}k]${RESET}"

echo -e "${CLAUDE_PART} ${HOST_COLOR}${HOST}${RESET}:${CYAN}${DISPLAY_DIR}${RESET}${GIT_PART}"
