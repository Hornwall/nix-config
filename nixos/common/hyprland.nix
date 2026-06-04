{ inputs, pkgs }:
{
  #programs.hyperland = {
  #  enable = true;
  #  xwayland.enable = true;
  #};
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.unstable.hyprland;
    plugins = [
      # nixpkgs' hyprsplit (0.54.2) lags hyprland (0.55.x) and no longer
      # compiles against it, so build the plugin from the pinned hyprsplit
      # input source against the unstable hyprland we actually run.
      (pkgs.unstable.hyprlandPlugins.hyprsplit.overrideAttrs {
        src = inputs.hyprsplit;
        version = "0.55-unstable";
      })
    ];
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  security.pam.services.hyprlock = {};
  security.pam.services.swaylock = {};
  security.polkit.enable = true;
}
