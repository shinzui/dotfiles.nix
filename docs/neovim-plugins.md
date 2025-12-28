# Adding Neovim Plugins

This guide explains how to add neovim plugins to this nix-based setup. Plugins are managed through home-manager with Lua configuration files.

## Architecture Overview

```
flake.nix                              # Plugin sources (vimExtraPlugins overlay)
    ↓
home/neovim.nix                        # Plugin declarations
    ↓
config/nvim/lua/shinzui/<plugin>.lua   # Plugin configuration (Lua)
```

## Plugin Categories

Plugins are organized into three categories based on their configuration needs:

### 1. Basic Plugins (No Configuration)

Plugins that work out of the box without any setup:

```nix
# home/neovim.nix
programs.neovim.plugins = with pkgs.vimPlugins; [
  nord-nvim
  vim-surround
  vim-repeat
  # Add your plugin here
];
```

### 2. Optional Plugins (Lazy-loaded, No Config File)

Plugins that should be lazy-loaded but don't need a dedicated config file:

```nix
] ++ map optionalPlugin [
  telescope-symbols-nvim
  cmp-nvim-lsp
  # Add your plugin here
];
```

### 3. Configured Plugins (With Lua Config)

Plugins that need custom configuration. Each plugin gets a corresponding Lua file:

```nix
] ++ map pluginWithConfig [
  gitsigns-nvim       # → config/nvim/lua/shinzui/gitsigns-nvim.lua
  comment-nvim        # → config/nvim/lua/shinzui/comment-nvim.lua
  # Add your plugin here
];
```

## Step-by-Step: Adding a Plugin

### Step 1: Find the Plugin Package

Check if the plugin exists in nixpkgs:

```bash
# Search nixpkgs
nix search nixpkgs vimPlugins.<plugin-name>

# Or check the vim plugins list
nix-env -qaP -A nixpkgs.vimPlugins | grep -i <plugin-name>
```

### Step 2: Add to neovim.nix

Edit `home/neovim.nix` and add the plugin to the appropriate category.

**Example: Adding a basic plugin**

```nix
programs.neovim.plugins = with pkgs.vimPlugins; [
  nord-nvim
  vim-surround
  your-new-plugin    # ← Add here
];
```

**Example: Adding a configured plugin**

```nix
] ++ map pluginWithConfig [
  gitsigns-nvim
  your-new-plugin    # ← Add here
];
```

### Step 3: Create Lua Config (for configured plugins)

Create `config/nvim/lua/shinzui/<plugin-pname>.lua`:

```lua
-- Plugin description
-- plugin-name
-- https://github.com/author/plugin-name
vim.cmd "packadd plugin-name"

require("plugin-name").setup({
  -- your configuration here
})
```

**Important:** The filename must match the plugin's `pname` with `.` replaced by `-`.

### Step 4: Rebuild

```bash
darwin-rebuild switch --flake .
```

## Plugin Sources

### Standard nixpkgs (Most Common)

```nix
programs.neovim.plugins = with pkgs.vimPlugins; [
  telescope-nvim
  nvim-cmp
];
```

### vimExtraPlugins (Extended Collection)

For plugins not in nixpkgs, use the `nix-neovimplugins` overlay:

```nix
] ++ map pluginWithConfig [
  pkgs.vimExtraPlugins.lspsaga-nvim
  pkgs.vimExtraPlugins.trouble-nvim
  pkgs.vimExtraPlugins.conform-nvim
];
```

Browse available plugins: https://github.com/jooooscha/nixpkgs-vim-extra-plugins

## Handling Dependencies

Use `pluginWithDeps` for plugins that require other plugins:

```nix
] ++ map pluginWithConfig [
  (pluginWithDeps nvim-tree-lua [ nvim-web-devicons ])
  (pluginWithDeps telescope-nvim [ nvim-web-devicons ])
  (pluginWithDeps neotest [ neotest-haskell nvim-nio ])
];
```

For optional plugins with dependencies:

```nix
] ++ map optionalPlugin [
  (pluginWithDeps cmp_luasnip [ luasnip ])
  (pluginWithDeps lualine-lsp-progress [ lualine-nvim ])
];
```

## Extra Configuration

### Passing Variables to Lua

Use `pluginWithConfigAndExtraConfig` to set variables before loading the Lua config:

```nix
] ++ [
  (pluginWithConfigAndExtraConfig
    "lua vim.api.nvim_set_var('my_var','some_value')"
    my-plugin)
];
```

### Adding Extra Packages

Some plugins need external tools. Add them to `extraPackages`:

```nix
programs.neovim.extraPackages = with pkgs; [
  gcc                                    # For treesitter compilation
  nodePackages.typescript                # For TypeScript LSP
  nodePackages.typescript-language-server
];
```

## Lua Configuration Pattern

### Minimal Config

```lua
-- Plugin description
-- plugin-name
-- https://github.com/author/plugin-name
vim.cmd "packadd plugin-name"

require("plugin-name").setup()
```

### Config with Options

```lua
-- Gitsigns
-- gitsigns.nvim
-- https://github.com/lewis6991/gitsigns.nvim
vim.cmd "packadd gitsigns.nvim"

require("gitsigns").setup {
  signs = {
    add = { text = "+" },
    change = { text = "~" },
  },
}
```

### Config with Keymaps

Add keymaps to `config/nvim/lua/shinzui/which-key-nvim.lua` for discoverability:

```lua
-- In which-key-nvim.lua
local mappings = {
  g = {
    name = "Git",
    s = { "<cmd>Gitsigns stage_hunk<CR>", "Stage hunk" },
    r = { "<cmd>Gitsigns reset_hunk<CR>", "Reset hunk" },
  },
}
```

## Complete Example

Adding `nvim-autopairs`:

**1. Edit `home/neovim.nix`:**

```nix
] ++ map pluginWithConfig [
  gitsigns-nvim
  nvim-autopairs    # ← Add here
];
```

**2. Create `config/nvim/lua/shinzui/nvim-autopairs.lua`:**

```lua
-- Auto pairs
-- nvim-autopairs
-- https://github.com/windwp/nvim-autopairs
vim.cmd "packadd nvim-autopairs"

require("nvim-autopairs").setup({
  check_ts = true,  -- Use treesitter
  fast_wrap = {},
})
```

**3. Rebuild:**

```bash
darwin-rebuild switch --flake .
```

## Helper Functions Reference

| Function | Purpose |
|----------|---------|
| `optionalPlugin` | Mark plugin as optional (lazy-loaded) |
| `pluginWithConfig` | Auto-load matching Lua config file |
| `pluginWithConfigAndExtraConfig` | Load config with extra vimscript setup |
| `pluginWithDeps` | Declare plugin dependencies |

## Troubleshooting

### Plugin Not Found

Check if it exists in nixpkgs or vimExtraPlugins:

```bash
# Search nixpkgs
nix search nixpkgs vimPlugins.<name>

# Check vimExtraPlugins repo
# https://github.com/jooooscha/nixpkgs-vim-extra-plugins
```

### Lua Config Not Loading

Ensure the filename matches the plugin's `pname`:
- Plugin: `gitsigns-nvim` → File: `gitsigns-nvim.lua`
- Plugin: `nvim-tree-lua` → File: `nvim-tree-lua.lua`

### Missing Dependencies

Add system packages to `extraPackages` or plugin deps via `pluginWithDeps`.

## File Locations

| Component | Path |
|-----------|------|
| Plugin declarations | `home/neovim.nix` |
| Lua init | `config/nvim/lua/init.lua` |
| Plugin configs | `config/nvim/lua/shinzui/<plugin>.lua` |
| LSP configs | `config/nvim/lua/shinzui/lsp/*.lua` |
| Keybindings | `config/nvim/lua/shinzui/which-key-nvim.lua` |
