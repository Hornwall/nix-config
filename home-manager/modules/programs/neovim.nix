{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    plugins = [
      pkgs.vimPlugins.packer-nvim
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
    ];
  };
}