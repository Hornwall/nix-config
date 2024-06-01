{
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    environmentVariables = {
      HSA_OVERRIDE_GFX_VERSION = "9.0.0";
    };
  };
}
