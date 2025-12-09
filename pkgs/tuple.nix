{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "tuple";
  version = "v2025_12_02.0";

  src = fetchurl {
    url = "https://tuple-client-releases.s3.amazonaws.com/linux/${version}/x64/tuple";
    hash = "sha256-9fsXySb3wPOB5u+58ZuUbQIxf4HYh/54SAHKud8Oi/U=";
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
