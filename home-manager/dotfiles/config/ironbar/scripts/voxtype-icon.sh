#!/usr/bin/env bash
# Emit a single glyph for the current voxtype state, for ironbar's custom label.
# hyprpanel mapped the daemon's "alt" state to an icon; ironbar needs the glyph
# printed directly, so we do that mapping here.

vox() {
  if command -v voxtype >/dev/null 2>&1; then
    voxtype "$@"
  elif [ -x /run/current-system/sw/bin/voxtype ]; then
    /run/current-system/sw/bin/voxtype "$@"
  fi
}

state=$(vox status --format json --icon-theme omarchy 2>/dev/null | jq -r '.alt // "idle"' 2>/dev/null)

case "$state" in
  recording)    printf '󰻃' ;;
  transcribing) printf '󰦨' ;;
  error)        printf '󰍭' ;;
  *)            printf '󰍬' ;;  # idle / unknown / daemon not running
esac
