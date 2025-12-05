{ config, lib, pkgs, ... }:

{
  programs.ssh = {
    addKeysToAgent = true;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
