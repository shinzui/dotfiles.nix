{ config, pkgs, lib, ... }:

let
  inherit (lib) getName mkIf optional;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  nixConfigDir = "${config.home.homeDirectory}/.config/dotfiles.nix";

  pluginWithDeps = plugin: deps: plugin.overrideAttrs (_: { dependencies = deps; });
  optionalPlugin = plugin: {
    plugin = plugin;
    optional = true;
  };

  pluginWithConfig = plugin: {
    plugin = plugin;
    optional = true;
    config = ''
      lua require('shinzui.' .. string.gsub('${plugin.pname}', '%.', '-'))
    '';
  };

in
{
  programs.neovim.enable = true;


  # Config and plugins {{{

  # minimal init.vim config to load lua config. nix and home manager don't currently support
  # `init.lua`.
  xdg.configFile."nvim/lua".source = mkOutOfStoreSymlink "${nixConfigDir}/config/nvim/lua";
  programs.neovim.extraConfig = "lua require('init')";

  programs.neovim.plugins = with pkgs.vimPlugins; [
    nord-nvim
    moses-nvim
    vim-tmux-navigator
  ] ++ map optionalPlugin [
    telescope-symbols-nvim
    cmp-nvim-lua
    cmp-cmdline
    cmp-path
    cmp-emoji
    cmp-buffer
    cmp-nvim-lsp
    (pluginWithDeps cmp_luasnip [luasnip])
  ] ++ map pluginWithConfig [
    (pluginWithDeps nvim-tree-lua [ nvim-web-devicons ])
    nvim-cmp
    which-key-nvim
    nvim-lspconfig
    nvim-treesitter
    telescope-fzf-native-nvim
    lspsaga-nvim
    onenord-nvim
    gitsigns-nvim
    trouble-nvim
    (pluginWithDeps telescope-nvim [ nvim-web-devicons ])
    #(pluginWithDeps galaxyline-nvim [ nvim-web-devicons ])
    comment-nvim
    nvim-spectre
  ];

  # }}}

  # Required packages {{{

  programs.neovim.extraPackages = with pkgs; [
    gcc # needed for nvim-treesitter
    tree-sitter # needed for nvim-treesitter
    gnused #needed for nvim-spectre
  ];

  # }}}
}
# vim: foldmethod=marker
