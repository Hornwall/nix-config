#!/usr/bin/env bash
# Print the recording glyph only while wf-recorder is running; nothing otherwise
# (the .recording widget collapses to invisible when its label is empty).
if pgrep -x wf-recorder >/dev/null 2>&1; then
  printf '󰻃'
fi
