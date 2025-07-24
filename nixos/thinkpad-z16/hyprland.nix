{inputs, pkgs}:
{
  #programs.hyperland = {
  #  enable = true;
  #  xwayland.enable = true;
  #};
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # Use the hyprland package from our flake input for consistency
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
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
