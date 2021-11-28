{ config, pkgs, lib, ... }:

{
  # Import config broken out into files
  imports = [
    ./git.nix
    ./neovim.nix
    ./shells.nix
  ];

}
