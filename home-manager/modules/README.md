# Home Manager Modules

This directory contains modular home manager configurations organized for better maintainability and reusability.

## Structure

- **`programs/`** - Individual program configurations
  - `git.nix` - Git configuration and aliases
  - `zsh.nix` - ZSH shell configuration
  - `neovim.nix` - Neovim editor configuration

- **`hosts/`** - Host-specific configuration overrides
  - `thinkpad-z16.nix` - ThinkPad Z16 specific settings
  - `x1-carbon.nix` - X1 Carbon specific settings  
  - `vm.nix` - Virtual machine specific settings

- **`packages.nix`** - Organized package lists categorized by purpose
- **`dotfiles.nix`** - Dotfile management and symlinking
- **`default.nix`** - Entry point that imports all base modules

## Usage

The main `home.nix` imports `./modules` which automatically loads `default.nix`, providing all base configurations. Host-specific modules are loaded separately in the flake configuration to allow per-machine customization.

## Adding New Modules

1. Create new `.nix` files in the appropriate subdirectory
2. Add the import to `default.nix` if it should be loaded for all hosts
3. Or add to specific host files in `hosts/` for machine-specific configurations

## Host-Specific Configurations

Each host can have its own additional packages, environment variables, or program overrides by modifying the corresponding file in `hosts/`.