#!/usr/bin/env bash
# Stockholm weather for the ironbar bar: condition glyph + temperature (metric).
# Polled infrequently (30 min) by ironbar. Prints nothing on failure so the
# widget just disappears rather than showing an error.
out=$(curl -fsS --max-time 5 'https://wttr.in/Stockholm?format=%c%t&m' 2>/dev/null) || exit 0
# Trim whitespace wttr.in occasionally pads with.
printf '%s' "${out//+/}" | tr -d '\n'
