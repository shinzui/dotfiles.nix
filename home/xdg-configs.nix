{ config, lib, ... }:

let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  nixConfigDir = "${config.home.homeDirectory}/.config/dotfiles.nix";

  # Whole app config directories to symlink. Each name corresponds to a
  # directory under config/xdg/ that will be symlinked to ~/.config/<name>,
  # making home-manager the owner of everything under it.
  trackedConfigDirs = [
    "kazuha"
    "mori"
    "rei"
  ];

  # Individual files to symlink, for apps where only part of the config
  # directory is tracked. Each path is relative to config/xdg/ and lands at
  # ~/.config/<path>; the rest of the app's directory (e.g.
  # ~/.config/mina/agents) stays unmanaged.
  trackedConfigFiles = [
    "mina/config.kdl"
  ];
in
{
  xdg.configFile = lib.genAttrs (trackedConfigDirs ++ trackedConfigFiles) (path: {
    source = mkOutOfStoreSymlink "${nixConfigDir}/config/xdg/${path}";
  });
}
