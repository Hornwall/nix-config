# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  agent-browser = pkgs.callPackage ./agent-browser.nix { };
  beyond-identity = pkgs.callPackage ./beyond-identity.nix { };
  opencode = pkgs.callPackage ./opencode.nix { };
  tuple = pkgs.callPackage ./tuple.nix { };
  voxtype = pkgs.callPackage ./voxtype.nix { vulkanSupport = true; };
  voxtype-cuda = if pkgs.stdenv.hostPlatform.isLinux then pkgs.callPackage ./voxtype.nix { cudaSupport = true; } else pkgs.callPackage ./voxtype.nix { };
  voxtype-onnx = pkgs.callPackage ./voxtype.nix { onnxSupport = true; };
  voxtype-rocm = if pkgs.stdenv.hostPlatform.isLinux then pkgs.callPackage ./voxtype.nix { rocmSupport = true; } else pkgs.callPackage ./voxtype.nix { };
  voxtype-vulkan = pkgs.callPackage ./voxtype.nix { vulkanSupport = true; };
}
