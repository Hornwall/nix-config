{
  networking.extraHosts =
  ''
    127.0.0.1 app.aboardhr.localhost
    127.0.0.1 app.aboardhr.test
    127.0.0.1 whistle.aboardhr.localhost
    127.0.0.1 whistle.aboardhr.test
  '';


  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  
    virtualHosts."app.aboardhr.localhost" = {
      addSSL = true;
      sslCertificate = "/etc/ssl/certs/cert.pem";
      sslCertificateKey = "/etc/ssl/certs/plain.key";

      locations."/" = {
        proxyPass = "http://localhost:3000/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."app.aboardhr.test" = {
      addSSL = true;
      sslCertificate = "/etc/ssl/certs/cert.pem";
      sslCertificateKey = "/etc/ssl/certs/plain.key";

      locations."/" = {
        proxyPass = "http://localhost:3000/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."whistle.aboardhr.localhost" = {
      addSSL = true;
      sslCertificate = "/etc/ssl/certs/cert.pem";
      sslCertificateKey = "/etc/ssl/certs/plain.key";

      locations."/" = {
        proxyPass = "http://localhost:3000/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."whistle.aboardhr.test" = {
      addSSL = true;
      sslCertificate = "/etc/ssl/certs/cert.pem";
      sslCertificateKey = "/etc/ssl/certs/plain.key";

      locations."/" = {
        proxyPass = "http://localhost:3000/";
        proxyWebsockets = true;
      };
    };
  };
}
