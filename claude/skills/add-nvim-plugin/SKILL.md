---
name: add-nvim-plugin
description: Add and configure a neovim plugin following the nix-based setup. Use when the user wants to add a new vim/neovim plugin.
---

# Add Neovim Plugin

Add the neovim plugin: $ARGUMENTS

## Reference Documentation

Follow the patterns documented in @docs/neovim-plugins.md

## Steps

1. **Find the plugin**: Search nixpkgs for the plugin using `nix search nixpkgs vimPlugins.<name>`. If not found, check vimExtraPlugins.
   - **IMPORTANT**: vimExtraPlugins uses the naming convention `<plugin-name>-<owner>` (e.g., `trouble-nvim-folke`, `conform-nvim-stevearc`).
   - Find the exact name in [plugins.md](https://github.com/NixNeovim/NixNeovimPlugins/blob/main/plugins.md).

2. **Fetch plugin info**: If a GitHub URL is provided, fetch it to understand dependencies and configuration options.

3. **Add to neovim.nix**: Add the plugin to `home/neovim.nix` in the appropriate category:
   - Basic plugins (no config needed) - add to first list
   - Optional plugins (lazy-loaded, no config file) - add to `map optionalPlugin [...]`
   - Configured plugins (with Lua config file) - add to `map pluginWithConfig [...]`

4. **Handle dependencies**: Use `pluginWithDeps` if the plugin requires other plugins like `nvim-web-devicons`.

5. **Create Lua config**: If needed, create `config/nvim/lua/shinzui/<plugin-pname>.lua`.

   **CRITICAL**: The filename MUST match the plugin's `pname` exactly because `pluginWithConfig` derives the Lua module name from it.

   - For nixpkgs plugins: use the plugin name (e.g., `telescope-nvim.lua`)
   - For vimExtraPlugins: use the full name with owner (e.g., `trouble-nvim-folke.lua`, `lspsaga-nvim-nvimdev.lua`)

   Example for vimExtraPlugins (e.g., `pkgs.vimExtraPlugins.trouble-nvim-folke`):
   ```lua
   -- trouble.nvim
   -- A pretty diagnostics list
   -- https://github.com/folke/trouble.nvim
   vim.cmd "packadd trouble-nvim-folke"

   require("trouble").setup({})
   ```

   Example for nixpkgs vimPlugins (e.g., `telescope-nvim`):
   ```lua
   -- telescope.nvim
   -- https://github.com/nvim-telescope/telescope.nvim
   vim.cmd "packadd telescope-nvim"

   require("telescope").setup({})
   ```

6. **Summary**: Report what was added and remind to run `darwin-rebuild switch --flake .`
