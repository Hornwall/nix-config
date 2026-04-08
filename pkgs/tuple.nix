{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "tuple";
  version = "v2026_04_02.0";

  src = fetchurl {
    url = "https://tuple-client-releases.s3.amazonaws.com/linux/${version}/x86_64/tuple";
    hash = "sha256-Jf1Gg3tFKqB3IhAEcDXNDOlBo52ictl9z2eooiz/7Ec=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm555 $src $out/bin/tuple
    runHook postInstall
  '';

  meta = with lib; {
    description = "Tuple remote pair programming client";
    homepage = "https://tuple.app";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    maintainers = with maintainers; [ klden ];
    platforms = [ "x86_64-linux" ];
  };
}
