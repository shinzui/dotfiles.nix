# Flake-level `overlays` output.
#
# Note: these are applied via `attrValues self.overlays`, so they are applied in
# *alphabetical* order of their attribute names. Two overlays rely on that:
#   - `aaa-fix-pgspecial` is named to sort first, so it applies early.
#   - `vimExtraPlugins-no-require-check` must sort after `nix-neovimplugins`,
#     which is what introduces `vimExtraPlugins`.
# Renaming either one will silently change behaviour.
{ self, inputs, lib, ... }:
let
  nixpkgsConfig = import ../lib/nixpkgs-config.nix { inherit self lib; };
in
{
  flake.overlays = {
    nix-neovimplugins = inputs.nix-neovimplugins.overlays.default;
    bun2nix = inputs.bun2nix.overlays.default;

    # Fix tmux-extrakto to not pull in Linux-only dependencies on Darwin
    tmux-extrakto-darwin-fix = import ../overlays/tmux-extrakto-darwin-fix.nix;

    # Pin harlequin to avoid broken textual dependency
    harlequin-pin = import ../overlays/harlequin-pin.nix;

    # Fix pgspecial to avoid broken postgresql-test-hook dependency (named to apply early)
    aaa-fix-pgspecial = import ../overlays/fix-pgspecial.nix;

    # Fix httpstat's setup.py to build under Python 3.12+ (ast.Str removal)
    httpstat-fix = import ../overlays/httpstat-fix.nix;

    # Skip worktrunk tests that need the OS process table (blocked in the sandbox)
    worktrunk-skip-proc-tests = import ../overlays/worktrunk-skip-proc-tests.nix;

    my-packages = final: prev:
      let
        # Every Haskell flake output here ships lib/links/*.dylib (e.g.
        # libgmpxx.4.dylib). Two of them in the same buildEnv — or one of
        # them alongside nixpkgs' hoogle — collide when home-manager
        # assembles the profile. None of these need anything but bin/.
        hsBin = name: drv: prev.runCommand name { } ''
          mkdir -p $out
          ln -s ${drv}/bin $out/bin
        '';
        hsPkg = input: inputs.${input}.packages.${prev.stdenv.hostPlatform.system}.default;
      in
      {
        tmuxai = final.callPackage (self + "/derivations/tmuxai.nix") {
          inherit (final) lib buildGoModule fetchFromGitHub tmux;
        };
        oq = final.callPackage (self + "/derivations/oq.nix") {
          inherit (final) lib buildGoModule fetchFromGitHub;
        };
        uuinfo = final.callPackage (self + "/derivations/uuinfo.nix") {
          inherit (final) lib rustPlatform fetchFromGitHub;
        };
        ck = final.callPackage (self + "/derivations/ck.nix") { };
        parqeye = final.callPackage (self + "/derivations/parqeye.nix") {
          inherit (final) lib fetchFromGitHub;
          # parqeye v0.0.2 pins an `ethnum` that transmutes between `()` and
          # `TryFromIntError`; rustc >= ~1.95 rejects that (E0512). No newer
          # parqeye release exists, so build it with nixos-25.11's rustc 1.91.
          rustPlatform = final.pkgs-stable.rustPlatform;
        };
        beautiful-mermaid = final.callPackage (self + "/derivations/beautiful-mermaid") { };
        markit = final.callPackage (self + "/derivations/markit") { };
        defuddle = final.callPackage (self + "/derivations/defuddle") { };
        hunk = final.callPackage (self + "/derivations/hunk") { };
        jaeger-ui = final.callPackage (self + "/derivations/jaeger-ui") { };
        bootstrap-repos = final.callPackage (self + "/derivations/bootstrap-repos") { };
        pg_rman = final.callPackage (self + "/derivations/pg_rman.nix") {
          postgresql = final.postgresql_18;
        };
        mori = hsBin "mori" (hsPkg "mori");
        rei = hsBin "rei" (hsPkg "rei");
        # Wrap reiko to expose only bin/ and share/ — the full Haskell output
        # includes lib/links/libHStan-commons-config-* which conflicts with
        # mori (both depend on tan-commons-config from the same package set).
        # share/ is kept because reiko bundles its built SPA under
        # share/reiko-ui, so `reiko web` finds the viewer (no --dist needed).
        reiko = prev.runCommand "reiko" { } ''
          mkdir -p $out
          src=${inputs.reiko.packages.${prev.stdenv.hostPlatform.system}.default}
          ln -s $src/bin $out/bin
          ln -s $src/share $out/share
        '';
        # Wrap seihou to only expose bin/ — the full Haskell output
        # includes lib/links/libHSbaikai-* which conflicts with mori
        # (both now depend on baikai from the same package set).
        seihou = prev.runCommand "seihou" { } ''
          mkdir -p $out
          ln -s ${inputs.seihou.packages.${prev.stdenv.hostPlatform.system}.default}/bin $out/bin
        '';
        # Wrap kizamu to only expose bin/ — the full Haskell output
        # includes lib/links/libHSblake3-* which conflicts with mori
        # (both depend on blake3 from the same package set).
        kizamu = prev.runCommand "kizamu" { } ''
          mkdir -p $out
          ln -s ${inputs.kizamu.packages.${prev.stdenv.hostPlatform.system}.default}/bin $out/bin
        '';
        # Wrap kazuha to only expose bin/ — the full Haskell output
        # includes lib/links/libHSbaikai-* which conflicts with mori
        # (both depend on baikai from the same package set).
        kazuha = prev.runCommand "kazuha" { } ''
          mkdir -p $out
          ln -s ${inputs.kazuha.packages.${prev.stdenv.hostPlatform.system}.default}/bin $out/bin
        '';
        # Wrap mina to expose bin/ and share/ — the full Haskell output
        # includes lib/links/libHSmori-schema-pin-* which conflicts with mori
        # (both now depend on mori-schema-pin from the same package set).
        # share/ is kept because mina bundles its built SPA under
        # share/mina-ui, so `mina web` finds the viewer (no --dist needed).
        mina = prev.runCommand "mina" { } ''
          mkdir -p $out
          src=${inputs.mina.packages.${prev.stdenv.hostPlatform.system}.default}
          ln -s $src/bin $out/bin
          ln -s $src/share $out/share
        '';
        nihongo = hsBin "nihongo" (hsPkg "nihongo");
        shiki = hsBin "shiki" (hsPkg "shiki");
        okf = hsBin "okf" (hsPkg "okf");
        # Wrap mori-rei-app to only expose bin/ — the full Haskell output
        # includes lib/links/libHStan-commons-config-* which conflicts with
        # mori (both depend on tan-commons-config from the same package set).
        mori-rei-app = prev.runCommand "mori-rei-app" { } ''
          mkdir -p $out
          ln -s ${inputs.mori-rei-app.packages.${prev.stdenv.hostPlatform.system}.default}/bin $out/bin
        '';
        notion-cli = hsBin "notion-cli" (hsPkg "notion-cli");
        # Wrap notion-hub to only expose bin/ — the full Haskell output
        # includes lib/ghc-*/libHSnotion-client-* which conflicts with
        # notion-cli (both depend on notion-client from different package sets).
        notion-hub = prev.runCommand "notion-hub" { } ''
          mkdir -p $out
          ln -s ${inputs.notion-hub.packages.${prev.stdenv.hostPlatform.system}.default}/bin $out/bin
        '';
        notion-hub-subscriptions = hsBin "notion-hub-subscriptions"
          inputs.notion-hub.packages.${prev.stdenv.hostPlatform.system}.notion-hub-subscriptions;
      };

    # Escape hatch for packages that don't build against current unstable —
    # currently parqeye, which needs an older rustc.
    pkgs-stable = final: prev: {
      pkgs-stable = import inputs.nixpkgs-stable {
        system = prev.stdenv.hostPlatform.system;
        inherit (nixpkgsConfig) config;
      };
    };

    # Disable nixpkgs' neovim require-check for NixNeovimPlugins' generated set
    # (named to sort after `nix-neovimplugins`, which provides vimExtraPlugins)
    vimExtraPlugins-no-require-check = import ../overlays/vimExtraPlugins-no-require-check.nix;

    # Overlay that adds various additional utility functions to `vimUtils`
    vimUtils = import ../overlays/vimUtils.nix;

    # Overlay that adds some additional Neovim plugins
    vimPlugins = final: prev:
      let
        inherit (self.overlays.vimUtils final prev) vimUtils;
      in
      {
        vimPlugins = prev.vimPlugins.extend (super: self:
          (vimUtils.buildVimPluginsFromFlakeInputs inputs [
            "vim-rescript"
          ]) // {
            keiro-vim = prev.vimUtils.buildVimPlugin {
              pname = "keiro-vim";
              version = inputs.keiro-syntax.shortRev or inputs.keiro-syntax.lastModifiedDate or "unstable";
              src = inputs.keiro-syntax + "/packages/keiro-vim";
            };
          }
        );
      };
  };
}
