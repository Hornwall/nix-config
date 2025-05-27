{
  services.ollama = {
    enable = true;
    loadModels = ["llama3.2:3b"];
    acceleration = "rocm";
    environmentVariables = {
      HCC_AMDGPU_TARGET = "gfx1034"; # used to be necessary, but doesn't seem to anymore
    };
    # results in environment variable "HSA_OVERRIDE_GFX_VERSION=10.3.0"
    rocmOverrideGfx = "10.3.0";
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
