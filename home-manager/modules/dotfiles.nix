{ config, lib, ... }:

let
  configDotfilesDir = ../dotfiles/config;

  configFileEntries =
    builtins.listToAttrs (
      map
        (file: {
          name =
            ".config/"
            + lib.removePrefix "${toString configDotfilesDir}/" (toString file);
          value.source = file;
        })
        (lib.filesystem.listFilesRecursive configDotfilesDir)
    );

  defaultDotfiles = {
    ".zshrc".source = ../dotfiles/zshrc;
    ".zsh_prompt".source = ../dotfiles/zsh_prompt;
    ".zsh" = {
      source = ../dotfiles/zsh;
      recursive = true;
    };
    ".tmux.conf".source = ../dotfiles/tmux.conf;
  } // configFileEntries;

  overrideDotfiles =
    lib.mapAttrs (_: source: { inherit source; })
      config.hornwall.dotfiles.overrides;
in
{
  options.hornwall.dotfiles.overrides = lib.mkOption {
    type = lib.types.attrsOf lib.types.path;
    default = { };
    description = "Per-host dotfile source overrides keyed by target path.";
    example = {
      ".config/hyprpanel/config.json" = ../dotfiles/hosts/thinkpad-z16/hyprpanel/config.json;
    };
  };

  config = {
    home.file = defaultDotfiles // overrideDotfiles;
    fonts.fontconfig.enable = true;
  };
}
