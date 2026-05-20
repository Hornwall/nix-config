{ inputs, pkgs }:
{
  services.ollama = {
    enable = true;
    package = pkgs.unstable.ollama-rocm;
    acceleration = "rocm";
    environmentVariables = {
      HCC_AMDGPU_TARGET = "gfx1103"; # used to be necessary, but doesn't seem to anymore
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_KEEP_ALIVE = "5m";
    };
    rocmOverrideGfx = "11.0.2";
  };

  # Keep ollama from taking the whole machine down with it.
  # The 780M iGPU shares system RAM via GTT, so a runaway model can OOM the
  # desktop. Cap ollama's cgroup and make it the preferred OOM victim.
  systemd.services.ollama.serviceConfig = {
    MemoryHigh = "32G";
    MemoryMax = "40G";
    OOMScoreAdjust = 500;
  };

  services.open-webui.enable = true;

  #services.open-webui = {
  #  enable = true;
  #  environment = {
  #    ENABLE_WEB_SEARCH              = "True";
  #    ENABLE_SEARCH_QUERY_GENERATION = "True";
  #    WEB_SEARCH_ENGINE              = "duckduckgo";
  #  };
  #};
}
