# Animated, theme-matched fastfetch on new interactive shells (skip nested
# shells so it doesn't re-fire inside tmux panes, `bash` subshells, etc.)
if [[ $- == *i* ]] && [ -z "${FASTFETCH_SHOWN:-}" ]; then
    export FASTFETCH_SHOWN=1
    ~/.config/fastfetch/run.sh
fi
