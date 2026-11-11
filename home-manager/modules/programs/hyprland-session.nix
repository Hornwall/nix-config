{ config, lib, pkgs, ... }:

let
  # Long-running Hyprland helpers, run as systemd user services so they
  # restart on crash and log to `journalctl --user -u <name>`. They are tied to
  # hyprland-session.target (started by Hyprland itself), so they do not run
  # in GNOME sessions. Config files stay in dotfiles/config/hypr.
  mkHyprService = description: command: {
    Unit = {
      Description = description;
      # No After=hyprland-session.target: the target is already ordered after
      # the units it wants, and the extra edge can form ordering cycles.
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = command;
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  # Exits 0 when running on battery: a battery exists and no mains supply is
  # online. Desktops (no battery) count as plugged in. Used by hypridle.conf.
  onBattery = pkgs.writeShellApplication {
    name = "on-battery";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      shopt -s nullglob
      has_battery=false
      for supply in /sys/class/power_supply/*; do
        type=$(cat "$supply/type" 2>/dev/null || true)
        if [ "$type" = "Mains" ] && [ "$(cat "$supply/online" 2>/dev/null || echo 0)" = "1" ]; then
          exit 1
        fi
        if [ "$type" = "Battery" ]; then
          has_battery=true
        fi
      done
      $has_battery
    '';
  };
  # Lock screen info lines for hyprlock.conf. Each prints one short line, or
  # nothing when there is nothing to show.
  lockBattery = pkgs.writeShellApplication {
    name = "lock-battery";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      shopt -s nullglob
      for supply in /sys/class/power_supply/*; do
        [ "$(cat "$supply/type" 2>/dev/null)" = "Battery" ] || continue
        capacity=$(cat "$supply/capacity")
        case "$(cat "$supply/status")" in
          Charging) echo "󰂄 $capacity%" ;;
          Full) echo "󰁹 $capacity%" ;;
          *) echo "󰁾 $capacity%" ;;
        esac
        exit 0
      done
    '';
  };

  # Next timed (not all-day) event within a week, from GNOME's calendar server
  # via the same agenda.js that the Quickshell calendar popup uses. Events
  # after today are prefixed with "Tomorrow" or the weekday.
  lockNextEvent = pkgs.writeShellApplication {
    name = "lock-next-event";
    runtimeInputs = [ pkgs.coreutils pkgs.gjs pkgs.jq ];
    text = ''
      now=$(date +%s)
      today=$(date +%F)
      tomorrow=$(date -d tomorrow +%F)
      week=$(date -d '+7 days 00:00' +%s)
      timeout 5 gjs -m ${../../dotfiles/config/quickshell/scripts/agenda.js} "$now" "$week" 2>/dev/null \
        | jq -r --argjson now "$now" --arg today "$today" --arg tomorrow "$tomorrow" '
            [.[] | select(.start >= $now and (.end - .start) < 86400)]
            | sort_by(.start) | first // empty
            | (.start | strflocaltime("%F")) as $day
            | (if $day == $today then ""
               elif $day == $tomorrow then "Tomorrow "
               else (.start | strflocaltime("%a ")) end) as $prefix
            | "󰃭 \($prefix)\(.start | strflocaltime("%H:%M"))  \(.summary)"' \
        || true
    '';
  };

  # Current weather from quickshell's weather.sh (Open-Meteo), cached for 30
  # minutes so locking the screen doesn't hit the network every time.
  lockWeather = pkgs.writeShellApplication {
    name = "lock-weather";
    runtimeInputs = [ pkgs.bash pkgs.coreutils pkgs.curl pkgs.jq ];
    text = ''
      cache="''${XDG_RUNTIME_DIR:-/tmp}/lock-weather.json"
      if [ ! -s "$cache" ] || [ $(( $(date +%s) - $(stat -c %Y "$cache") )) -gt 1800 ]; then
        if bash ${../../dotfiles/config/quickshell/scripts/weather.sh} > "$cache.tmp" 2>/dev/null; then
          mv "$cache.tmp" "$cache"
        else
          rm -f "$cache.tmp"
        fi
      fi
      [ -s "$cache" ] || exit 0
      jq -r '
        .current as $c
        | ($c.weatherCode) as $w
        | (if $w == 0 then (if $c.isDay then "󰖙 Clear" else "󰖔 Clear" end)
           elif $w <= 2 then "󰖕 Partly cloudy"
           elif $w == 3 then "󰖐 Cloudy"
           elif $w <= 48 then "󰖑 Fog"
           elif $w <= 67 or ($w >= 80 and $w <= 82) then "󰖗 Rain"
           elif $w <= 77 or $w == 85 or $w == 86 then "󰖘 Snow"
           else "󰖓 Thunderstorm" end) as $desc
        | "\($desc)  \($c.temperature)° · \(.location)"' "$cache"
    '';
  };

  lockNowPlaying = pkgs.writeShellApplication {
    name = "lock-now-playing";
    runtimeInputs = [ pkgs.playerctl ];
    text = ''
      [ "$(playerctl status 2>/dev/null)" = "Playing" ] || exit 0
      playerctl metadata --format '󰎆 {{ artist }} — {{ title }}' 2>/dev/null || true
    '';
  };
in
{
  home.packages = [ onBattery lockBattery lockNextEvent lockWeather lockNowPlaying pkgs.playerctl ];

  # The GNOME account picture, under a name with an extension so hyprlock can
  # load it. Out-of-store link: the picture is managed by GNOME Settings.
  home.file.".face.png".source =
    config.lib.file.mkOutOfStoreSymlink "/var/lib/AccountsService/icons/${config.home.username}";

  systemd.user.services = {
    hypridle = mkHyprService "Hyprland idle daemon" (lib.getExe pkgs.hypridle);
    hyprpaper = mkHyprService "Hyprland wallpaper daemon" (lib.getExe pkgs.hyprpaper);
    quickshell = mkHyprService "Quickshell desktop shell" "${pkgs.quickshell}/bin/qs -n";
    # Overrides the package unit, which would also start under GNOME
    # (graphical-session.target) next to GNOME's own polkit agent.
    hyprpolkitagent = mkHyprService "Hyprland polkit authentication agent"
      "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
  };
}
