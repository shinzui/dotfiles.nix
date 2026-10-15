# Flake-level `overlays` output.
#
# Note: these are applied via `attrValues self.overlays`, so they are applied in
# *alphabetical* order of their attribute names, which one relies on:
#   - `vimExtraPlugins-require-check-exemptions` must sort after `nix-neovimplugins`,
#     which is what introduces `vimExtraPlugins`.
# Renaming either one will silently change behaviour.
{ self, inputs, ... }:
{
  flake.overlays = {
    nix-neovimplugins = inputs.nix-neovimplugins.overlays.default;
    bun2nix = inputs.bun2nix.overlays.default;

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
        # These flakes ship developer tools, not libraries anyone reads Haddock
        # for, so drop the `doc` output and the haddock pass from every
        # darwin-rebuild. Scope: this reaches only each flake's *top-level*
        # package. The rest of the closure is built inside the project's own
        # flake against its own pkgs, which no overlay here can influence, so
        # each project now wraps its own packages in `dontHaddock` in its
        # nix/haskell-overlay.nix (nix/haskell.nix for okf) — see
        # mori://shinzui/mori and mori://shinzui/rei. That leaves this a
        # belt-and-braces default for any flake that has not done so yet.
        #
        # Third-party dependency Haddock is still built (once, then cached).
        # Cutting that too means `disableHaddock = true` on
        # mori://shinzui/haskell-nix's `mkChannelExtension`, which re-hashes the
        # whole ~315-derivation closure for a one-time full rebuild.
        # `seihou`'s default output is not a Cabal derivation, hence the guard.
        noHaddock = drv:
          if drv ? override then prev.haskell.lib.compose.dontHaddock drv else drv;
        hsPkg = input:
          noHaddock inputs.${input}.packages.${prev.stdenv.hostPlatform.system}.default;
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
          inherit (final) lib fetchFromGitHub rustPlatform;
        };
        # Keep nixpkgs' packaging, overriding only the newer release source.
        container = final.callPackage (self + "/derivations/apple-container.nix") {
          container = prev.container;
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
        # rei's HTTP front end. Its own flake output: `packages.default` is the CLI,
        # which does not depend on it.
        rei-api = hsBin "rei-api"
          (noHaddock inputs.rei.packages.${prev.stdenv.hostPlatform.system}.rei-api);
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
          (noHaddock inputs.notion-hub.packages.${prev.stdenv.hostPlatform.system}.notion-hub-subscriptions);
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
