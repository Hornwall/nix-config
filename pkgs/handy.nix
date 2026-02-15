{ lib
, fetchurl
, appimageTools
}:

let
  pname = "handy";
  version = "0.6.7";

  src = fetchurl {
    url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_amd64.AppImage";
    hash = "sha256-5PrDpV93cJ4tGZzRlLYBGvp3uvCjPjuBgjoL1nQsD/s=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/Handy.desktop \
      $out/share/applications/Handy.desktop
    install -m 444 -D ${appimageContents}/handy.png \
      $out/share/icons/hicolor/512x512/apps/handy.png
  '';

  meta = with lib; {
    description = "Offline speech-to-text application";
    longDescription = "A free, open source, and extensible speech-to-text application that works completely offline.";
    homepage = "https://handy.computer";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    mainProgram = "handy";
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ ];
  };
}

