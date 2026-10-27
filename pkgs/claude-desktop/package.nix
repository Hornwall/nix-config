{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  asar,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libcap_ng,
  libdrm,
  libgbm,
  libGL,
  libnotify,
  libappindicator-gtk3,
  libpulseaudio,
  libseccomp,
  libsecret,
  libuuid,
  libxkbcommon,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  wayland,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxtst,
  bubblewrap,
  socat,
  openssh,
  xdg-utils,
  claude-code,
}:

let
  pname = "claude-desktop";
  manifest = lib.importJSON ./manifest.json;
  inherit (manifest) version;

  source =
    manifest.platforms.${stdenv.hostPlatform.system}
      or (throw "${pname}: unsupported system ${stdenv.hostPlatform.system}");

  # Libraries Electron dlopens at runtime rather than linking against.
  runtimeLibs = [
    (lib.getLib systemd)
    libGL
    libnotify
    libappindicator-gtk3
    libpulseaudio
    libsecret
    pipewire
    wayland
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    inherit (source) url sha256;
  };

  nativeBuildInputs = [
    dpkg
    asar
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libcap_ng
    libdrm
    libgbm
    libseccomp
    libuuid
    libxkbcommon
    nspr
    nss
    pango
    pipewire
    stdenv.cc.cc.lib
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxtst
    libxcb
  ];

  runtimeDependencies = runtimeLibs;

  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib
    cp -a usr/lib/claude-desktop $out/lib/
    cp -a usr/share $out/share
    rm -rf $out/share/lintian

    # Chromium's setuid sandbox can't work from the Nix store; rely on the
    # user namespace sandbox instead.
    rm $out/lib/claude-desktop/chrome-sandbox

    # The app downloads a generic Linux build of Claude Code, which can't run
    # on NixOS. Its CLAUDE_CODE_LOCAL_BINARY override is compiled out of
    # release builds, so wire it back up and point it at our claude-code.
    resources=$out/lib/claude-desktop/resources
    asar extract $resources/app.asar app
    ccdChunk=$(grep -rlF 'process.env.CLAUDE_CODE_LOCAL_BINARY}async initLocalBinary' app/.vite/build)
    substituteInPlace "$ccdChunk" --replace-fail \
      'process.env.CLAUDE_CODE_LOCAL_BINARY}async initLocalBinary' \
      'process.env.CLAUDE_CODE_LOCAL_BINARY&&(this.localBinaryInitPromise=this.initLocalBinary(process.env.CLAUDE_CODE_LOCAL_BINARY))}async initLocalBinary'
    rm -r $resources/app.asar $resources/app.asar.unpacked
    asar pack app $resources/app.asar --unpack '{*.node,github-mcp-server}'

    substituteInPlace $out/share/applications/com.anthropic.Claude.desktop \
      --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [ bubblewrap socat openssh xdg-utils ]} \
      --set-default CLAUDE_CODE_LOCAL_BINARY ${lib.getExe claude-code} \
      --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true"
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Desktop application for Claude.ai";
    homepage = "https://code.claude.com/docs/en/desktop-linux";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = builtins.attrNames manifest.platforms;
    mainProgram = "claude-desktop";
  };
}
