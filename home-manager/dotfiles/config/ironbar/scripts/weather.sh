#!/usr/bin/env bash
# Stockholm weather for the ironbar bar: flat nerd-font condition glyph +
# temperature (metric). The glyph is text, so it inherits the label colour.
# Polled every 30 min by ironbar. Prints nothing on failure so the widget
# just disappears rather than showing an error.
data=$(curl -fsS --max-time 5 \
  'https://api.open-meteo.com/v1/forecast?latitude=59.3293&longitude=18.0686&current=temperature_2m,weather_code&temperature_unit=celsius&timezone=Europe%2FStockholm' \
  2>/dev/null) || exit 0
read -r temp code < <(
  jq -r '[(.current.temperature_2m | round), .current.weather_code] | @tsv' <<<"$data"
)
[[ $temp =~ ^-?[0-9]+$ && $code =~ ^[0-9]+$ ]] || exit 0

# WMO weather interpretation codes returned by Open-Meteo.
case "$code" in
  95|96|99)                   icon='󰖓' ;;
  71|73|75|77|85|86)         icon='󰖘' ;;
  51|53|55|56|57|61|63|65|66|67|80|81|82) icon='󰖗' ;;
  45|48)                      icon='󰖑' ;;
  1|2)                        icon='󰖕' ;;
  3)                          icon='󰖐' ;;
  0)                          icon='󰖙' ;;
  *)                          icon='󰖕' ;;
esac

# Icon teal + sized to match the 16px image icons via Pango markup (custom
# labels render markup); temp text takes the label colour from CSS.
printf "<span foreground='#68b5ab' size='12pt'>%s</span> %s°C" "$icon" "$temp"
