#!/usr/bin/env bash
# Stockholm weather for the ironbar bar: flat nerd-font condition glyph +
# temperature (metric). The glyph is text, so it inherits the label colour.
# Polled every 30 min by ironbar. Prints nothing on failure so the widget
# just disappears rather than showing an error.
data=$(curl -fsS --max-time 5 'https://wttr.in/Stockholm?format=%C|%t&m' 2>/dev/null) || exit 0
cond=$(printf '%s' "${data%%|*}" | tr '[:upper:]' '[:lower:]')
temp=${data##*|}
temp=${temp//+/}

case "$cond" in
  *thunder*)                       icon='󰖓' ;;
  *snow*|*sleet*|*blizzard*|*ice*) icon='󰖘' ;;
  *drizzle*|*rain*|*shower*)       icon='󰖗' ;;
  *fog*|*mist*)                    icon='󰖑' ;;
  *partly*)                        icon='󰖕' ;;
  *cloud*|*overcast*)              icon='󰖐' ;;
  *clear*|*sunny*)                 icon='󰖙' ;;
  *)                               icon='󰖕' ;;
esac

# Icon teal + sized to match the 16px image icons via Pango markup (custom
# labels render markup); temp text takes the label colour from CSS.
printf "<span foreground='#68b5ab' size='12pt'>%s</span> %s" "$icon" "$temp" | tr -d '\n'
