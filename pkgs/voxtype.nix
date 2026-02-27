{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, nix-update-script
, git
, cmake
, clang
, pkg-config
, makeBinaryWrapper
, installShellFiles
, libclang
, alsa-lib
, openssl
, wtype
, dotool
, xdotool
, xclip
, wl-clipboard
, libnotify
, pciutils
, installManPages ? stdenv.buildPlatform.canExecute stdenv.hostPlatform
, installShellCompletions ? stdenv.buildPlatform.canExecute stdenv.hostPlatform
, vulkanSupport ? false
, shaderc
, vulkan-headers
, vulkan-loader
, rocmSupport ? false
, rocmPackages ? null
, cudaSupport ? false
, cudaPackages ? null
, onnxSupport ? false
, onnxruntime
, waylandSupport ? stdenv.hostPlatform.isLinux
, waylandRuntimePackages ? [
    wtype
    dotool
    wl-clipboard
  ]
, x11Support ? stdenv.hostPlatform.isLinux
, x11RuntimePackages ? [
    xdotool
    xclip
  ]
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "voxtype";
  version = "0.6.3";

  src = fetchFromGitHub {
    owner = "peteonrails";
    repo = "voxtype";
    tag = "v${finalAttrs.version}";
    hash = "sha256-2YYHwiTJVD8kDccMvZe0wsKfWw+C2B0qSDAqT3ze8Mg=";
  };

  cargoHash = "sha256-l0GibrwJfDfJmoPFggeTJbDyW2Bg3XLzG7eX3BbHVUs=";

  buildFeatures =
    [ ]
    ++ lib.optionals vulkanSupport [ "gpu-vulkan" ]
    ++ lib.optionals rocmSupport [ "gpu-hipblas" ]
    ++ lib.optionals cudaSupport [ "gpu-cuda" ]
    ++ lib.optionals onnxSupport [
      "parakeet-load-dynamic"
      "moonshine"
      "sensevoice"
      "paraformer"
      "dolphin"
      "omnilingual"
    ]
    ++ lib.optionals (onnxSupport && cudaSupport) [
      "parakeet-cuda"
      "moonshine-cuda"
      "sensevoice-cuda"
      "paraformer-cuda"
      "dolphin-cuda"
      "omnilingual-cuda"
    ];

  nativeBuildInputs = [
    git
    cmake
    clang
    pkg-config
    installShellFiles
    makeBinaryWrapper
  ]
  ++ lib.optionals vulkanSupport [
    shaderc
    vulkan-headers
    vulkan-loader
  ]
  ++ lib.optionals rocmSupport (with rocmPackages; [
    clr
    hipblas
    rocblas
  ])
  ++ lib.optionals cudaSupport (with cudaPackages; [
    cuda_nvcc
  ]);

  buildInputs = [
    openssl
    alsa-lib
  ]
  ++ lib.optionals vulkanSupport [
    vulkan-headers
    vulkan-loader
  ]
  ++ lib.optionals rocmSupport (with rocmPackages; [
    clr
    hipblas
    rocblas
  ])
  ++ lib.optionals cudaSupport (with cudaPackages; [
    cuda_nvcc
    cudatoolkit
    cudnn
  ])
  ++ lib.optionals onnxSupport [
    onnxruntime
  ];

  env = {
    LIBCLANG_PATH = "${lib.getLib libclang}/lib";
    RUSTFLAGS = lib.optionalString (stdenv.hostPlatform.system == "x86_64-linux") "-C target-cpu=x86-64-v3";
  };

  preBuild = ''
    export CMAKE_BUILD_PARALLEL_LEVEL=$NIX_BUILD_CORES
  ''
  + lib.optionalString vulkanSupport ''
    export VULKAN_SDK="${shaderc.bin}"
  ''
  + lib.optionalString rocmSupport ''
    export HIP_PATH="${rocmPackages.clr}"
    export ROCM_PATH="${rocmPackages.clr}"
  ''
  + lib.optionalString cudaSupport ''
    export CUDA_PATH="${cudaPackages.cudatoolkit}"
  ''
  + lib.optionalString onnxSupport ''
    export ORT_LIB_LOCATION="${lib.getLib onnxruntime}/lib"
  '';

  postInstall =
    ''
      install -Dm644 config/default.toml \
        $out/share/voxtype/default-config.toml

      wrapProgram $out/bin/voxtype \
        --prefix PATH : ${
          lib.makeBinPath (
            [
              libnotify
            ]
            ++ lib.optionals vulkanSupport [
              pciutils
            ]
            ++ lib.optionals rocmSupport [
              pciutils
            ]
            ++ lib.optionals cudaSupport [
              pciutils
            ]
            ++ lib.optionals waylandSupport waylandRuntimePackages
            ++ lib.optionals x11Support x11RuntimePackages
          )
        }
    ''
    + lib.optionalString onnxSupport ''
      wrapProgram $out/bin/voxtype \
        --set ORT_DYLIB_PATH "${lib.getLib onnxruntime}/lib/libonnxruntime.so" \
        --prefix LD_LIBRARY_PATH : "${lib.getLib onnxruntime}/lib"
    ''
  + lib.optionalString installManPages ''
    installManPage target/debug/build/voxtype-*/out/man/*
  ''
  + lib.optionalString installShellCompletions ''
    installShellCompletion packaging/completions/voxtype.{bash,zsh,fish}
  '';

  passthru.update-script = nix-update-script { };

  meta = {
    description = "Voice-to-text with push-to-talk for Wayland compositors";
    longDescription = ''
      Voxtype is a push-to-talk voice-to-text daemon for Linux.
      Hold a hotkey while speaking, release to transcribe and output
      text at your cursor position. Supports Whisper, Parakeet,
      SenseVoice, Moonshine, Paraformer, Dolphin, and Omnilingual engines.
    '';
    homepage = "https://voxtype.io";
    downloadPage = "https://voxtype.io/download/";
    changelog = "https://github.com/peteonrails/voxtype/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "voxtype";
  };
})
