# Show the current directory (and git branch, if any) in the kitty
# window/tab title via a standard xterm OSC 0 title escape.
_git_title() {
    local dir branch title
    dir=$(basename "$PWD")
    branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        title="$dir [$branch]"
    else
        title="$dir"
    fi
    printf '\033]0;%s\007' "$title"
}
PROMPT_COMMAND="_git_title${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
