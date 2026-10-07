{ config, lib, pkgs, ... }:

{
  # wezterm terminal
  # The app comes from the official Homebrew cask (darwin/homebrew.nix), not
  # nixpkgs: the cask is Developer ID-signed, so its macOS privacy grants
  # (e.g. Privacy & Security > Developer Tools) survive upgrades. The nixpkgs
  # build is only ad-hoc signed, so its identity changes on every rebuild.
  # `programs.wezterm` can't be used without installing the nixpkgs package,
  # so the config is written directly.

  # Shell integration (OSC 7 cwd, user vars) shipped inside the cask's bundle.
  programs.zsh.initContent = ''
    if [[ -o interactive && -r /Applications/WezTerm.app/Contents/Resources/wezterm.sh ]]; then
      source /Applications/WezTerm.app/Contents/Resources/wezterm.sh
    fi
  '';

  # Config {{{
  # https://wezfurlong.org/wezterm/config/files.html
  xdg.configFile."wezterm/wezterm.lua".text = ''
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
      TERMINFO_DIRS = '${config.home.profileDirectory}/share/terminfo',
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
