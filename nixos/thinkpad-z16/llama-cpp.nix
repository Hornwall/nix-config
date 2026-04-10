{ inputs, pkgs }:
let
  modelPath = "/var/lib/llama.cpp/models/model.gguf";
in
{
  services.llama-cpp = {
    enable = true;
    package = pkgs.unstable.llama-cpp-rocm;
    model = modelPath;
    extraFlags = [
      "-ngl"
      "999"
    ];
  };

  systemd.services.llama-cpp.unitConfig.ConditionPathExists = modelPath;

  systemd.tmpfiles.rules = [
    "d /var/lib/llama.cpp 0755 root root -"
    "d /var/lib/llama.cpp/models 0755 root root -"
  ];

  #services.open-webui = {
  #  enable = true;
  #  environment = {
  #    ENABLE_WEB_SEARCH              = "True";
  #    ENABLE_SEARCH_QUERY_GENERATION = "True";
  #    WEB_SEARCH_ENGINE              = "duckduckgo";
  #  };
  #};
}
