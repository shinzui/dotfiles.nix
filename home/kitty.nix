{ config, lib, pkgs, ... }:

{

  # Kitty terminal
  # https://sw.kovidgoyal.net/kitty/conf.html
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.kitty.enable
  programs.kitty.enable = true;

  # Config {{{
  programs.kitty.settings = {
    font_family = "PragmataPro Mono Liga";
    font_size = "12.0";
  };

  # }}}


}
# vim: foldmethod=marker

