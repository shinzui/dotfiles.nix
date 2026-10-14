{ config, ... }:
{
  networking.computerName = "sungkyung";
  networking.hostName = "sungkyung";
  home-manager.users.${config.users.primaryUser}.imports = [ ./home.nix ];
}
