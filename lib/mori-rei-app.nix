{ rei, mori-rei-app, system }:
let
  pkgs = rei.inputs.nixpkgs.legacyPackages.${system};
  haskellLib = pkgs.haskell.lib.compose;
  runtimeConfig = builtins.fromJSON (builtins.readFile (rei + "/nix/runtime-selection.json"));
  runtime = rei.inputs.haskell-nix.lib.mkRuntimePackageSet
    (runtimeConfig // rei.lib.applicationDependencyPolicy);
  appOverlay = import (mori-rei-app + "/nix/haskell-overlay.nix") {
    inherit pkgs;
    inherit (mori-rei-app.inputs) mori-src mori-app-src;
  };
  # The pinned bridge predates the Rei 10 and Keiro 0.26 bounds.
  bridgeOverlay = pkgs.lib.composeExtensions appOverlay (_: prev: {
    mori-rei-app = haskellLib.overrideCabal (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace mori-rei-app.cabal \
          --replace-fail 'rei-core ^>=9.0,' 'rei-core ^>=10.0,' \
          --replace-fail 'keiro ^>=0.24.0.0,' 'keiro ^>=0.26.0.0,' \
          --replace-fail 'keiro-migrations ^>=0.24.0.0,' 'keiro-migrations ^>=0.26.0.0,'
      '';
    }) prev.mori-rei-app;
  });
  scope = runtime.mkApplicationScope pkgs (pkgs.lib.composeExtensions
    (rei.lib.haskellExtension haskellLib pkgs)
    bridgeOverlay);
in
scope.mori-rei-app
