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
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    logError = "stderr debug";
  
    virtualHosts."app.aboardhr.localhost" = {
      addSSL = true;
      sslCertificate = "/etc/ssl/certs/cert.pem";
      sslCertificateKey = "/etc/ssl/certs/plain.key";

      extraConfig = ''
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        proxy_buffer_size   128k;
        proxy_buffers   4 256k;
        proxy_busy_buffers_size   256k;
      '';

      locations."/" = {
        proxyPass = "http://localhost:3000/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."app.aboardhr.test" = {
      addSSL = true;
      sslCertificate = "/etc/ssl/certs/cert.pem";
      sslCertificateKey = "/etc/ssl/certs/plain.key";

      extraConfig = ''
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        proxy_buffer_size   128k;
        proxy_buffers   4 256k;
        proxy_busy_buffers_size   256k;
      '';

      locations."/" = {
        proxyPass = "http://localhost:3000/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."whistle.aboardhr.localhost" = {
      addSSL = true;
      sslCertificate = "/etc/ssl/certs/cert.pem";
      sslCertificateKey = "/etc/ssl/certs/plain.key";

      extraConfig = ''
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        proxy_buffer_size   128k;
        proxy_buffers   4 256k;
        proxy_busy_buffers_size   256k;
      '';

      locations."/" = {
        proxyPass = "http://localhost:3000/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."whistle.aboardhr.test" = {
      addSSL = true;
      sslCertificate = "/etc/ssl/certs/cert.pem";
      sslCertificateKey = "/etc/ssl/certs/plain.key";

      extraConfig = ''
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        proxy_buffer_size   128k;
        proxy_buffers   4 256k;
        proxy_busy_buffers_size   256k;
      '';


      locations."/" = {
        proxyPass = "http://localhost:3000/";
        proxyWebsockets = true;
      };
    };
  };
}
