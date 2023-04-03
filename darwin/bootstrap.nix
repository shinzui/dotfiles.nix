{ config, pkgs, lib, ... }:

{
  ##################
  # Nix configuration
  ##################

  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://shinzui.cachix.org"
      "https://hydra.iohk.io"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "shinzui.cachix.org-1:QEmAoJrA9WwLP0uxfDgktLi2BRrcvQQWdz8NzcMg4/E="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];

    trusted-users = [
      "shinzui"
      "@admin"
    ];
    auto-optimise-store = true;

    experimental-features = [
      "nix-command"
      "flakes"
    ];

    keep-outputs = true;
    keep-derivations = true;

    extra-platforms = lib.mkIf (pkgs.system == "aarch64-darwin") [ "x86_64-darwin" "aarch64-darwin" ];
  };

  nix.extraOptions = ''
    !include ${config.age.secrets.access_token.path}
  '';

  nix.configureBuildUsers = true;

  nix.package = pkgs.nixUnstable;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

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
