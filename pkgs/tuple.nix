{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "tuple";
  version = "v2026_02_19.0";

  src = fetchurl {
    url = "https://tuple-client-releases.s3.amazonaws.com/linux/${version}/x86_64/tuple";
    hash = "sha256-pC+Tz6zWMGSUBQzI1a3Lo5VmBU4i4v0YgIkElUJ59qs=";
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
