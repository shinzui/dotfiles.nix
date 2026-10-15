# nixpkgs currently packages Container 1.1.0. Keep its installation, wrappers,
# completions, and version check while selecting the 1.5.0 release source.
# Remove this override once the locked nixpkgs provides this release or newer.
{ container, fetchurl }:

container.overrideAttrs (finalAttrs: previousAttrs: {
  version = "1.5.0";
  src = fetchurl {
    url = "https://github.com/apple/container/releases/download/${finalAttrs.version}/container-${finalAttrs.version}-installer-signed.pkg";
    hash = "sha256-okgIyyAjGPocO77gxsaIf+EiX+iZ17aHoN3ZOb1lc/g=";
  };
  # The nixpkgs update bot does not operate on this repository.
  passthru = builtins.removeAttrs (previousAttrs.passthru or { }) [ "updateScript" ];
})
