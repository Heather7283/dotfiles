#!/usr/bin/env bash

offset_top=26
offset_left=0
cell_width=9
cell_height=21

hook_name="$1"
target_tmux_pane_id="$2"
source_hyprland_window_address="$3"
target_hyprland_window_address="$4"

resize_hook() {
  read pane_left pane_top pane_width pane_height < <(tmux display-message -t "$target_tmux_pane_id" -p "#{pane_left} #{pane_top} #{pane_width} #{pane_height}")

  window_left="$(( pane_left * cell_width + offset_left ))"
  window_top="$(( pane_top * cell_height + offset_top ))"
  window_width="$(( pane_width * cell_width ))"
  window_height="$(( pane_height * cell_height ))"

  hyprctl dispatch movewindowpixel exact $window_left $window_top,address:$source_hyprland_window_address
  hyprctl dispatch resizewindowpixel exact $window_width $window_height,address:$source_hyprland_window_address
}

is_pane_visible() {
  pane_id="$1"
  tmux list-windows -f '#{window_active}' -F '#{window_visible_layout}' | grep -qPe "(\d+x\d+),(\d+),(\d+),$pane_id"
}

get_visible_pane_ids() {
  for var in $(tmux list-windows -f '#{window_active}' -F '#{window_visible_layout}' | grep -Poe '(\d+x\d+),(\d+),(\d+),(\d+)'); do echo "${var##*,}"; done
}

hide_hook() {
  if is_pane_visible "${target_tmux_pane_id#%}"; then
    hyprctl dispatch movetoworkspacesilent 1,address:"$source_hyprland_window_address"
  else
    hyprctl dispatch movetoworkspacesilent special:"${source_hyprland_window_address}_ws",address:"$source_hyprland_window_address"
  fi
}

resize_hooks=("initial" "window-layout-changed")
hide_hooks=("initial" "after-new-window" "after-select-window" "window-layout-changed")
if [[ " ${resize_hooks[@]} " =~ " ${hook_name} " ]]; then
  resize_hook
fi
if [[ " ${hide_hooks[@]} " =~ " ${hook_name} " ]]; then
  hide_hook
fi

