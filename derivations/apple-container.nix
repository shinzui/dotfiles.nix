# Apple Container, pinned to the latest upstream release.
#
# Copied from nixpkgs `pkgs/by-name/co/container/package.nix` (nixpkgs-unstable),
# which lags upstream: nixpkgs ships 1.1.0 while apple/container is at 1.2.2.
# Diff this file against that path when bumping, and delete it entirely once
# nixpkgs catches up — the overlay registers it as `container`, shadowing
# nixpkgs' own attribute of the same name, so removal is a one-line migration.
#
# Changes from the nixpkgs original: version and src hash bumped to 1.2.2, and
# the `nix-update-script` argument plus the `passthru.updateScript` it feeds are
# dropped (no nixpkgs update bot operates on this repository).
{
  lib,
  stdenvNoCC,
  fetchurl,
  libarchive,
  xar,
  installShellFiles,
  makeWrapper,
  versionCheckHook,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "container";
  version = "1.2.2";

  src = fetchurl {
    url = "https://github.com/apple/container/releases/download/${finalAttrs.version}/container-${finalAttrs.version}-installer-signed.pkg";
    hash = "sha256-9MfnP3IDclo1Emdt/Z7GxqmKNwk7b9ShsP3PyyJ+IRg=";
  };

  nativeBuildInputs = [
    libarchive
    xar
    installShellFiles
    makeWrapper
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    xar -xf $src Payload
    bsdtar --extract --file Payload --directory $out

    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
    installShellCompletion --cmd ${finalAttrs.meta.mainProgram} \
      --bash <($out/bin/${finalAttrs.meta.mainProgram} --generate-completion-script bash) \
      --fish <($out/bin/${finalAttrs.meta.mainProgram} --generate-completion-script fish) \
      --zsh <($out/bin/${finalAttrs.meta.mainProgram} --generate-completion-script zsh)
  '';

  postFixup = ''
    wrapProgram $out/bin/container \
      --set-default CONTAINER_INSTALL_ROOT "$out"
    wrapProgram $out/bin/container-apiserver \
      --set-default CONTAINER_INSTALL_ROOT "$out"
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  doInstallCheck = true;

  meta = {
    description = "Create and run Linux containers using lightweight virtual machines on a Mac";
    homepage = "https://github.com/apple/container";
    changelog = "https://github.com/apple/container/releases/tag/${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "container";
    maintainers = with lib.maintainers; [
      xiaoxiangmoe
      Br1ght0ne
    ];
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
