#!/usr/bin/env bash
# Forecast for the ironbar weather popup: today's 3-hourly forecast plus
# today and the next two days. Output is Pango markup for a single multi-line
# label — teal glyphs, white text, muted times.
TEAL='#68b5ab'
MUTED='#5c656e'

data=$(curl -fsS --max-time 8 \
  'https://api.open-meteo.com/v1/forecast?latitude=59.3293&longitude=18.0686&current=temperature_2m&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&temperature_unit=celsius&timezone=Europe%2FStockholm&forecast_days=3' \
  2>/dev/null) || { printf 'forecast unavailable'; exit 0; }

# WMO weather interpretation codes → material design glyphs.
GLYPH_DEF='def g: ({
  "0":"󰖙","1":"󰖕","2":"󰖕","3":"󰖐",
  "45":"󰖑","48":"󰖑",
  "51":"󰖗","53":"󰖗","55":"󰖗","56":"󰖗","57":"󰖗",
  "61":"󰖗","63":"󰖗","65":"󰖗","66":"󰖗","67":"󰖗",
  "80":"󰖗","81":"󰖗","82":"󰖗",
  "71":"󰖘","73":"󰖘","75":"󰖘","77":"󰖘","85":"󰖘","86":"󰖘",
  "95":"󰖓","96":"󰖓","99":"󰖓"
}[tostring] // "󰖕");'

out="<b>Today</b>\n"
while IFS=$'\t' read -r hour glyph temp; do
  printf -v line "<span foreground='%s'>%s:00</span>  <span foreground='%s'>%s</span>  %3s°" \
    "$MUTED" "$hour" "$TEAL" "$glyph" "$temp"
  out+="$line\n"
done < <(jq -r "$GLYPH_DEF"'
  . as $root
  | range(0; (.hourly.time | length)) as $i
  | select($root.hourly.time[$i][0:10] == $root.current.time[0:10])
  | select((($root.hourly.time[$i][11:13] | tonumber) % 3) == 0)
  | [$root.hourly.time[$i][11:13], ($root.hourly.weather_code[$i] | g), ($root.hourly.temperature_2m[$i] | round)]
  | @tsv
' <<<"$data")

out+="\n<b>Coming days</b>\n"
while IFS=$'\t' read -r d min max glyph; do
  printf -v line "<span foreground='%s'>%s</span>  <span foreground='%s'>%s</span>  %3s° / %s°" \
    "$MUTED" "$(date -d "$d" +%a)" "$TEAL" "$glyph" "$min" "$max"
  out+="$line\n"
done < <(jq -r "$GLYPH_DEF"'
  . as $root
  | range(0; (.daily.time | length)) as $i
  | [$root.daily.time[$i], ($root.daily.temperature_2m_min[$i] | round), ($root.daily.temperature_2m_max[$i] | round), ($root.daily.weather_code[$i] | g)]
  | @tsv
' <<<"$data")

printf '%b' "${out%\\n}"
