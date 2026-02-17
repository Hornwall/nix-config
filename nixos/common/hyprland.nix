{ pkgs }:
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
      pkgs.hyprlandPlugins.hyprsplit
    ];
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  security.pam.services.hyprlock = {};
  security.pam.services.swaylock = {};
  security.polkit.enable = true;
}
