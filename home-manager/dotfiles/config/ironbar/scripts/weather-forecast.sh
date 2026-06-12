#!/usr/bin/env bash
# Forecast for the ironbar weather popup: today's 3-hourly forecast plus the
# three days wttr.in provides (today + 2). Output is Pango markup for a
# single multi-line label — teal glyphs, white text, muted times.
TEAL='#68b5ab'
MUTED='#5c656e'

data=$(curl -fsS --max-time 8 'https://wttr.in/Stockholm?format=j1' 2>/dev/null) \
  || { printf 'forecast unavailable'; exit 0; }

# WWO weather codes → material design glyphs
GLYPH_DEF='def g: {
  "113":"󰖙","116":"󰖕","119":"󰖐","122":"󰖐",
  "143":"󰖑","248":"󰖑","260":"󰖑",
  "176":"󰖗","263":"󰖗","266":"󰖗","293":"󰖗","296":"󰖗","299":"󰖗",
  "302":"󰖗","305":"󰖗","308":"󰖗","311":"󰖗","314":"󰖗","317":"󰖗",
  "353":"󰖗","356":"󰖗","359":"󰖗",
  "200":"󰖓","386":"󰖓","389":"󰖓","392":"󰖓",
  "179":"󰖘","182":"󰖘","185":"󰖘","227":"󰖘","230":"󰖘","320":"󰖘",
  "323":"󰖘","326":"󰖘","329":"󰖘","332":"󰖘","335":"󰖘","338":"󰖘",
  "368":"󰖘","371":"󰖘","374":"󰖘","377":"󰖘","395":"󰖘"
}[.] // "󰖕";'

out="<b>Today</b>\n"
while IFS=$'\t' read -r t glyph temp; do
  printf -v line "<span foreground='%s'>%02d:00</span>  <span foreground='%s'>%s</span>  %3s°" \
    "$MUTED" $((10#$t / 100)) "$TEAL" "$glyph" "$temp"
  out+="$line\n"
done < <(jq -r "$GLYPH_DEF"' .weather[0].hourly[] | [.time, (.weatherCode|g), .tempC] | @tsv' <<<"$data")

out+="\n<b>Coming days</b>\n"
while IFS=$'\t' read -r d min max glyph; do
  printf -v line "<span foreground='%s'>%s</span>  <span foreground='%s'>%s</span>  %3s° / %s°" \
    "$MUTED" "$(date -d "$d" +%a)" "$TEAL" "$glyph" "$min" "$max"
  out+="$line\n"
done < <(jq -r "$GLYPH_DEF"' .weather[] | [.date, .mintempC, .maxtempC, (.hourly[4].weatherCode|g)] | @tsv' <<<"$data")

printf '%b' "${out%\\n}"
