{ lib, pkgs, ... }:

let
  # Long-running Hyprland helpers, run as systemd user services so they
  # restart on crash and log to `journalctl --user -u <name>`. They are tied to
  # hyprland-session.target (started by Hyprland itself), so they do not run
  # in GNOME sessions. Config files stay in dotfiles/config/hypr.
  mkHyprService = description: command: {
    Unit = {
      Description = description;
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = command;
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  # Suspend only when running on battery: requires a battery and no mains
  # supply online. Desktops (no battery) never suspend from idle.
  idleSuspend = pkgs.writeShellApplication {
    name = "idle-suspend";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      shopt -s nullglob
      has_battery=false
      for supply in /sys/class/power_supply/*; do
        type=$(cat "$supply/type" 2>/dev/null || true)
        if [ "$type" = "Mains" ] && [ "$(cat "$supply/online" 2>/dev/null || echo 0)" = "1" ]; then
          exit 0
        fi
        if [ "$type" = "Battery" ]; then
          has_battery=true
        fi
      done
      if $has_battery; then
        exec systemctl suspend
      fi
    '';
  };
in
{
  home.packages = [ idleSuspend ];

  systemd.user.services = {
    hypridle = mkHyprService "Hyprland idle daemon" (lib.getExe pkgs.hypridle);
    hyprpaper = mkHyprService "Hyprland wallpaper daemon" (lib.getExe pkgs.hyprpaper);
    quickshell = mkHyprService "Quickshell desktop shell" "${pkgs.quickshell}/bin/qs -n";
  };
}
