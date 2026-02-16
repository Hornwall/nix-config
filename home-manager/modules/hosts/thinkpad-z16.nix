{ config, lib, pkgs, ... }:

{
  # Host-specific configuration for ThinkPad Z16
  # This could include specific packages, settings, or overrides for this machine
  
  # Example: Additional packages for the ThinkPad Z16
  home.packages = with pkgs; [
    pkgs.slack
    pkgs.teams-for-linux
    pkgs.awscli2
    # Add any ThinkPad Z16 specific packages here
  ];

  # Example: Host-specific environment variables
  home.sessionVariables = {
    # HOST_MACHINE = "thinkpad-z16";
  };
}
