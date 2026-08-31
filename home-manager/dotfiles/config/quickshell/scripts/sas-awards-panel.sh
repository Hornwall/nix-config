#!/usr/bin/env bash
set -Eeuo pipefail

# Simple panel for SAS awards using wofi

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WIDGET="$DIR/sas-awards-widget.sh"
FETCH="$DIR/fetch_sas_awards_v2.sh"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hyprpanel"
STATE_FILE="$STATE_DIR/sas_awards_state.json"
DEFAULT_YM="${HYPR_SAS_DEFAULT_YM:-2026-09}"

# Config via env (match widget defaults)
MARKET="${HYPR_SAS_MARKET:-se-sv}"
ORIGIN="${HYPR_SAS_ORIGIN:-ARN}"
DEST="${HYPR_SAS_DESTINATIONS:-HND}"
PASSENGERS="${HYPR_SAS_PASSENGERS:-2}"
DIRECT="${HYPR_SAS_DIRECT:-false}"
AVAIL="${HYPR_SAS_AVAILABILITY:-true}"
MIN_SEATS="${HYPR_SAS_MIN_SEATS:-0}"

ensure_state() {
  mkdir -p "$STATE_DIR"
  [[ -f "$STATE_FILE" ]] || printf '{"ym":"%s"}\n' "${DEFAULT_YM}" > "$STATE_FILE"
}

get_ym() { ensure_state; jq -r '.ym // empty' "$STATE_FILE" 2>/dev/null || true; }
set_ym() { mkdir -p "$STATE_DIR"; printf '{"ym":"%s"}\n' "$1" > "$STATE_FILE"; }

month_shift() {
  local base="$1"; local shift="${2:-0}"; local y m; IFS='-' read -r y m <<<"$base"
  local t=$((10#$y * 12 + 10#$m + shift))
  local yy=$((t / 12)); local mm=$((t % 12)); if (( mm == 0 )); then mm=12; yy=$((yy-1)); fi
  printf "%04d-%02d" "$yy" "$mm"
}

open_panel() {
  local ym="${1:-$(date +%Y-%m)}"
  local ymnodash="${ym//-/}"; local ymdash="$ym"

  # Fetch data
  local json
  if [[ -x "$FETCH" ]]; then
    if ! json="$("$FETCH" -m "$MARKET" -o "$ORIGIN" -D "$DEST" -p "$PASSENGERS" --direct "$DIRECT" --availability "$AVAIL" -M "$ymnodash" -F "$ymdash" 2>/dev/null)"; then
      json='[]'
    fi
  else
    json='[]'
  fi

  # Build menu lines
  local header="SAS ${ORIGIN}→${DEST}  ${ym}"
  local nav_prev="◀ Prev"
  local nav_next="Next ▶"

  local lines
  if command -v jq >/dev/null 2>&1; then
    lines=$(printf '%s' "$json" | jq -r --arg ym "$ymdash" --argjson min "$MIN_SEATS" '
      def filt(arr): (arr // []) | map(select((.date // "") | startswith($ym)))
        | map(select((.availableSeatsTotal // 0) >= $min));
      [
        (.[0].availability.outbound | filt(.) | map("out  " + (.date // "") + "  " + ((.availableSeatsTotal // 0)|tostring) + " seats  AG:" + ((.AG // 0)|tostring) + " AP:" + ((.AP // 0)|tostring))),
        (.[0].availability.inbound  | filt(.) | map("in   " + (.date // "") + "  " + ((.availableSeatsTotal // 0)|tostring) + " seats  AG:" + ((.AG // 0)|tostring) + " AP:" + ((.AP // 0)|tostring)))
      ] | add | sort | join("\n")
    ')
  else
    lines="Install jq for detailed view"
  fi

  local menu_input
  menu_input=$(printf '%s\n%s\n%s\n\n%s\n' "$nav_prev" "$nav_next" "$header" "$lines")

  # Fallback if wofi not present: notify
  if ! command -v wofi >/dev/null 2>&1; then
    notify-send "SAS ${ORIGIN}→${DEST} ${ym}" "$lines"
    exit 0
  fi

  # Display panel using wofi, handle month navigation
  local sel
  sel=$(printf '%s' "$menu_input" | wofi --dmenu --allow-markup --prompt "SAS Awards" --insensitive --matching fuzzy \
      --width 900 --height 550 --location center --cache-file /dev/null || true)

  case "$sel" in
    "$nav_prev") open_panel "$(month_shift "$ym" -1)" ;;
    "$nav_next") open_panel "$(month_shift "$ym" +1)" ;;
    *) ;; # any other selection closes
  esac
}

case "${1:-open}" in
  open) open_panel ;;
  [0-9][0-9][0-9][0-9]-[0-9][0-9]) open_panel "$1" ;;
  *) open_panel ;;
esac
