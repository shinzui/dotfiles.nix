{ config, ... }:

let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  nixConfigDir = "${config.home.homeDirectory}/.config/dotfiles.nix";
in
{
  home.file.".claude/CLAUDE.md".source =
    mkOutOfStoreSymlink "${nixConfigDir}/config/claude/CLAUDE.md";
}
