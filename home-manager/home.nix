{ inputs, outputs, lib, config, pkgs, ... }:

{

  imports = [
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];

    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = "hannes";
    homeDirectory = "/home/hannes";
    stateVersion = "23.11";

    packages = [
      # Devtools
      pkgs.kitty
      pkgs.tmux
      pkgs.git
      pkgs.gcc
      pkgs.nodejs
      pkgs.gnumake
      pkgs.ripgrep
      pkgs.wl-clipboard
      pkgs.vscode
      #Fonts
      pkgs.fira-code
      pkgs.fira-code-nerdfont
      pkgs.fira-code-symbols
      pkgs.nerdfonts

      # Software
      pkgs.spotify
      pkgs.discord
      pkgs.slack
    ];

    file = {
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
    };

    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  programs = {
    neovim = {
      enable = true;
      plugins = [
        pkgs.vimPlugins.packer-nvim
      ];
    };

    home-manager = {
      enable = true;
    };

    zsh = {
      enable = true;
    };

    git = {
      enable = true;

      userName = "Hannes Hornwall";
      userEmail = "hannes@hornwall.me";
      
      aliases = {
        st = "status -sb";
      };
    };
  };
}
