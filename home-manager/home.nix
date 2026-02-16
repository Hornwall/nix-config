{ config, pkgs, inputs, outputs, ... }:

{
  # Import all our modular configurations
  imports = [
    ./modules
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "hannes";
  home.homeDirectory = "/home/hannes";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
