{ config, lib, ... }:
{
  networking.computerName = "yujin";
  networking.hostName = "yujin";
  age.identityPaths = lib.mkForce [ "/Users/shinzui/.ssh/agenix_ed25519" ];
  home-manager.users.${config.users.primaryUser}.imports = [ ./home.nix ];
}
