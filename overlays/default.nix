# This file defines overlays
{ inputs, ... }: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev:
    import ../pkgs {
      pkgs = final;
      unstablePkgs = import inputs.nixpkgs-unstable {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
      abrdAdminPackage = final.callPackage (inputs.aboard-admin-cli + "/nix/package.nix") {
        buildGoModule = final.buildGo126Module;
        version = inputs.aboard-admin-cli.shortRev or "dev";
      };
    };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
