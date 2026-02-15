{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "tuple";
  version = "v2026_01_09.0";

  src = fetchurl {
    url = "https://tuple-client-releases.s3.amazonaws.com/linux/${version}/x64/tuple";
    hash = "sha256-E5a+YmR27kgpRozo7afPz+yqORb7O7qaC7kHxHKWtgg=";
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
