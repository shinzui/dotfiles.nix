{ config, ... }:
{
  nix-homebrew = {
    enable = true;
    user = config.system.primaryUser;
    enableRosetta = false;
    mutableTaps = true;
    autoMigrate = false;
  };
}
