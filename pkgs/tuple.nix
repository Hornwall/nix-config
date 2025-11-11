{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "tuple";
  version = "v2025_10_30.0";

  src = fetchurl {
    url = "https://tuple-client-releases.s3.amazonaws.com/linux/${version}/x64/tuple";
    sha256 = "0xqgad1fqjkm8l4fyk7hn298x5akl2rrgb7b5zaw5k3vzk2h7ylj";
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
