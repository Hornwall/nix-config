# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  agent-browser = pkgs.callPackage ./agent-browser.nix { };
  beyond-identity = pkgs.callPackage ./beyond-identity.nix { };
  opencode = pkgs.callPackage ./opencode.nix { };
  tuple = pkgs.callPackage ./tuple.nix { };
}
