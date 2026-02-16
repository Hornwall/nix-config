{ inputs, pkgs }:
{
  services.ollama = {
    enable = true;
    package = pkgs.unstable.ollama-cuda;
    loadModels = [];
  };

  #services.open-webui = {
  #  enable = true;
  #  environment = {
  #    ENABLE_WEB_SEARCH              = "True";
  #    ENABLE_SEARCH_QUERY_GENERATION = "True";
  #    WEB_SEARCH_ENGINE              = "duckduckgo";
  #  };
  #};
}
