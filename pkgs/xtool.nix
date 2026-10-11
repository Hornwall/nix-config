{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
}:

let
  pname = "xtool";
  version = "1.21.0";

  sources = {
    "x86_64-linux" = {
      arch = "x86_64";
      hash = "sha256-4id+Wbsv2ptIfLx3rQgOorA3C7dArA8CzEL6KKJy06U=";
    };
    "aarch64-linux" = {
      arch = "aarch64";
      hash = "sha256-Rw1ViAN53paWoEj0KToLBaf8Q766Qj/+bClKSXXc6/c=";
    };
  };

  source = sources.${stdenv.hostPlatform.system}
    or (throw "xtool: unsupported platform ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://github.com/xtool-org/xtool/releases/download/${version}/xtool-${source.arch}.AppImage";
    inherit (source) hash;
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/xtool.desktop $out/share/applications/xtool.desktop
    install -Dm444 ${appimageContents}/xtool.png $out/share/icons/hicolor/512x512/apps/xtool.png
  '';

  meta = {
    description = "Cross-platform Xcode replacement for building and deploying iOS apps";
    homepage = "https://xtool.sh/";
    changelog = "https://github.com/xtool-org/xtool/releases/tag/${version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "xtool";
    platforms = builtins.attrNames sources;
  };
}
