{ config, lib, pkgs, ... }:

{
  # Host-specific configuration for X1 Carbon
  # This could include specific packages, settings, or overrides for this machine
  
  # Example: Additional packages for the X1 Carbon
  home.packages = with pkgs; [
    # Add any X1 Carbon specific packages here
  ];

  # Example: Host-specific environment variables
  home.sessionVariables = {
    # HOST_MACHINE = "x1-carbon";
  };
}