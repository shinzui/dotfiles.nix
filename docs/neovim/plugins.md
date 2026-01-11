# Neovim Plugins

## vimExtraPlugins

[NixNeovimPlugins](https://github.com/NixNeovim/NixNeovimPlugins) provides additional neovim plugins not available in nixpkgs.

**Naming Convention:** Plugin names include the owner to prevent conflicts: `<plugin-name>-<owner>`

Used via the `pkgs.vimExtraPlugins` overlay for plugins like:
- `lspsaga-nvim-nvimdev`
- `trouble-nvim-folke`
- `conform-nvim-stevearc`
- `grug-far-nvim-MagicDuck`
- `neogit-NeogitOrg`

Find exact plugin names at: https://github.com/NixNeovim/NixNeovimPlugins/blob/main/plugins.md

## LSP Plugins

### Lspsaga

[LspSaga](https://nvimdev.github.io/lspsaga/) enhances LSP UI with better hover docs, code actions, and diagnostics.
