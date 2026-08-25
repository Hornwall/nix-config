{
  lib,
  fetchFromGitHub,
  buildGoModule,
  installShellFiles,
  stdenv,
  versionCheckHook,
  makeWrapper,
}:

buildGoModule (finalAttrs: {
  pname = "gh";
  version = "2.98.0-pr.14200";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "cli";
    repo = "cli";
    rev = "cd94f8cdffd710b41fa16df39680ee6f75069ecd";
    hash = "sha256-LXI8mOHD2Nmf1VUs13VS/hS2w1QIyB9Hb2pjq2cXjVs=";
  };

  vendorHash = "sha256-QT4a1ZCT4UVnUeBTSK71uvFx4elZ3Dan+KFOiUwWWlM=";

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild
    make GO_LDFLAGS="-s -w -X github.com/cli/cli/v${lib.versions.major finalAttrs.version}/internal/build.Date=nixpkgs" GH_VERSION=${finalAttrs.version} bin/gh ${lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) "manpages"}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    installBin bin/gh
    wrapProgram $out/bin/gh \
      --set-default GH_TELEMETRY false
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installManPage share/man/*/*.[1-9]

    installShellCompletion --cmd gh \
      --bash <($out/bin/gh completion -s bash) \
      --fish <($out/bin/gh completion -s fish) \
      --zsh <($out/bin/gh completion -s zsh)
  ''
  + ''
    runHook postInstall
  '';

  doCheck = false;

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "GitHub CLI tool built from cli/cli PR #14200";
    homepage = "https://cli.github.com/";
    changelog = "https://github.com/cli/cli/pull/14200";
    license = lib.licenses.mit;
    mainProgram = "gh";
  };
})
