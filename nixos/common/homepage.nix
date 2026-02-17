{
  virtualisation.oci-containers = {
    backend = "docker";
    containers.homepage = {
      ports = [
        "3002:3000"
      ];
      volumes = [ "/home/hannes/.config/homepage:/config" ];
      environment.TZ = "Europe/Stockholm";
      image = "ghcr.io/gethomepage/homepage:v0.9.3";
    };
  };
}
