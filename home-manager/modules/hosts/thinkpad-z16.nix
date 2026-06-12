{ config, lib, pkgs, ... }:

{
  # Host-specific configuration for ThinkPad Z16
  # This could include specific packages, settings, or overrides for this machine
  
  # Example: Additional packages for the ThinkPad Z16
  home.packages = with pkgs; [
    pkgs.slack
    pkgs.teams-for-linux
    pkgs.awscli2
    pkgs.sentry-cli
    pkgs.pup
    pkgs.abrd-admin
    pkgs.abrd
    # Add any ThinkPad Z16 specific packages here
  ];

  # Example: Host-specific environment variables
  home.sessionVariables = {
    NIX_CONFIG_PATH = "/var/nix-config";
  };

  # No ironbar override: the laptop uses the base bar (which includes battery).
}
