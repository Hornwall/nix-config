{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "hannes";
  home.homeDirectory = "/home/hannes";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello
    pkgs.kitty
    pkgs.tmux
    pkgs.git
    pkgs.gcc
    pkgs.gnumake
    pkgs.ripgrep
    pkgs.fira-code
    pkgs.fira-code-nerdfont
    pkgs.fira-code-symbols

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # ZSH
    ".zshrc".source = dotfiles/zshrc;
    ".zsh_prompt".source = dotfiles/zsh_prompt;
    ".zsh/aliases".source = dotfiles/zsh/aliases;
    ".zsh/completion".source = dotfiles/zsh/completion;
    ".zsh/functions".source = dotfiles/zsh/functions;
    ".zsh/work_aliases".source = dotfiles/zsh/work_aliases;

    # Tmux
    ".tmux.conf".source = dotfiles/tmux.conf;
    # Kitty
    ".config/kitty/kitty.conf".source = dotfiles/config/kitty/kitty.conf;

    # Neovim
    ".config/nvim/init.lua".source = dotfiles/config/nvim/init.lua;
    ".config/nvim/colors/hybrid.vim".source = dotfiles/config/nvim/colors/hybrid.vim;
    ".config/nvim/lua/bindings.lua".source = dotfiles/config/nvim/lua/bindings.lua;
    ".config/nvim/lua/editor.lua".source = dotfiles/config/nvim/lua/editor.lua;
    ".config/nvim/lua/cheat-sheet.lua".source = dotfiles/config/nvim/lua/cheat-sheet.lua;
    ".config/nvim/lua/plugins.lua".source = dotfiles/config/nvim/lua/plugins.lua;
    ".config/nvim/lua/plugins/configs/cmp.lua".source = dotfiles/config/nvim/lua/plugins/configs/cmp.lua;
    ".config/nvim/lua/plugins/configs/lualine.lua".source = dotfiles/config/nvim/lua/plugins/configs/lualine.lua;
    ".config/nvim/lua/plugins/configs/nvim-lsp.lua".source = dotfiles/config/nvim/lua/plugins/configs/nvim-lsp.lua;
    ".config/nvim/lua/plugins/configs/nvimtree.lua".source = dotfiles/config/nvim/lua/plugins/configs/nvimtree.lua;
    ".config/nvim/lua/plugins/configs/treesitter.lua".source = dotfiles/config/nvim/lua/plugins/configs/treesitter.lua;
    ".config/nvim/lua/plugins/configs/vim-test.lua".source = dotfiles/config/nvim/lua/plugins/configs/vim-test.lua;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/hannes/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.neovim = {
    enable = true;
    plugins = [
      pkgs.vimPlugins.packer-nvim
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;

    userName = "Hannes Hornwall";
    userEmail = "hannes@hornwall.me";
    
    aliases = {
      st = "status -sb";
    };
  };
}
