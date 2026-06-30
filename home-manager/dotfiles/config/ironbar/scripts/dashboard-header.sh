#!/usr/bin/env bash
# Header text for the ironbar dashboard popup. Emitted as two SEPARATE
# single-line labels (see config.toml) so each centers cleanly — a single
# multi-line label would block-center but left-justify each line.
#   $1 = "greeting" → time-of-day greeting
#   $1 = "date"     → formatted date + time
# Pango markup; polled by ironbar.
case "$1" in
  date)
    line=$(LC_TIME=sv_SE.UTF-8 date '+%A %e %B  ·  %H:%M')
    printf "<span size='10pt' foreground='#7d858d'>%s</span>" "${line^}"
    ;;
  *)
    h=$(date +%H)
    if   (( 10#$h < 5  )); then greet="Good night"
    elif (( 10#$h < 12 )); then greet="Good morning"
    elif (( 10#$h < 18 )); then greet="Good afternoon"
    else                        greet="Good evening"
    fi
    printf "<span size='15pt' foreground='#ffffff' weight='600'>%s</span>" "$greet"
    ;;
esac
