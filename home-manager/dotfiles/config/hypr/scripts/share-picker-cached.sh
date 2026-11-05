#!/usr/bin/env bash
# xdph custom picker. Electron apps (Slack) open the ScreenCast portal several
# times for a single share; reuse the first selection for a few seconds so the
# picker is only shown once.

cache="${XDG_RUNTIME_DIR:-/tmp}/xdph-picker-selection"
window=15

if [[ -f "$cache" ]] && (( $(date +%s) - $(stat -c %Y "$cache") < window )); then
  cat "$cache"
  exit 0
fi

out=$(hyprland-share-picker "$@")
status=$?
printf '%s\n' "$out"

# Only cache a real choice; the restore-token flag (r) is dropped since
# restoring tokens left Slack with a black stream.
selection=$(grep -m1 '^\[SELECTION\]' <<<"$out" | sed -E 's/^\[SELECTION\]([^/]*)r([^/]*)\//[SELECTION]\1\2\//')
if (( status == 0 )) && [[ -n "$selection" ]]; then
  printf '%s\n' "$selection" > "$cache"
else
  rm -f "$cache"
fi
exit $status
