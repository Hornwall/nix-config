{ inputs, pkgs }:
let
  # Hyprland comes from the pinned nixpkgs-hyprland input (0.55.4), not
  # pkgs.unstable: hyprsplit doesn't compile against hyprland 0.56's reworked
  # state/* API yet (shezdy/hyprsplit#90). Switch back to pkgs.unstable and
  # drop the input once upstream supports 0.56.
  hyprPkgs = import inputs.nixpkgs-hyprland {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  #programs.hyperland = {
  #  enable = true;
  #  xwayland.enable = true;
  #};
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = hyprPkgs.hyprland;
    plugins = [
      # nixpkgs' hyprsplit (0.54.2) lags hyprland (0.55.x) and no longer
      # compiles against it, so build the plugin from the pinned hyprsplit
      # input source against the hyprland we actually run.
      (hyprPkgs.hyprlandPlugins.hyprsplit.overrideAttrs {
        src = inputs.hyprsplit;
        version = "0.55-unstable";
      })
    ];
  };

  # Route portal requests to the Hyprland backend under Hyprland sessions.
  # Without a hyprland-specific (or common) portals.conf, xdg-desktop-portal
  # 1.20+ has no backend assigned for ScreenCast, so screen sharing in
  # Slack/Chromium finds no sources. gnome.nix only configures the `gnome`
  # desktop, which doesn't apply when XDG_CURRENT_DESKTOP=Hyprland.
  xdg.portal.config.hyprland = {
    default = [ "hyprland" "gtk" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
    "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };

  # Drop CAP_SYS_NICE from the Hyprland wrapper. nixpkgs sets
  # security.wrappers.Hyprland.capabilities = "cap_sys_nice+ep" so Hyprland can
  # self-promote to SCHED_RR; Hyprland then raises CAP_SYS_NICE into its AMBIENT
  # set, so every descendant (Slack, Firefox, …) inherits it in cap_permitted.
  # xdg-desktop-portal runs as a user systemd service with cap_effective=0, so
  # the kernel's cap_ptrace_access_check (cap_issubset(child.permitted,
  # caller.effective)) fails when the portal opens /proc/<caller>/root to detect
  # flatpak. xdp 1.20.4 treats this as fatal and replies AccessDenied to every
  # request → screen share / file dialogs never appear. Dropping the cap fixes
  # it (Hyprland loses SCHED_RR self-promotion). See flatpak/xdg-desktop-portal#1691.
  security.wrappers.Hyprland.capabilities = pkgs.lib.mkForce "";

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  security.pam.services.hyprlock = {};
  security.pam.services.swaylock = {};
  security.polkit.enable = true;
}
