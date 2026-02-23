{ lib
, stdenv
, fetchFromGitHub
, fetchurl
, nodejs_22
, pnpm_9
, fetchPnpmDeps
, pnpmConfigHook
, patchelf
}:

let
  pnpm = pnpm_9.override { nodejs = nodejs_22; };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "agent-browser";
  version = "0.12.0";

  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-browser";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RZrHetOaq6cQ1Lnn3WztllQZrhiqZlWnVRS4qYI3k9g=";
  };

  npmSrc = fetchurl {
    url = "https://registry.npmjs.org/agent-browser/-/agent-browser-${finalAttrs.version}.tgz";
    hash = "sha256-ByAcpwZSfLN5weNsk2KsG/nlowFUkQF4r2+nNqjLesc=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 1;
    hash = "sha256-n8npEPbXRksdDG9UOVDXZbKP5k3iEbNtLsWUk3K7As8=";
  };

  nativeBuildInputs = [
    nodejs_22
    pnpmConfigHook
    pnpm
  ];

  installPhase =
    let
      binaryName = if stdenv.hostPlatform.isx86_64 then "agent-browser-linux-x64" else "agent-browser-linux-arm64";
      nativeBinary = fetchurl {
        url = "https://github.com/vercel-labs/agent-browser/releases/download/v${finalAttrs.version}/${binaryName}";
        hash = if stdenv.hostPlatform.isx86_64 then
          "sha256-QHM7kuhNAqZ39W1Il7UzeyoQikofay5BbU6Vxxn1mqY="
        else
          "sha256-ceQssF9iJX+dOrHsFlT0wCI3vcnS80fItB0E8IOkQkc=";
      };
    in
    ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/node_modules/agent-browser
      tar -xzf ${finalAttrs.npmSrc} -C $out/lib/node_modules/agent-browser --strip-components=1 \
        package/bin \
        package/dist \
        package/package.json \
        package/skills

      cp -r node_modules $out/lib/node_modules/agent-browser/

      install -Dm755 ${nativeBinary} "$out/lib/node_modules/agent-browser/bin/${binaryName}"
      ${patchelf}/bin/patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        "$out/lib/node_modules/agent-browser/bin/${binaryName}"

      patchShebangs $out/lib/node_modules/agent-browser/bin/agent-browser.js
      ln -s ../lib/node_modules/agent-browser/bin/agent-browser.js $out/bin/agent-browser

      runHook postInstall
    '';

  meta = {
    description = "Headless browser automation CLI for AI agents";
    homepage = "https://agent-browser.dev";
    license = lib.licenses.asl20;
    mainProgram = "agent-browser";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
})
