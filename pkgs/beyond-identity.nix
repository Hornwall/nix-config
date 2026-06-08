{ lib, stdenv, fetchurl, dpkg, buildFHSEnv, runCommand, makeWrapper, util-linux
, glibc, glib, openssl, tpm2-tss
, gtk3, gnome-keyring, polkit, polkit_gnome
, webkitgtk_4_1, libsoup_3, cairo, gdk-pixbuf, xz
}:

let
  pname = "beyond-identity";
  version = "2.111.0-4";
  libPath = lib.makeLibraryPath ([
    glib glibc openssl tpm2-tss gtk3 gnome-keyring polkit polkit_gnome
    webkitgtk_4_1 libsoup_3 cairo gdk-pixbuf xz
  ]);
  meta = with lib; {
    description = "Passwordless MFA identities for workforces, customers, and developers";
    homepage = "https://www.beyondidentity.com";
    downloadPage = "https://app.byndid.com/downloads";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    maintainers = with maintainers; [ klden ];
    platforms = [ "x86_64-linux" ];
  };

  beyond-identity = stdenv.mkDerivation {
    inherit pname version meta;

    src = fetchurl {
      url = "https://packages.beyondidentity.com/public/linux-authenticator/deb/ubuntu/pool/jammy/main/b/be/${pname}_${version}/${pname}_${version}_amd64.deb";
      hash = "sha512-OqMDv2zW7mjnBeU4cRxrdRsTVvsMXHh7h1ZaYuYZ7t6Ul84wuCfzoMMIa9WNHi9Y12HdLt+eG4G2xac+GwG0eg==";
    };

    nativeBuildInputs = [
      dpkg
    ];

    unpackPhase = ''
      dpkg -x $src .
    '';

    installPhase = ''
      rm -rf usr/share/doc

      mkdir -p $out/opt/beyond-identity
      cp -ar opt/beyond-identity/{bin,etc,lib,share} $out/opt/beyond-identity

      cp -ar usr/share $out

      # Register the TPM2 user-key polkit action system-wide. byndid's crypto
      # provider ("policy manager") calls pkcheck on org.tpm2.UserKeyAccess.*;
      # without the action registered it fails with "Failed to initialize policy
      # manager". The deb's postinst copies these into the system polkit dirs;
      # on NixOS, actions under share/polkit-1/actions are discovered from
      # systemPackages, and the rules file from share/polkit-1/rules.d.
      install -Dm644 opt/beyond-identity/share/polkit/org.tpm2.UserKeyAccess.policy \
        $out/share/polkit-1/actions/org.tpm2.UserKeyAccess.policy
      install -Dm644 opt/beyond-identity/share/polkit/50-tpm2-user-keys.rules \
        $out/share/polkit-1/rules.d/50-tpm2-user-keys.rules

      mkdir -p $out/lib/systemd/user
      cp -ar usr/lib/systemd/user/* $out/lib/systemd/user/

      mkdir -p $out/bin
      ln -s $out/opt/beyond-identity/bin/* $out/bin/
    '';

    postFixup = ''
      substituteInPlace \
        $out/share/applications/com.beyondidentity.endpoint.BeyondIdentity.desktop \
        --replace /opt/ $out/opt/
      substituteInPlace \
        $out/lib/systemd/user/beyond-identity-webserver.service \
        --replace /opt/ $out/opt/
      substituteInPlace \
        $out/opt/beyond-identity/bin/beyond-identity \
        --replace /opt/ $out/opt/
      substituteInPlace \
        $out/opt/beyond-identity/bin/gpg-bi \
        --replace /opt/ $out/opt/

      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "$out/opt/beyond-identity/lib:${libPath}" \
        --force-rpath \
        $out/opt/beyond-identity/bin/byndid
    '';
  };
# /usr/bin/pkcheck is hardcoded in binary - we need FHS
  fhsEnv = buildFHSEnv {
     inherit meta;
     name = "beyond-identity-fhs";

     targetPkgs = pkgs: [
       beyond-identity
       glib glibc openssl tpm2-tss
       gtk3 gnome-keyring
       polkit polkit_gnome
       webkitgtk_4_1 libsoup_3 cairo gdk-pixbuf xz
     ];

     extraInstallCommands = ''
       ln -s ${beyond-identity}/share $out
     '';

     runScript = "beyond-identity";
  };
# The FHS launcher is itself bwrap. When invoked from a shell that carries an
# ambient capability (e.g. ghostty leaks ambient CAP_SYS_NICE), bwrap aborts with
# "Unexpected capabilities but not setuid". Clear the ambient set before bwrap runs.
in runCommand pname {
  inherit meta;
  nativeBuildInputs = [ makeWrapper ];
} ''
  mkdir -p $out/bin
  makeWrapper ${util-linux}/bin/setpriv $out/bin/${pname} \
    --add-flags "--ambient-caps -all ${fhsEnv}/bin/beyond-identity-fhs"
  ln -s ${beyond-identity}/share $out/share
''
