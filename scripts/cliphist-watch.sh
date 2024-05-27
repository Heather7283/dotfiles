#!/usr/bin/env bash

set -o pipefail

# silence all output
exec 1>/dev/null

full_item="$(cliphist list | head -n1)"
item="$(echo "$full_item" | cut -d$'\t' -f2)"

# don't save 1 character long items
if [ "${#item}" -le 1 ]; then
  echo "$full_item" | cliphist delete
# convert bmp to png and delete original bmp
elif [[ "$item" =~ ^\[\[\ binary\ data\ [1-9][0-9]*\ .iB\ bmp ]]; then
  if echo "$full_item" | cliphist decode | convert BMP:- PNG:- | wl-copy; then
    echo "$full_item" | cliphist delete
  fi
# download images that copy as funny html tag thingies, delete original
elif [[ "$item" =~ \<img ]]; then
  string="$(echo "$full_item" | cliphist decode | grep -P '^<.*src="[^"]*".*>$')"
  if [ -n "$string" ]; then
    url="$(echo "$string" | grep -oP 'src="\K[^"]*')"
    if curl -L --no-progress-meter --fail "$url" | cliphist store; then
      echo "$full_item" | cliphist delete
    fi
  fi
fi

