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

  # Determinate's daemon handles GC itself (targets ~30GB free / 5–20% steady-state).
  # No interval / retention knobs are exposed — strategy is the only switch.
  determinateNix.determinateNixd.garbageCollector.strategy = "automatic";

  determinateNix.registry.nixpkgs.flake = nixpkgs-unstable;

  ##################
  # Remote builders
  ##################
  # On-demand x86_64-linux builder hosted in GCP (tan-nb-exp / us-west1-a).
  # The wrapper that opens the SSH connection lives in
  # ~/Keikaku/dotfiles.nix/home/gcp-nix-builder.nix; that wrapper starts
  # the VM on demand and shuts it back down via an in-guest systemd timer.
  #
  # Determinate Nix shadows nix-darwin's `nix.buildMachines` /
  # `nix.distributedBuilds` with its own `determinateNix.*` equivalents.
  # Use the Determinate-flavored options so the active daemon picks
  # them up.
  determinateNix.distributedBuilds = true;
  determinateNix.buildMachines = [{
    hostName = "nix-gcp-builder";
    systems = [ "x86_64-linux" ];
    maxJobs = 4;
    speedFactor = 2;
    supportedFeatures = [ "kvm" "big-parallel" "nixos-test" ];
    sshUser = "builder";
    sshKey = "/etc/nix/builder_ed25519";
  }];

  # Let the remote builder pull from substituters directly rather than
  # round-tripping every closure through the darwin host.
  determinateNix.customSettings.builders-use-substitutes = true;

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
