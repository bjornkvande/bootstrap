#!/bin/bash

# this script will open a developer project in a workspace, on omarchy one project
# will be tied to one key binding (trailguide is one, skiguide is one, sjogg is one, etc)

# Exit if not running Hyprland
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "hyprctl not found. Are you running Hyprland?"
    exit 1
fi
if [ -z "$WAYLAND_DISPLAY" ] || ! hyprctl info >/dev/null 2>&1; then
    echo "Hyprland not detected. Exiting."
    exit 1
fi

# do this on workspace 2
WS=2
hyprctl dispatch workspace "$WS"

# open the apps I want 
ghostty &
sleep 0.5
code ~/projects/trailguide &
sleep 1.5
google-chrome-stable &
sleep 0.5

# function to find a window on the specified workspace
find_window() {
    hyprctl clients -j | jq -r \
    --arg cls "$1" --argjson ws "$WS" '
        .[] | select(.class == $cls and .workspace.id == $ws) | .address
    ' | head -n1
}

ghostty_addr=$(find_window "com.mitchellh.ghostty")
code_addr=$(find_window "code")
chrome_addr=$(find_window "google-chrome")

# Exit if any window is missing
[ -z "$ghostty_addr" ] && echo "Ghostty not found" && exit 1
[ -z "$code_addr" ] && echo "Code not found" && exit 1
[ -z "$chrome_addr" ] && echo "Chrome not found" && exit 1

# resize them to my liking
hyprctl dispatch focuswindow address:$ghostty_addr
hyprctl dispatch resizeactive exact 22% 100%

# focus the editor
hyprctl dispatch focuswindow address:$code_addr
hyprctl dispatch resizeactive exact 45% 100%
