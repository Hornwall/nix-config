{
  networking.extraHosts =
  ''
    127.0.0.1 app.aboardhr.localhost
    127.0.0.1 app.aboardhr.test
    127.0.0.1 whistle.aboardhr.localhost
    127.0.0.1 whistle.aboardhr.test
    127.0.0.1 teamtailor-livereload.localhost
    127.0.0.1 teamtailor-ember.localhost
    127.0.0.1 *.teamtailor.localhost
  '';

  security.pki.certificates=[''
  -----BEGIN CERTIFICATE-----
  MIIGLzCCBBegAwIBAgIUM4gnYIJ75rrDMTg0rOxUkRo0JCkwDQYJKoZIhvcNAQEL
  BQAwgaYxCzAJBgNVBAYTAlNFMRIwEAYDVQQIDAlTdG9ja2hvbG0xEjAQBgNVBAcM
  CVN0b2NraG9sbTETMBEGA1UECgwKVGVhbXRhaWxvcjEMMAoGA1UECwwDZGV2MR0w
  GwYDVQQDDBQqLmFib2FyZGhyLmxvY2FsaG9zdDEtMCsGCSqGSIb3DQEJARYeaGFu
  bmVzLmhvcm53YWxsQHRlYW10YWlsb3IuY29tMB4XDTI0MDUwMzA5NDAzMFoXDTI1
  MDUwMzA5NDAzMFowgaYxCzAJBgNVBAYTAlNFMRIwEAYDVQQIDAlTdG9ja2hvbG0x
  EjAQBgNVBAcMCVN0b2NraG9sbTETMBEGA1UECgwKVGVhbXRhaWxvcjEMMAoGA1UE
  CwwDZGV2MR0wGwYDVQQDDBQqLmFib2FyZGhyLmxvY2FsaG9zdDEtMCsGCSqGSIb3
  DQEJARYeaGFubmVzLmhvcm53YWxsQHRlYW10YWlsb3IuY29tMIICIjANBgkqhkiG
  9w0BAQEFAAOCAg8AMIICCgKCAgEAnhhL0JO7de4u5XT1G4yB4oVAC+FKB8W/Zpls
  vqPEH0IlBIIVhU3VR7o1/2HNAklz/x/4BHAtq29wjfPkXxKXOXRC+1gmevTMuZ4y
  c44kc/0s17eHUV96CNv+W1dX/ZlhaV6hbc85l19laWo84xsL4XN0EWQyg0xYWJa2
  tD3JE+S3B+WTGUpUG6a48rUKdninMECJ/jBVCt9nCeche9r5SDgrrMCTH/5H1jR+
  XH8Y5tKa00kSwNE6FKmWisfjJzsHYqHYrC59ZF2AsSmyAziLM7vn+DZVDwuWz5pA
  OjUSZNM21e0r4hHT9JdnrCCYBGiozVMsSnEpl8IS2PwTfw2wXeqUjPEM8XHzDh/H
  vESuKSew5QT6npqcyUdpzIGb9eARUyS6m7WDg6lM4Fgbxc4nTcnI59mtxQ0oTLy3
  u3yrdYeVEsxwPgC79Fjf0N6FMhkG+e5+GGbXxSPWgEPpj88qf7BAQqa921q17P+K
  yg/+dhdqyRWoTPb6B7V8f4MgbKpNEcBUIpHupRGH5fZ7/aysR4DIO8ReJRHOi90B
  qnDFoAHyWx/drC/NYC5pqRmBUTCSNir3aBtwdyhHeSfA/KtYVHm4sry1WXN+HEvA
  kIo7jEqwNMWNHPpf0kKyz6+1jv4tmK5wTpWn8WD9w1fJd4YOf/9kHmuGOIS7+5no
  fsN3FD0CAwEAAaNTMFEwHQYDVR0OBBYEFILax3All3Zf+60cno5dqneODxSTMB8G
  A1UdIwQYMBaAFILax3All3Zf+60cno5dqneODxSTMA8GA1UdEwEB/wQFMAMBAf8w
  DQYJKoZIhvcNAQELBQADggIBADJr5Gs3QApKflwERYh45yAChRd4EqDqzeWRFuCR
  TmgxstG2YY6j01biaxEtA7djJl4kTO4bSP0499I9vxIrYy1dDLnRRH7rY7l9rP4N
  XyDbbH7vRQrPYfBj463gkT341SPrjSdDpJ0/QWJYvILx7LD2xb74ZT+frw6BfV4r
  /4pZ66DqZgJ4H/zQCOtiDmyBKJGlCvc6QApSGk96xwEX4GA9k0q2PeTpvuCmdI0J
  K6PAAHmG6vBF7c+rOpx8xMRPttOKBuHO6LM/qOSfXlDusZ8CfLZiGZIoKdyX8iMR
  Ro40LZQQ17CgSlliQlO9eWZXwULoMGN4cH3V0EDNARChMezQ+OW3vYWHDBphFFAp
  JKdm57/odmmPSm+MS4FCf3aQnbFkcGcWfixcdZlyCNmY9iSbiheuQY44Bzk19YiU
  cNG/Y6zDvJpVngj/Pas6v790TueLI3lT6UGIoNfN8ERTHXYCG7jam4hTni82/XnH
  OX0hbXj2bFXuJoqxUOswLnbeRa0G90VI3GnLPtrQPb9vtkS8eJ567w+RegkWxq3W
  ssrl27iMPg8MyGjE/ow6SXPXKjMqRctvHSJNroAqy12A1JHYw6NnbKymINEXj5oY
  D7cxxCoMkhnH8awai2qbrFTX7XJlryWVuNkPZM6qXdjtdQSAd0C0uALzVMNLkFj0
  qzwO
  -----END CERTIFICATE-----
  ''];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "100M";

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
    virtualHosts."accounts.aboardhr.localhost" = {
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
        proxyPass = "http://localhost:3003/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."accounts.teamtailor.localhost" = {
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
        proxyPass = "http://localhost:3003/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."api.aboardhr.localhost" = {
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
    virtualHosts."teamtailor-livereload.localhost" = {
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
        proxyPass = "http://localhost:1337/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."tt.teamtailor.localhost" = {
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
        proxyPass = "http://localhost:5500/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."app.teamtailor.localhost" = {
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
        proxyPass = "http://localhost:5500/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."api.teamtailor.localhost" = {
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
        proxyPass = "http://localhost:5500/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."www.teamtailor-ember.localhost" = {
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
        proxyPass = "http://localhost:4200/";
        proxyWebsockets = true;
      };
    };
    virtualHosts."teamtailor-ember.localhost" = {
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
        proxyPass = "http://localhost:4200/";
        proxyWebsockets = true;
      };
    };
  };
}
