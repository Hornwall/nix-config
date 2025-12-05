{ config, lib, pkgs, ... }:

{
  programs.ssh = {
    matchBlocks = {
      "*" = {
        addKeysToAgent = true;
      };
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
