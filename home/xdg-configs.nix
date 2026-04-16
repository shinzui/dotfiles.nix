{ config, lib, ... }:

let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  nixConfigDir = "${config.home.homeDirectory}/.config/dotfiles.nix";

  # Explicit list of app configs to symlink.
  # Each name corresponds to a directory or file under config/xdg/
  # that will be symlinked to ~/.config/<name>.
  trackedConfigs = [
    "mori"
    "rei"
  ];
in
{
  xdg.configFile = lib.genAttrs trackedConfigs (name: {
    source = mkOutOfStoreSymlink "${nixConfigDir}/config/xdg/${name}";
  });
}
