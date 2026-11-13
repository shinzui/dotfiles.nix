# Jaeger v2 (all-in-one `jaeger` binary) from the upstream release tarballs.
# nixpkgs does not package Jaeger, so this repackages the prebuilt, statically
# linked Go binary. To update: bump `version`, then refresh each hash with
#   nix-prefetch-url https://github.com/jaegertracing/jaeger/releases/download/v<v>/jaeger-<v>-<platform>.tar.gz
# and convert it with `nix hash convert --hash-algo sha256 --to sri <hash>`.
{ lib, stdenvNoCC, fetchurl }:

let
  platforms = {
    aarch64-darwin = { arch = "darwin-arm64"; hash = "sha256-7U8AY25akJz4zj/Nryah6nl3Fj/inaj7UDGzemqWgsQ="; };
    x86_64-darwin = { arch = "darwin-amd64"; hash = "sha256-rbsDV0yzzUJs3gX2EKWfGwWDrBXsXOBEhobwBeVW0jY="; };
    aarch64-linux = { arch = "linux-arm64"; hash = "sha256-yuBEYCFGKm2l4dwmY9BHRQy1l05OOYiG0q3KygXSarc="; };
    x86_64-linux = { arch = "linux-amd64"; hash = "sha256-S3vRUu0x0iBeTnO4c9KJxhzT+rrsyGRDBwFDRI1At1M="; };
  };
  system = stdenvNoCC.hostPlatform.system;
  platform = platforms.${system} or (throw "jaeger: unsupported system ${system}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "jaeger";
  version = "2.23.0";

  src = fetchurl {
    url = "https://github.com/jaegertracing/jaeger/releases/download/v${finalAttrs.version}/jaeger-${finalAttrs.version}-${platform.arch}.tar.gz";
    inherit (platform) hash;
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 jaeger-*/jaeger $out/bin/jaeger
    install -Dm755 jaeger-*/example-hotrod $out/bin/jaeger-example-hotrod
    runHook postInstall
  '';

  meta = {
    description = "Distributed tracing platform (Jaeger v2 all-in-one binary)";
    homepage = "https://www.jaegertracing.io/";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames platforms;
    mainProgram = "jaeger";
  };
})
