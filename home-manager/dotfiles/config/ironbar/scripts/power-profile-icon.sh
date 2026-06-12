#!/usr/bin/env bash
# Glyph for the current power-profiles-daemon profile (ironbar bar label).
case "$(powerprofilesctl get 2>/dev/null)" in
  performance) printf '󰓅' ;;
  balanced)    printf '󰾅' ;;
  power-saver) printf '󰌪' ;;
  *)           printf '' ;;  # daemon unavailable → hide
esac
