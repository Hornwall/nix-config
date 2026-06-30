#!/usr/bin/env bash
# Live system stats for the ironbar dashboard popup: CPU, RAM and root-disk
# usage, each as a nerd-font glyph + mini unicode bar + percentage.
# Polled by ironbar (a few seconds). Pango markup; colours match the theme.
accent='#68b5ab'   # teal  — bar fill
muted='#3a4046'    # empty bar track
text='#b7bcba'

row() {
  local glyph=$1 pct=$2
  local segs=10 filled i fill="" track=""
  filled=$(( (pct * segs + 50) / 100 ))
  for (( i = 0; i < filled; i++ )); do fill+="█"; done
  for (( i = filled; i < segs; i++ )); do track+="─"; done
  printf "<span foreground='%s' size='12pt'>%s</span>  <span foreground='%s'>%s</span><span foreground='%s'>%s</span>  <span foreground='%s'>%3d%%</span>" \
    "$accent" "$glyph" "$accent" "$fill" "$muted" "$track" "$text" "$pct"
}

# CPU: delta of busy vs total jiffies across a short sample.
read -r _ u n s idle io irq sirq steal _ < /proc/stat
t1=$((u + n + s + idle + io + irq + sirq + steal)); b1=$((t1 - idle - io))
sleep 0.25
read -r _ u n s idle io irq sirq steal _ < /proc/stat
t2=$((u + n + s + idle + io + irq + sirq + steal)); b2=$((t2 - idle - io))
dt=$((t2 - t1)); db=$((b2 - b1))
cpu=0; (( dt > 0 )) && cpu=$(( db * 100 / dt ))

# RAM: (total - available) / total.
mem_total=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
mem_avail=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
ram=0; (( mem_total > 0 )) && ram=$(( (mem_total - mem_avail) * 100 / mem_total ))

# Disk: root filesystem use%.
disk=$(df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9')
disk=${disk:-0}

printf '%s\n%s\n%s' \
  "$(row '󰻠' "$cpu")" \
  "$(row '󰍛' "$ram")" \
  "$(row '󰋊' "$disk")"
