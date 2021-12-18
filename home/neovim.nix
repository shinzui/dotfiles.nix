{ config, pkgs, lib, ... }:

let
  inherit (lib) getName mkIf optional;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  nixConfigDir = "${config.home.homeDirectory}/.config/dotfiles.nix";

in
{
  programs.neovim.enable = true;


  # Config and plugins {{{

  # minimal init.vim config to load lua config. nix and home manager don't currently support
  # `init.lua`.
  xdg.configFile."nvim/lua".source = mkOutOfStoreSymlink "${nixConfigDir}/config/nvim/lua";
  programs.neovim.extraConfig = "lua require('init')";

  # }}}

  # Required packages {{{

  programs.neovim.extraPackages = with pkgs; [
    gcc # needed for nvim-treesitter
    tree-sitter # needed for nvim-treesitter
  ];

  # }}}
}
# vim: foldmethod=marker
