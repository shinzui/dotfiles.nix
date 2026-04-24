{ config, pkgs, nixpkgs-unstable, lib, ... }:

{
  system.primaryUser = "shinzui";
  ##################
  # Nix configuration (managed via Determinate Nix)
  ##################

  determinateNix.customSettings = {
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

    keep-outputs = true;
    keep-derivations = true;

    # Fall back to building from source when a substituter fails
    fallback = true;
    # Reduce connection timeout for substituters (seconds)
    connect-timeout = 10;
  };

  # Include access tokens from agenix secret into nix.custom.conf
  environment.etc."nix/nix.custom.conf".text = lib.mkAfter ''
    !include ${config.age.secrets.access_token.path}
  '';

  determinateNix.determinateNixd.authentication.additionalNetrcSources = [
    config.age.secrets.netrc.path
  ];

  determinateNix.registry.nixpkgs.flake = nixpkgs-unstable;

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

  ##################
  # System limits
  ##################
  # Raise the system-wide file descriptor limit. macOS defaults to 256 soft,
  # which is trivially exhausted by modern dev tooling (language servers,
  # watchers, containers) and can hang the machine.
  launchd.daemons."limit.maxfiles" = {
    serviceConfig = {
      Label = "limit.maxfiles";
      ProgramArguments = [ "launchctl" "limit" "maxfiles" "524288" "524288" ];
      RunAtLoad = true;
      ServiceIPC = false;
    };
  };

  system.stateVersion = 4;
}
