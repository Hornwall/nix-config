{ config, lib, pkgs, ... }:

let
  # Keep this aligned with aboardhrWtCount in nixos/thinkpad-z16/aboard.nix.
  aboardhrWtCount = 10;

  aboardWorktree = pkgs.writeShellApplication {
    name = "aboard-wt";
    runtimeInputs = with pkgs; [
      coreutils
      direnv
      git
      python3
      tmux
      unstable.devenv
    ];
    text = ''
      export ABOARD_WT_SLOT_COUNT=${toString aboardhrWtCount}
      export ABOARD_WT_EXE="$0"
      exec python3 ${../scripts/aboard-wt.py} "$@"
    '';
  };
in
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
    aboardWorktree
    # Add any ThinkPad Z16 specific packages here
  ];

  # Example: Host-specific environment variables
  home.sessionVariables = {
    NIX_CONFIG_PATH = "/var/nix-config";
  };

  # Quickshell enables battery and power-profile widgets when UPower reports a
  # laptop battery.
}
