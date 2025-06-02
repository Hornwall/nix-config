{
  services.ollama = {
    enable = true;
    loadModels = ["llama3.2:3b"];
    acceleration = "rocm";
    environmentVariables = {
      HCC_AMDGPU_TARGET = "gfx1103"; # used to be necessary, but doesn't seem to anymore
    };
    rocmOverrideGfx = "11.0.2";
  };

  services.open-webui = {
    enable = true;
    environment = {
      ENABLE_WEB_SEARCH              = "True";
      ENABLE_SEARCH_QUERY_GENERATION = "True";
      WEB_SEARCH_ENGINE              = "duckduckgo";
    };
  };
}
