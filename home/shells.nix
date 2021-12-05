{ config, pkgs, lib, ... }:

{
  # Starship Prompt
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.starship.enable
  programs.starship.enable = true;


  programs.starship.settings = {
    # See docs here: https://starship.rs/config/
    # Symbols config configured in Flake.

    battery.display.threshold = 25; # display battery information if charge is <= 25%
  };
}
