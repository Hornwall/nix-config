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
in
{
  home.packages = [ onBattery ];

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
