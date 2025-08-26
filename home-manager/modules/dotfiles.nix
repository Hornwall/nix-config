{ config, lib, pkgs, ... }:

{
  home.file = {
    # ZSH Configuration
    ".zshrc".source = ../dotfiles/zshrc;
    ".zsh_prompt".source = ../dotfiles/zsh_prompt;
    ".zsh" = {
      source = ../dotfiles/zsh;
      recursive = true;
    };

    # Tmux Configuration
    ".tmux.conf".source = ../dotfiles/tmux.conf;

    # Application Config Directory
    ".config" = {
      source = ../dotfiles/config;
      recursive = true;
    };
  };

  fonts.fontconfig.enable = true;
}