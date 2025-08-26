{ config, lib, pkgs, ... }:

{
  # Host-specific configuration for VM
  # This could include VM-specific packages, settings, or overrides
  
  # Example: VM-specific packages (lighter weight alternatives)
  home.packages = with pkgs; [
    # Add any VM specific packages here
  ];

  # Example: Host-specific environment variables
  home.sessionVariables = {
    # HOST_MACHINE = "vm";
  };
}