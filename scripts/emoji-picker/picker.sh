#!/bin/sh

selected="$(fzf <~/.config/scripts/emoji-picker/emoji-list.txt \
    -d "$(printf '\t')" \
    --nth=2 \
    --bind 'ctrl-y:execute-silent(printf '%s' {1} | wl-copy -t text/plain\;charset=utf-8)')"
[ -z "$selected" ] && exit

set -- $selected
emoji="$1"
description="$2"

printf '%s' "$emoji" | wl-copy -t "text/plain;charset=utf-8"
