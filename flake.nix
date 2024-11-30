{
  description = "Hornwall nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Hardware support
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
     self,
     nixpkgs,
     nixos-hardware,
     nixpkgs-unstable,
     home-manager,
     ...
   } @ inputs: let
     inherit (self) outputs;
     # Supported systems for your flake packages, shell, etc.
     systems = [
       "aarch64-linux"
       "i686-linux"
       "x86_64-linux"
       "aarch64-darwin"
       "x86_64-darwin"
     ];
     # This is a function that generates an attribute by calling a function you
     # pass to it, with each system as an argument
     forAllSystems = nixpkgs.lib.genAttrs systems;
   in {
     # Your custom packages
     # Accessible through 'nix build', 'nix shell', etc
     packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      );
     # Formatter for your nix files, available through 'nix fmt'
     # Other options beside 'alejandra' include 'nixpkgs-fmt'
     #formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

     # Your custom packages and modifications, exported as overlays
     overlays = import ./overlays {inherit inputs;};
     # Reusable nixos modules you might want to export
     # These are usually stuff you would upstream into nixpkgs
     #nixosModules = import ./modules/nixos;
     # Reusable home-manager modules you might want to export
     # These are usually stuff you would upstream into home-manager
     #homeManagerModules = import ./modules/home-manager;

     # NixOS configuration entrypoint
     # Available through 'nixos-rebuild --flake .#your-hostname'
     nixosConfigurations = {
       x1-carbon = nixpkgs.lib.nixosSystem {
         specialArgs = {inherit inputs outputs;};
         modules = [
           ./nixos/x1-carbon/configuration.nix
         ];
       };
       thinkpad-z16 = nixpkgs.lib.nixosSystem {
         specialArgs = {inherit inputs outputs;};
         modules = [
           nixos-hardware.nixosModules.lenovo-thinkpad-z
           ./nixos/thinkpad-z16/configuration.nix
         ];
       };
       vm = nixpkgs.lib.nixosSystem {
         specialArgs = {inherit inputs outputs;};
         modules = [
           ./nixos/vm/configuration.nix
         ];
       };
     };

     # Standalone home-manager configuration entrypoint
     # Available through 'home-manager --flake .#your-username@your-hostname'
     homeConfigurations = {
       # FIXME replace with your username@hostname
       "hannes@x1-carbon" = home-manager.lib.homeManagerConfiguration {
         pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
         extraSpecialArgs = {inherit inputs outputs;};
         modules = [
           # > Our main home-manager configuration file <
           ./home-manager/home.nix
         ];
       };
       "hannes@thinkpad-z16" = home-manager.lib.homeManagerConfiguration {
         pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
         extraSpecialArgs = {inherit inputs outputs;};
         modules = [
           # > Our main home-manager configuration file <
           ./home-manager/home.nix
         ];
       };
       "hannes@vm" = home-manager.lib.homeManagerConfiguration {
         pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
         extraSpecialArgs = {inherit inputs outputs;};
         modules = [
           # > Our main home-manager configuration file <
           ./home-manager/home.nix
         ];
       };
     };
   };
}
