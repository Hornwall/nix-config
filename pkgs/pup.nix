{ lib, stdenv, fetchurl, autoPatchelfHook }:

let
  version = "0.58.6";

  sources = {
    "x86_64-linux" = {
      arch = "Linux_x86_64";
      hash = "sha256-GlCBxiA9RP6lgV1tEHMFryN9AUkb5hnTzw62imUpH4Y=";
    };
    "aarch64-linux" = {
      arch = "Linux_arm64";
      hash = "sha256-OmZ1e0nmUYEFT1sFFQmag7nnRzHsWjCu8+i9E4IeJ9o=";
    };
    "x86_64-darwin" = {
      arch = "Darwin_x86_64";
      hash = "sha256-/ttrE4WcdzQHhKve/Phkv4w/M7/hdcUibl0K9+tyjSs=";
    };
    "aarch64-darwin" = {
      arch = "Darwin_arm64";
      hash = "sha256-lcdQW72WiEBfCVHOaodKfgXe1Uavbfi/vqX5tz1Tn/0=";
    };
  };

  source = sources.${stdenv.hostPlatform.system}
    or (throw "pup: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "pup";
  inherit version;

  src = fetchurl {
    url = "https://github.com/DataDog/pup/releases/download/v${version}/pup_${version}_${source.arch}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    install -Dm755 pup $out/bin/pup
    runHook postInstall
  '';

  meta = with lib; {
    description = "DataDog pup CLI";
    homepage = "https://github.com/DataDog/pup";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    mainProgram = "pup";
    platforms = builtins.attrNames sources;
  };
}
