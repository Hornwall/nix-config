{ config, lib, pkgs, ... }:

{
  home.packages = [
    # Development Tools
    pkgs.kitty
    pkgs.ghostty
    pkgs.tmux
    pkgs.git
    pkgs.gh
    pkgs.gcc
    pkgs.nodejs
    pkgs.gnumake
    pkgs.ripgrep
    pkgs.jq
    pkgs.wl-clipboard
    pkgs.dive
    pkgs.docker-slim
    pkgs.ssm-session-manager-plugin
    pkgs.yarn
    pkgs.devbox
    pkgs.heroku
    pkgs.solargraph
    pkgs.gnupg
    pkgs.nodePackages_latest.typescript-language-server
    pkgs.ngrok
    pkgs.fzf
    pkgs.zeal
    pkgs.tldr
    pkgs.unstable.devenv
    pkgs.direnv
    pkgs.opencode

    # Desktop Applications
    pkgs.spotify
    pkgs.discord
    pkgs.gimp
    pkgs.chromium
    pkgs.inkscape
    pkgs.calibre
    pkgs.feh
    pkgs.lmstudio
    pkgs.gradia
    pkgs.prismlauncher

    # Hyprland & Window Manager
    pkgs.wofi
    pkgs.hyprpaper
    pkgs.hypridle
    pkgs.hyprlock
    pkgs.hyprpanel
    pkgs.hyprcursor
    pkgs.hyprpolkitagent
    pkgs.brightnessctl
    pkgs.wf-recorder
    pkgs.grim
    pkgs.slurp
    pkgs.satty
    pkgs.tesseract
    pkgs.gnome-keyring
    pkgs.seahorse
    pkgs.walker
    pkgs.libnotify
  ];
}
