#!/usr/bin/env bash

profile_icon() {
  case "$(powerprofilesctl get 2>/dev/null)" in
    performance) printf '󰓅' ;;
    balanced) printf '󰾅' ;;
    power-saver) printf '󰌪' ;;
  esac
}

if [[ ${1:-} == "--watch" ]]; then
  previous=""

  while true; do
    icon=$(profile_icon)

    if [[ $icon != "$previous" ]]; then
      printf '%s\n' "$icon"
      previous=$icon
    fi

    sleep 5
  done
else
  profile_icon
fi
