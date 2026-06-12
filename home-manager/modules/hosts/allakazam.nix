{ config, lib, pkgs, ... }:

{
  # Host-specific configuration for ThinkPad Z16
  # This could include specific packages, settings, or overrides for this machine
  
  # Example: Additional packages for the ThinkPad Z16
  home.packages = with pkgs; [
    # Add any allakazam specific packages here
  ];

  # Example: Host-specific environment variables
  home.sessionVariables = {
    NIX_CONFIG_PATH = "/home/hannes/code/nix-config";
  };

  # Desktop has no battery, so use a battery-less copy of the ironbar config.
  hornwall.dotfiles.overrides = {
    ".config/ironbar/config.toml" = ../../dotfiles/hosts/allakazam/ironbar/config.toml;
  };
}
