# Flake-level `overlays` output.
#
# Note: these are applied via `attrValues self.overlays`, so they are applied in
# *alphabetical* order of their attribute names, which one relies on:
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

    # Pin harlequin to avoid broken textual dependency
    harlequin-pin = import ../overlays/harlequin-pin.nix;

    # Fix httpstat's setup.py to build under Python 3.12+ (ast.Str removal)
    httpstat-fix = import ../overlays/httpstat-fix.nix;

    # Skip worktrunk tests that need the OS process table (blocked in the sandbox)
    worktrunk-skip-proc-tests = import ../overlays/worktrunk-skip-proc-tests.nix;

    my-packages = final: prev:
      let
        # Every Haskell flake output here ships lib/, which collides in the
        # home-manager profile's buildEnv: either against another of these
        # (shared deps like tan-commons-config, baikai, blake3, notion-client,
        # mori-schema-pin) or against nixpkgs' hoogle (lib/links/libgmpxx).
        # None of them need anything from lib/, so expose only bin/.
        hsBin = name: drv: prev.runCommand name { } ''
          mkdir -p $out
          ln -s ${drv}/bin $out/bin
        '';
        # Same, plus share/ — reiko and mina bundle their built SPA under
        # share/<tool>-ui, so `<tool> web` finds the viewer without --dist.
        hsBinShare = name: drv: prev.runCommand name { } ''
          mkdir -p $out
          src=${drv}
          ln -s $src/bin $out/bin
          ln -s $src/share $out/share
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
        # Shadows nixpkgs' own `container` (1.1.0) with a local copy pinned to
        # the latest upstream release. See derivations/apple-container.nix.
        container = final.callPackage (self + "/derivations/apple-container.nix") { };
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
        reiko = hsBinShare "reiko" (hsPkg "reiko");
        seihou = hsBin "seihou" (hsPkg "seihou");
        kizamu = hsBin "kizamu" (hsPkg "kizamu");
        kazuha = hsBin "kazuha" (hsPkg "kazuha");
        mina = hsBinShare "mina" (hsPkg "mina");
        nihongo = hsBin "nihongo" (hsPkg "nihongo");
        shiki = hsBin "shiki" (hsPkg "shiki");
        okf = hsBin "okf" (hsPkg "okf");
        mori-rei-app = hsBin "mori-rei-app" (hsPkg "mori-rei-app");
        notion-cli = hsBin "notion-cli" (hsPkg "notion-cli");
        notion-hub = hsBin "notion-hub" (hsPkg "notion-hub");
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

    # Exempt the few NixNeovimPlugins that fail nixpkgs' neovim require-check
    # (named to sort after `nix-neovimplugins`, which provides vimExtraPlugins)
    vimExtraPlugins-require-check-exemptions =
      import ../overlays/vimExtraPlugins-require-check-exemptions.nix;

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
