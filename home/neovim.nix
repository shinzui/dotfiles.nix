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

  pluginWithConfigAndExtraConfig = extraConfig: plugin: {
    plugin = plugin;
    optional = true;
    config = ''
      ${extraConfig}
      lua require('shinzui.' .. string.gsub('${plugin.pname}', '%.', '-'))
    '';
  };

  pluginWithConfig = pluginWithConfigAndExtraConfig "";
in
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };


  # Config and plugins 

  # minimal init.vim config to load lua config. nix and home manager don't currently support
  # `init.lua`.
  xdg.configFile."nvim/lua".source = mkOutOfStoreSymlink "${nixConfigDir}/config/nvim/lua";
  programs.neovim.extraConfig = ''
    lua require('init')
  '';

  programs.neovim.plugins = with pkgs.vimPlugins; [
    nord-nvim
    vim-surround
    vim-repeat
    vim-tmux-navigator
    vim-asterisk
    vim-helm
    vim-just
    vim-nickel
  ] ++ map optionalPlugin [
    telescope-symbols-nvim
    cmp-nvim-lua
    cmp-cmdline
    cmp-path
    cmp-emoji
    cmp-buffer
    cmp-nvim-lsp
    (pluginWithDeps cmp_luasnip [ luasnip ])
    lspkind-nvim
    (pluginWithDeps lualine-lsp-progress [ lualine-nvim ])
    telescope_hoogle
    telescope-manix
    telescope-live-grep-args-nvim
    telescope-undo-nvim
    vim-rescript
    pkgs.vimExtraPlugins.twoslash-queries-nvim
    pkgs.vimExtraPlugins.mini-nvim
  ] ++ map pluginWithConfig [
    (pluginWithDeps nvim-tree-lua [ nvim-web-devicons ])
    nvim-cmp
    which-key-nvim
    nvim-treesitter.withAllGrammars
    telescope-fzf-native-nvim
    pkgs.vimExtraPlugins.lspsaga-nvim
    onenord-nvim
    gitsigns-nvim
    pkgs.vimExtraPlugins.trouble-nvim
    pkgs.vimExtraPlugins.nvim-lint
    pkgs.vimExtraPlugins.conform-nvim
    (pluginWithDeps telescope-nvim [ nvim-web-devicons ])
    lualine-nvim
    # (pluginWithDeps galaxyline-nvim [ nvim-web-devicons ])
    comment-nvim
    pkgs.vimExtraPlugins.grug-far-nvim
    hop-nvim
    git-blame-nvim
    toggleterm-nvim
    nvim-hlslens
    symbols-outline-nvim
    # pkgs.vimExtraPlugins.neogit
    nvim-ts-autotag
    octo-nvim
    (pluginWithDeps diffview-nvim [ nvim-web-devicons ])
    # nvim-treesitter-context
    markdown-preview-nvim
    ChatGPT-nvim
    glance-nvim
    (pluginWithDeps neotest [ neotest-haskell nvim-nio ])
  ] ++ [
    (pluginWithConfigAndExtraConfig "lua vim.api.nvim_set_var('rescript_lsp_path','${vim-rescript}/server/out/server.js')" nvim-lspconfig)
  ];
  # 

  # Required packages 

  programs.neovim.extraPackages = with pkgs; [
    gcc # needed for nvim-treesitter
    gccStdenv
    # tree-sitter # needed for nvim-treesitter
    vimPlugins.nvim-treesitter-parsers.hurl
    nodePackages.typescript
    nodePackages.typescript-language-server
    luajitPackages.nvim-nio
  ];

  # 
}
# vim: foldmethod=marker
