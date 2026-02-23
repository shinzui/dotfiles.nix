{ config, pkgs, nixpkgs-unstable, lib, ... }:

{
  system.primaryUser = "shinzui";
  ##################
  # Nix configuration
  ##################

  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://shinzui.cachix.org"
      "https://tan.cachix.org"
      "https://nvim-treesitter-main.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "shinzui.cachix.org-1:QEmAoJrA9WwLP0uxfDgktLi2BRrcvQQWdz8NzcMg4/E="
      "tan.cachix.org-1:y9VYkIo4aZD4oK1wM/mYppPK0Pt//FMmTIyPcT6sbcs="
      "nvim-treesitter-main.cachix.org-1:cbwE6blfW5+BkXXyeAXoVSu1gliqPLHo2m98E4hWfZQ="
    ];

    trusted-users = [
      "shinzui"
      "@admin"
    ];

    netrc-file = config.age.secrets.netrc.path;

    experimental-features = [
      "nix-command"
      "flakes"
    ];

    keep-outputs = true;
    keep-derivations = true;

    extra-platforms = lib.mkIf (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") [ "x86_64-darwin" "aarch64-darwin" ];
  };

  nix.extraOptions = ''
    !include ${config.age.secrets.access_token.path}
  '';


  nix.package = pkgs.nixVersions.latest;

  nix.registry.nixpkgs.flake = nixpkgs-unstable;

  nix.linux-builder = {
    enable = true;
    config.virtualisation.darwin-builder.memorySize = 8 * 1024;
  };

  ##################
  # Shell
  ##################
  # Add shells installed by nix to /etc/shells file
  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];

  # Install and setup ZSH to work with nix(-darwin) as well
  programs.zsh.enable = true;


  system.stateVersion = 4;
}
