{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
  };

  programs.ssh = {
    addKeysToAgent = true;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}