{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    # We manage init.lua ourselves via dotfiles (see modules/dotfiles.nix).
    # As of home-manager 26.05 the module writes init.lua (previously init.vim),
    # which collides with our symlinked init.lua. sideloadInitLua keeps our file
    # authoritative and loads home-manager's generated lua via the nvim wrapper.
    sideloadInitLua = true;
    # Keep the pre-26.05 provider defaults (stateVersion is still < 26.05).
    withRuby = true;
    withPython3 = true;
    plugins = [
      pkgs.vimPlugins.packer-nvim
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
    ];
  };
}
