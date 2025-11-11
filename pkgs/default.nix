# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  immersed-vr = pkgs.callPackage ./immersed-vr.nix { };
  beyond-identity = pkgs.callPackage ./beyond-identity.nix { };
  tuple = pkgs.callPackage ./tuple.nix { };
}
