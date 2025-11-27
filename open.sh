#!/bin/bash

# this script will open a developer project in a workspace, on omarchy one project
# will be tied to one key binding (trailguide is one, skiguide is one, sjogg is one, etc)

# function to find a window on the specified workspace
find_window() {
    hyprctl clients -j | jq -r \
    --arg cls "$1" --argjson ws "$WS" '
        .[] | select(.class == $cls and .workspace.id == $ws) | .address
    ' | head -n1
}

# waits until a window is present
wait_for_window() {
    local cls="$1"
    local addr=""
    local tries=0
    while [ $tries -lt 50 ]; do
        addr=$(find_window "$cls")
        [ -n "$addr" ] && echo "$addr" && return 0
        sleep 0.1
        tries=$((tries+1))
    done
    return 1
}

# Exit if not running Hyprland
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "hyprctl not found. Are you running Hyprland?"
    exit 1
fi
if [ -z "$WAYLAND_DISPLAY" ] || ! hyprctl info >/dev/null 2>&1; then
    echo "Hyprland not detected. Exiting."
    exit 1
fi

# the project to be opened
PROJECT="${1:-trailguide}"  # default project is trailguide
WS="${2:-2}"                # default workspace is w

# do this on workspace 2
hyprctl dispatch workspace "$WS"

openProject() {
  # open the apps I want 
  cd "$HOME/projects/$PROJECT"
  ghostty &
  ghostty_addr=$(wait_for_window "com.mitchellh.ghostty")
  code "$HOME/projects/$PROJECT" &
  code_addr=$(wait_for_window "code")
  google-chrome-stable &
  chrome_addr=$(wait_for_window "google-chrome")

  # Exit if any window is missing
  [ -z "$ghostty_addr" ] && echo "Ghostty not found" && exit 1
  [ -z "$code_addr" ] && echo "Code not found" && exit 1
  [ -z "$chrome_addr" ] && echo "Chrome not found" && exit 1

  # resize them to my liking
  hyprctl dispatch focuswindow address:$ghostty_addr
  hyprctl dispatch resizeactive exact 22% 100%
  hyprctl dispatch focuswindow address:$code_addr
  hyprctl dispatch resizeactive exact 45% 100%
  hyprctl dispatch focuswindow address:$chrome_addr
  hyprctl dispatch resizeactive exact 33% 100%
  hyprctl dispatch focuswindow address:$code_addr
}

openProject