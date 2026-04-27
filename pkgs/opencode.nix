{ lib
, stdenvNoCC
, bun
, fetchFromGitHub
, makeBinaryWrapper
, models-dev
, nodejs
, nix-update-script
, opencodeSrc ? null
, ripgrep
, sysctl
, installShellFiles
, versionCheckHook
, writableTmpDirAsHomeHook
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode";
  version = "dev";
  src = if opencodeSrc != null then opencodeSrc else fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    rev = "61eabfc60c1005d1b2b11849d70696a3dcef293e";
    hash = "sha256-D53S1bqrt1JoUDK0vU2+yxJdlCigBQrkaj2SeOcsw1U=";
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${finalAttrs.pname}-node_modules";
    inherit (finalAttrs) version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      bun install \
        --cpu="*" \
        --frozen-lockfile \
        --filter ./ \
        --filter ./packages/app \
        --filter ./packages/opencode \
        --filter ./packages/desktop \
        --filter ./packages/shared \
        --ignore-scripts \
        --no-progress \
        --os="*"

      bun --bun ./nix/scripts/canonicalize-node-modules.ts
      bun --bun ./nix/scripts/normalize-bun-binaries.ts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      find . -type d -name node_modules -exec cp -R --parents {} $out \;

      runHook postInstall
    '';

    # Required or the fixed-output derivation ends up referencing store paths.
    dontFixup = true;

    outputHash = "sha256-shMfcEeS4T/gUKILrXmFTnXISg4CcL682YniuaNlb2I=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    bun
    nodejs
    installShellFiles
    makeBinaryWrapper
    models-dev
    writableTmpDirAsHomeHook
  ];

  postPatch = ''
    substituteInPlace packages/script/src/index.ts \
      --replace-fail 'throw new Error(`This script requires bun@''${expectedBunVersionRange}' \
                     'console.warn(`Warning: This script requires bun@''${expectedBunVersionRange}'
  '';

  configurePhase = ''
    runHook preConfigure

    cp -R ${finalAttrs.node_modules}/. .
    patchShebangs node_modules
    patchShebangs packages/*/node_modules

    runHook postConfigure
  '';

  env.MODELS_DEV_API_JSON = "${models-dev}/dist/_api.json";
  env.OPENCODE_DISABLE_MODELS_FETCH = true;
  env.OPENCODE_VERSION = finalAttrs.version;
  env.OPENCODE_CHANNEL = "dev";

  buildPhase = ''
    runHook preBuild

    cd ./packages/opencode
    bun --bun ./script/build.ts --single --skip-install
    bun --bun ./script/schema.ts config.json tui.json

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 dist/opencode-*/bin/opencode $out/bin/opencode
    wrapProgram $out/bin/opencode \
     --prefix PATH : ${
       lib.makeBinPath (
         [
           ripgrep
         ]
         ++ lib.optionals stdenvNoCC.hostPlatform.isDarwin [
           sysctl
         ]
       )
     }

    install -Dm644 config.json $out/share/opencode/config.json
    install -Dm644 tui.json $out/share/opencode/tui.json

    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
    installShellCompletion --cmd opencode \
      --bash <($out/bin/opencode completion) \
      --zsh <(SHELL=/bin/zsh $out/bin/opencode completion)
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  doInstallCheck = true;
  versionCheckKeepEnvironment = [
    "HOME"
    "OPENCODE_DISABLE_MODELS_FETCH"
  ];
  versionCheckProgramArg = "--version";

  passthru = {
    jsonschema = {
      config = "${placeholder "out"}/share/opencode/config.json";
      tui = "${placeholder "out"}/share/opencode/tui.json";
    };
    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "node_modules"
      ];
    };
  };

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://github.com/anomalyco/opencode";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      delafthi
      DuskyElf
      graham33
      superherointj
    ];
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    mainProgram = "opencode";
    badPlatforms = [
      # Broken as 2026-04-23: CPU lacks AVX support, strange crashes may occur.
      "x86_64-darwin"
    ];
  };
})
