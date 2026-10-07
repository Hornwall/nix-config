{
  lib,
  stdenv,
  fetchurl,
  runCommand,
  appimageTools,
  autoPatchelfHook,
  makeWrapper,
  gzip,
  gnutar,
  coreutils,
  util-linux,
  systemd,
  psmisc,
  zenity,
  xdg-utils,
  xz,
  libselinux,
  wayland,
  webkitgtk_4_1,
  gtk3,
  cairo,
  gdk-pixbuf,
  libsoup_3,
  glib,
  dbus,
  pcsclite,
  pam,
  tpm2-abrmd,
}:

let
  pname = "beyond-identity";
  version = "3.0.0-23";

  installer = fetchurl {
    url = "https://downloads.byndid.com/linux/run/production/${pname}-${version}-x86_64.run";
    hash = "sha256-d7LOeEdSeGzUMDHpA6lvSouvxOEa3fTcYON7XT6e4To=";
  };

  # The early-access Linux release is a makeself archive containing an
  # AppImage. Extract both layers so the application can run directly from the
  # Nix store without FUSE or an FHS sandbox. The webserver needs an unobscured
  # /proc to validate browser clients, which an FHS sandbox would prevent.
  appImage = runCommand "${pname}-${version}.AppImage" {
    nativeBuildInputs = [ gzip gnutar ];
  } ''
    mkdir payload
    sh ${installer} --noexec --target payload
    cp payload/beyond-identity.AppImage $out
  '';

  appImageContents = appimageTools.extract {
    inherit pname version;
    src = appImage;
  };

  runtimePath = lib.makeBinPath [
    coreutils
    util-linux
    systemd
    psmisc
    zenity
    xdg-utils
  ];
  # The bundled tctildr loads this transport by soname at runtime.
  tpmLibraryPath = lib.makeLibraryPath [ tpm2-abrmd ];
in
stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    xz
    libselinux
    wayland
    webkitgtk_4_1
    gtk3
    cairo
    gdk-pixbuf
    libsoup_3
    glib
    dbus
    pcsclite
    pam
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    appDir=$out/opt/beyond-identity
    mkdir -p "$appDir" $out/bin $out/share/applications \
      $out/share/icons/hicolor/256x256/apps $out/lib/systemd/user
    cp -a ${appImageContents}/. "$appDir/"
    chmod -R u+w "$appDir"

    for command in beyond-identity bi-cli gpg-bi bi-webserver bi-commit-sign bi-configure; do
      makeWrapper "$appDir/usr/bin/beyond-identity" "$out/bin/$command" \
        --argv0 "$command" \
        --prefix PATH : "$appDir/usr/bin:${runtimePath}" \
        --prefix LD_LIBRARY_PATH : "${tpmLibraryPath}"
    done

    install -Dm644 "$appDir/beyond-identity.desktop" \
      $out/share/applications/com.beyondidentity.endpoint.BeyondIdentity.desktop
    substituteInPlace \
      $out/share/applications/com.beyondidentity.endpoint.BeyondIdentity.desktop \
      --replace-fail "Exec=beyond-identity" "Exec=$out/bin/beyond-identity"

    install -Dm644 "$appDir/beyondidentity.png" \
      $out/share/icons/hicolor/256x256/apps/beyondidentity.png

    cat > $out/lib/systemd/user/beyond-identity-webserver.service <<EOF
    [Unit]
    # Version: ${version}
    Description=Beyond Identity Web Server
    After=network.target graphical-session.target

    [Service]
    Type=simple
    PIDFile=%t/beyond-identity-webserver/webserver.pid
    ExecStart=$out/bin/bi-webserver
    ExecReload=${coreutils}/bin/kill -HUP \$MAINPID
    Restart=on-failure
    RestartSec=5
    TimeoutStopSec=10
    KillMode=process
    ProtectProc=default
    ProcSubset=all
    StandardOutput=journal
    StandardError=journal
    SyslogIdentifier=beyond-identity-webserver

    [Install]
    WantedBy=default.target
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Passwordless MFA identities for workforces, customers, and developers";
    homepage = "https://www.beyondidentity.com";
    downloadPage = "https://app.byndid.com/downloads";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    maintainers = with maintainers; [ klden ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "beyond-identity";
  };
}
