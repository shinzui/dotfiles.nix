{ config, lib, ... }:

{
  # Consumers of the merged public and private secrets. These live here rather than in
  # bootstrap.nix so that `darwinConfigurations.bootstrap-arm`, which imports
  # bootstrap.nix alone, can evaluate on a machine with no secrets yet.

  # Include access tokens from agenix secret into nix.custom.conf
  environment.etc."nix/nix.custom.conf".text = lib.mkAfter ''
    !include ${config.age.secrets.access_token.path}
  '';

  determinateNix.determinateNixd.authentication.additionalNetrcSources = [
    config.age.secrets.netrc.path
  ];

  age.identityPaths = [ "/Users/shinzui/.ssh/id_ed25519" ];
  age.secrets = {
    sesh_config = {
      file = ../secrets/sesh.toml.age;
      path = "/Users/shinzui/.config/sesh/sesh.toml";
      mode = "600";
      owner = "shinzui";
    };
    mori-rei-app-webhook-secret = {
      file = ../secrets/mori-rei-app-webhook-secret.age;
      path = "/Users/shinzui/.config/mori-rei-app/webhook-secret";
      mode = "600";
      owner = "shinzui";
    };
    # REI_API_TOKENS for the rei-api agent (home/rei.nix): comma-separated
    # token=actor pairs, e.g. `<hex>=human,<hex>=agent:mina`.
    rei-api-tokens = {
      file = ../secrets/rei-api-tokens.age;
      path = "/Users/shinzui/.config/rei-api/tokens";
      mode = "600";
      owner = "shinzui";
    };
  };
}
