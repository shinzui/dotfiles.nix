{
  description = "Shinzui's dotfiles";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # Shared Haskell toolchain base flake. Every shinzui Haskell project below
    # follows this single input (and its pinned nixpkgs), so they all build
    # against one GHC 9.12.4 toolchain and one nixpkgs revision — maximizing
    # binary-cache sharing across the projects and avoiding toolchain rebuilds
    # when nixpkgs-unstable moves.
    haskell-nix-dev.url = "github:shinzui/haskell-nix-dev";

    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-unstable";
    };
    # Consumed by default.nix (legacy non-flake entry point), which reads its
    # rev straight out of flake.lock — not referenced from flake.nix itself.
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    nix-neovimplugins = { url = "github:NixNeovim/NixNeovimPlugins"; };
    vim-rescript = { url = "github:rescript-lang/vim-rescript"; flake = false; };
    keiro-syntax = { url = "github:shinzui/keiro-syntax"; flake = false; };
    private-fonts = { url = "git+ssh://git@github.com/shinzui/fonts"; };
    dotfiles-private = {
      url = "git+ssh://git@github.com/shinzui/dotfiles-private.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # A home-manager module running a local Redpanda cluster on Apple Container.
    # Not a Haskell project, so it follows nixpkgs-unstable rather than the
    # shared Haskell toolchain flake the tools below use.
    redpanda-container = {
      url = "github:shinzui/redpanda-container";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # Organization sources use SSH because personal fine-grained tokens are
    # limited to their resource owner. Keep these existing source revisions;
    # review the overrides when updating the consuming tool inputs.
    mori = {
      # Keep the rehearsed runtime/toolchain, with the observed-HEAD guard for
      # clients which feed commits through the shared database tunnel.
      # mori://shinzui/mori/plans/304-upgrade-mori-to-keiro-0-21-and-retire-obsolete-runtime-workarounds
      # Rejoin the shared toolchain only after the resulting runtime is rehearsed.
      url = "github:shinzui/mori/4f56ce3e2a5cbb615018a51b8ecb50a6feeafe85";
    };
    rei = {
      # Personal Topic-profile cohort; release proof belongs to
      # mori://shinzui/rei/masterplans/30-support-user-defined-topic-profiles.
      url = "github:shinzui/rei/9833d3cf0766495c6fc7b59050e13a92a11ff8c8";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    reiko = {
      url = "github:shinzui/reiko";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    seihou = {
      url = "github:shinzui/seihou";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    kizamu = {
      url = "github:shinzui/kizamu";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    kazuha = {
      url = "github:shinzui/kazuha";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    mina = {
      url = "github:shinzui/mina";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    nihongo = {
      url = "github:shinzui/nihongo";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    shiki = {
      url = "github:shinzui/shiki";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    okf = {
      url = "github:shinzui/okf";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    notion-cli = {
      url = "github:shinzui/notion-cli";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    mori-rei-app = {
      url = "github:shinzui/mori-rei-app/fccc5b054529acd3cde7d34c5bd523101f143c81";
      # The integration embeds Rei's codecs and catalog: deploy the same source.
      inputs.rei.follows = "rei";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    notion-hub = {
      url = "github:shinzui/notion-hub";
      inputs.tan-effectful-src.url = "git+ssh://git@github.com/topagentnetwork/tan-effectful?rev=5e081ad8019b4731d1da37003c80aaaac6ccb5b5";
      inputs.typeid-hs-src.url = "git+ssh://git@github.com/topagentnetwork/typeid-hs?rev=e59e3f29237dcaddfd1faba158302532daf62a2a";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];

      imports = [
        ./flake-modules/overlays.nix
        ./flake-modules/modules.nix
        ./flake-modules/darwin-configurations.nix
        ./flake-modules/packages.nix
      ];
    };
}
# vim: foldmethod=marker
