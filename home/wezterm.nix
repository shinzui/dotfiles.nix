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
    config.front_end = 'WebGpu'
    config.font = wezterm.font 'PragmataPro Mono Liga'
    config.window_decorations = 'RESIZE'
    config.warn_about_missing_glyphs = false
    config.hide_tab_bar_if_only_one_tab = true
    config.color_scheme = 'nordfox'

    config.audible_bell = 'Disabled'

    -- Use the title set by tmux (session name) for the tab title
    wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
      local pane = tab.active_pane
      local title = pane.title
      if title and #title > 0 then
        return title
      end
      return tab.tab_index + 1
    end)

    config.set_environment_variables = {
      TERMINFO_DIRS = '/home/shinzui/.nix-profile/share/terminfo',
      WSLENV = 'TERMINFO_DIRS',
    }

    config.mouse_bindings = {
       -- and make CTRL-Click open hyperlinks
      {
        event={Up={streak=1, button="Left"}},
        mods="CTRL",
        action="OpenLinkAtMouseCursor",
      },
    }

    return config
  '';
  # }}}


}
# vim: foldmethod=marker
