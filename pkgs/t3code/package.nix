{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "t3code";
  manifest = lib.importJSON ./manifest.json;
  inherit (manifest) version;

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    inherit (manifest) hash;
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/t3code.desktop $out/share/applications/t3code.desktop
    substituteInPlace $out/share/applications/t3code.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'
    install -Dm444 ${appimageContents}/t3code.png $out/share/icons/hicolor/512x512/apps/t3code.png
  '';

  meta = {
    description = "Open-source desktop app for coding agents";
    homepage = "https://github.com/pingdotgg/t3code";
    changelog = "https://github.com/pingdotgg/t3code/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "t3code";
    platforms = [ "x86_64-linux" ];
  };
}
