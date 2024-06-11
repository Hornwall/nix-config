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

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # Devtools
    pkgs.kitty
    pkgs.tmux
    pkgs.git
    pkgs.gh
    pkgs.gcc
    pkgs.nodejs
    pkgs.gnumake
    pkgs.ripgrep
    pkgs.wl-clipboard
    pkgs.vscode
    pkgs.devbox
    pkgs.heroku
    pkgs.solargraph
    pkgs.gnupg
    pkgs.nodePackages_latest.typescript-language-server
    pkgs.ngrok
    pkgs.fzf
    #Fonts
    pkgs.fira-code
    pkgs.fira-code-nerdfont
    pkgs.fira-code-symbols
    pkgs.nerdfonts

    # Software
    pkgs.spotify
    pkgs.discord
    pkgs.slack
    pkgs.gimp
    pkgs.chromium

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
    ".zsh".source = dotfiles/zsh;
    ".zsh".recursive = true;

    # Tmux
    ".tmux.conf".source = dotfiles/tmux.conf;
    # .config
    ".config".source = dotfiles/config;
    ".config".recursive = true;

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
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
  };

  programs.git = {
    enable = true;

    userName = "Hannes Hornwall";
    userEmail = "hannes@hornwall.me";
    
    aliases = {
      st = "status -sb";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      fixup = "!git log -n 50 --pretty=format:'%h %s' --no-merges | fzf | cut -c -7 | xargs -o git commit --fixup";
    };
  };
}

