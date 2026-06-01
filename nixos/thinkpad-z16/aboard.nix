{ pkgs, lib, ... }:
let
  aboardhrWtCount = 10;

  # Worktree dev slots: app/api.aboardhr-wt<N>.localhost -> localhost:(3000 + N).
  # See the aboard repo's `aboard-devenv-env` skill, which spins envs into these.
  aboardhrWtPorts = builtins.listToAttrs (
    lib.concatMap (n: [
      { name = "app.aboardhr-wt${toString n}.localhost"; value = 3000 + n; }
      { name = "api.aboardhr-wt${toString n}.localhost"; value = 3000 + n; }
    ]) (builtins.genList (i: i + 1) aboardhrWtCount)
  );

  # Single source of truth: host -> upstream port. The TLS cert's SANs and the
  # nginx virtualHosts are both derived from this map, so they cannot drift.
  vhostPorts = {
    "app.aboardhr.localhost" = 3000;
    "accounts.aboardhr.localhost" = 3003;
    "accounts.teamtailor.localhost" = 3003;
    "api.aboardhr.localhost" = 3000;
    "app.aboardhr.test" = 3000;
    "whistle.aboardhr.localhost" = 3000;
    "whistle.aboardhr.test" = 3000;
    "teamtailor-livereload.localhost" = 1337;
    "tt.teamtailor.localhost" = 5500;
    "app.teamtailor.localhost" = 5500;
    "api.teamtailor.localhost" = 5500;
    "www.teamtailor-ember.localhost" = 4200;
    "teamtailor-ember.localhost" = 4200;
  } // aboardhrWtPorts;

  serverNames = builtins.attrNames vhostPorts;

  # Dev PKI for the proxied hosts: a local root CA (the trust anchor) plus a
  # non-CA leaf certificate -- with a SAN per proxied host (incl. the wtN slots)
  # -- that nginx serves. Browsers reject a CA cert used directly as a server
  # cert (MOZILLA_PKIX_ERROR_CA_CERT_USED_AS_END_ENTITY), hence the split.
  #
  # Outputs: ca.pem (trust this), cert.pem (leaf+CA fullchain, served), key.pem
  # (leaf key). The CA private key is never persisted to $out. Everything
  # regenerates automatically when `serverNames` changes, so bumping
  # `aboardhrWtCount` is enough. The leaf key lands in the (world-readable) nix
  # store, which is acceptable for a localhost-only development certificate.
  aboardDevCert =
    pkgs.runCommand "aboard-dev-cert" { nativeBuildInputs = [ pkgs.openssl ]; } ''
      mkdir -p $out
      dn="/C=SE/ST=Stockholm/L=Stockholm/O=Teamtailor/OU=dev"

      # Root CA (trust anchor) -- key stays in the build dir, not $out.
      openssl req -x509 -newkey rsa:4096 -nodes -days 3650 \
        -keyout ca-key.pem -out $out/ca.pem -subj "$dn/CN=Aboard dev CA" \
        -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
        -addext "keyUsage=critical,keyCertSign,cRLSign"

      # Leaf key + CSR.
      openssl req -newkey rsa:4096 -nodes \
        -keyout $out/key.pem -out leaf.csr -subj "$dn/CN=Aboard dev"

      # Sign the leaf with SANs, CA:FALSE, serverAuth.
      cat > leaf.ext <<'EOF'
      basicConstraints = critical, CA:FALSE
      keyUsage = critical, digitalSignature, keyEncipherment
      extendedKeyUsage = serverAuth
      subjectAltName = @alt
      [alt]
      ${lib.concatStringsSep "\n" (lib.imap1 (i: name: "DNS.${toString i} = ${name}") serverNames)}
      EOF
      openssl x509 -req -in leaf.csr -CA $out/ca.pem -CAkey ca-key.pem \
        -CAcreateserial -days 3650 -extfile leaf.ext -out leaf.pem

      # nginx serves the full chain (leaf then CA).
      cat leaf.pem $out/ca.pem > $out/cert.pem
    '';

  mkProxyVHost = port: {
    addSSL = true;
    sslCertificate = "${aboardDevCert}/cert.pem";
    sslCertificateKey = "${aboardDevCert}/key.pem";

    extraConfig = ''
      fastcgi_buffers 16 16k;
      fastcgi_buffer_size 32k;
      proxy_buffer_size   128k;
      proxy_buffers   4 256k;
      proxy_busy_buffers_size   256k;
    '';

    locations."/" = {
      proxyPass = "http://localhost:${toString port}/";
      proxyWebsockets = true;
    };
  };
in
{
  networking.extraHosts =
  ''
    127.0.0.1 app.aboardhr.localhost
    127.0.0.1 api.aboardhr.localhost
    127.0.0.1 *.localhost
    127.0.0.1 app.aboardhr.test
    127.0.0.1 whistle.aboardhr.localhost
    127.0.0.1 whistle.aboardhr.test
    127.0.0.1 teamtailor-livereload.localhost
    127.0.0.1 teamtailor-ember.localhost
    127.0.0.1 *.teamtailor.localhost
    ${lib.concatStringsSep "\n    " (
      map (name: "127.0.0.1 ${name}") (builtins.attrNames aboardhrWtPorts)
    )}
  '';

  # Trust the dev root CA so the proxied https hosts validate cleanly.
  # The system store covers CLI/system-OpenSSL consumers (curl, git, ruby...).
  security.pki.certificateFiles = [ "${aboardDevCert}/ca.pem" ];

  # Browsers on Linux keep their own NSS trust stores and ignore the system
  # store, so trust the cert in each of them explicitly.

  # Firefox: honor OS roots (ImportEnterpriseRoots) and pin our cert directly
  # (Install) so it validates regardless of how Linux enterprise-roots resolve.
  programs.firefox = {
    enable = true;
    package = pkgs.unstable.firefox;
    policies.Certificates = {
      ImportEnterpriseRoots = true;
      Install = [ "${aboardDevCert}/ca.pem" ];
    };
  };

  # Chromium/Chrome read ~/.pki/nssdb -- import the cert there as a trusted CA.
  system.activationScripts.aboardDevCertChromium = {
    deps = [ "users" ];
    text = ''
      db="/home/hannes/.pki/nssdb"
      ${pkgs.coreutils}/bin/mkdir -p "$db"
      ${pkgs.nss.tools}/bin/certutil -d "sql:$db" -D -n "aboard-dev" 2>/dev/null || true
      ${pkgs.nss.tools}/bin/certutil -d "sql:$db" -A -t "C,," -n "aboard-dev" -i "${aboardDevCert}/ca.pem"
      ${pkgs.coreutils}/bin/chown -R hannes:users "/home/hannes/.pki"
    '';
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "100M";

    logError = "stderr debug";
  
    virtualHosts = builtins.mapAttrs (_name: port: mkProxyVHost port) vhostPorts;
  };
}
