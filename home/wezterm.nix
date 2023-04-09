{ config, lib, pkgs, ... }:

{
  #wezterm terminal
  #https://nix-community.github.io/home-manager/options.html#opt-programs.wezterm.enable
  programs.wezterm.enable = true;
  
  # Config {{{
  # https://wezfurlong.org/wezterm/config/files.html
  programs.wezterm.extraConfig = ''
    local wezterm = require 'wezterm'
    local config = {}
    config.font = wezterm.font 'PragmataPro Mono Liga'
    config.window_decorations = 'RESIZE'
    config.hide_tab_bar_if_only_one_tab = true
    config.color_scheme = 'nordfox'

    return config
  '';
    

  # }}}


}
# vim: foldmethod=market
