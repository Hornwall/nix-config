{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Development Tools
    kitty
    ghostty
    tmux
    git
    gh
    gcc
    nodejs
    gnumake
    ripgrep
    wl-clipboard
    dive
    docker-slim
    awscli2
    ssm-session-manager-plugin
    yarn
    devbox
    heroku
    solargraph
    gnupg
    nodePackages_latest.typescript-language-server
    ngrok
    fzf
    zeal
    tldr

    # Desktop Applications
    spotify
    discord
    slack
    gimp
    chromium
    inkscape
    teams-for-linux
    calibre
    feh

    # Hyprland & Window Manager
    wofi
    hyprpaper
    hypridle
    hyprlock
    hyprpanel
    hyprcursor
    hyprpolkitagent
    brightnessctl
    wf-recorder
    grim
    slurp
    satty
    tesseract
    gnome-keyring
    seahorse
    sherlock-launcher
    libnotify
  ];
}