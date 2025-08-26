{ config, lib, pkgs, ... }:

{
  # This file serves as an entry point for all home-manager modules
  # It can be imported to get all the modular configurations at once
  
  imports = [
    ./programs/git.nix
    ./programs/zsh.nix
    ./programs/neovim.nix
    ./packages.nix
    ./dotfiles.nix
  ];
}