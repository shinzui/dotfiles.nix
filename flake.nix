{
  description = "Shinzui's dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # Escape hatch for packages that don't build against current unstable —
    # e.g. crates needing an older rustc. The `pkgs-stable` overlay exposes it
    # as `pkgs.pkgs-stable`.
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

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
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    nix-neovimplugins = { url = "github:NixNeovim/NixNeovimPlugins"; };
    vim-rescript = { url = "github:rescript-lang/vim-rescript"; flake = false; };
    keiro-syntax = { url = "github:shinzui/keiro-syntax"; flake = false; };
    private-fonts = { url = "github:shinzui/fonts";};
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    mori = {
      url = "github:shinzui/mori";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    rei = {
      url = "github:shinzui/rei";
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
      url = "github:shinzui/mori-rei-app";
      inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
      inputs.haskell-nix-dev.follows = "haskell-nix-dev";
    };
    notion-hub = {
      url = "github:shinzui/notion-hub";
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
