{ config, lib, pkgs, ... }:

let
  # Full system update: flake inputs, pinned Claude packages, NixOS, Home Manager,
  # then prune old system generations (keeping the latest three).
  nixUpdate = pkgs.writeShellApplication {
    name = "nix-update";
    runtimeInputs = with pkgs; [ coreutils git nix home-manager hostname ];
    text = ''
      repo="''${NIX_CONFIG_DIR:-/var/nix-config}"
      host="$(hostname)"
      cd "$repo"

      echo "==> Updating flake inputs"
      nix flake update

      echo "==> Updating claude-code"
      ./pkgs/claude-code/update.sh

      echo "==> Updating claude-desktop"
      ./pkgs/claude-desktop/update.sh

      update_files=(flake.lock pkgs/claude-code/manifest.json pkgs/claude-desktop/manifest.json)
      if git diff --quiet HEAD -- "''${update_files[@]}"; then
        echo "==> Nothing changed, done"
        exit 0
      fi

      # Claude packages are only used by Home Manager; NixOS only needs a
      # rebuild when the flake inputs moved.
      nixos_changed=false
      if ! git diff --quiet HEAD -- flake.lock; then
        nixos_changed=true
        echo "==> Rebuilding NixOS ($host)"
        sudo nixos-rebuild switch --flake ".#$host"
      else
        echo "==> Flake inputs unchanged, skipping NixOS rebuild"
      fi

      echo "==> Switching Home Manager ($USER@$host)"
      home-manager switch --flake ".#$USER@$host"

      echo "==> Committing and pushing updates"
      git add -- "''${update_files[@]}"
      git commit -m "Update packages" -- "''${update_files[@]}"
      git push

      if [[ "$nixos_changed" == true ]]; then
        echo "==> Pruning NixOS generations (keeping latest 3)"
        sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +3
        # Refresh bootloader entries so pruned generations disappear from the menu.
        sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot
        sudo nix-collect-garbage
      fi

      echo "==> Done"
    '';
  };
in
{
  home.packages = [
    nixUpdate
    # Development Tools
    pkgs.kitty
    pkgs.ghostty
    pkgs.tmux
    pkgs.git
    pkgs.gh
    pkgs.gcc
    pkgs.nodejs
    pkgs.gnumake
    pkgs.unzip
    pkgs.ripgrep
    pkgs.jq
    pkgs.wl-clipboard
    pkgs.dive
    pkgs.docker-slim
    pkgs.ssm-session-manager-plugin
    pkgs.yarn
    pkgs.devbox
    pkgs.heroku
    pkgs.ruby-lsp
    pkgs.gnupg
    pkgs.typescript-language-server
    pkgs.ngrok
    pkgs.fzf
    pkgs.zeal
    pkgs.tldr
    pkgs.unstable.devenv
    pkgs.direnv
    pkgs.opencode
    pkgs.claude-code
    pkgs.claude-desktop
    pkgs.graphify
    pkgs.xtool
    pkgs.t3code
    pkgs.unstable.pi-coding-agent

    # Desktop Applications
    pkgs.spotify
    pkgs.discord
    pkgs.gimp
    # Vulkan lets WebGPU use the real GPU instead of the SwiftShader CPU fallback.
    # Force the iGPU: WebGPU on the dGPU while compositing on the iGPU gives corrupt frames.
    (pkgs.chromium.override {
      commandLineArgs = [
        "--enable-features=Vulkan"
        "--enable-unsafe-webgpu"
        "--use-webgpu-power-preference=force-low-power"
      ];
    })
    pkgs.inkscape
    pkgs.calibre
    pkgs.feh
    pkgs.lmstudio
    pkgs.gradia
    pkgs.prismlauncher
    pkgs.unstable.openscreen
    pkgs.obsidian
    pkgs.proton-pass
    #pkgs.unstable.ladybird

    # Hyprland & Window Manager
    pkgs.wofi
    pkgs.hyprpaper
    pkgs.hypridle
    pkgs.hyprlock
    pkgs.quickshell
    pkgs.hyprcursor
    pkgs.hyprpolkitagent
    pkgs.brightnessctl
    pkgs.wf-recorder
    pkgs.grim
    pkgs.slurp
    pkgs.tesseract
    pkgs.gnome-keyring
    pkgs.seahorse
    pkgs.libnotify
    pkgs.gjs # Calendar agenda adapter for Quickshell
  ];

  home.file.".local/bin/obsidian" = {
    executable = true;
    force = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      gui="${pkgs.unstable.obsidian}/bin/obsidian"
      cli="${pkgs.unstable.obsidian}/bin/obsidian-cli"

      if [[ $# -gt 0 && "$1" == obsidian://* ]]; then
        exec "$gui" "$@"
      fi

      if [[ $# -eq 0 && ! -t 0 && ! -t 1 ]]; then
        exec "$gui"
      fi

      exec "$cli" "$@"
    '';
  };
}
