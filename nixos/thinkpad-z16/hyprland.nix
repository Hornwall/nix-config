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

  security.pam.services.hyprlock = {};
  security.pam.services.swaylock = {};
}
