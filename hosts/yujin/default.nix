{ config, ... }:
{
  networking.computerName = "yujin";
  networking.hostName = "yujin";
  home-manager.users.${config.users.primaryUser}.imports = [ ./home.nix ];
}
