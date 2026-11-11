# Colorschemes

The default colorscheme is `charcoal-atelier`. It is applied by `vim.cmd.colorscheme("charcoal-atelier")` at the end of `config/nvim/lua/shinzui/onenord-nvim.lua`, right after `require("onenord").setup()` (which applies onenord itself). That file runs after `init.lua` during startup and before lualine's setup, so lualine's `auto` theme picks up the matching theme.

Other colorschemes are installed but not applied, so they are available with `:colorscheme <name>`:

| Name | Source | Notes |
|------|--------|-------|
| `onenord` | plugin | Configured with custom highlights; overridden at startup |
| `catppuccin` | plugin | Configured for the `mocha` flavour; `catppuccin-latte` is used by zen-mode |
| `charcoal-atelier` | `config/nvim/colors/charcoal-atelier.lua` | Default. Custom, built from the terminal palette below |

## charcoal-atelier

A warm, muted dark theme matching the terminal colours. Palette and highlight groups live in `config/nvim/lua/charcoal-atelier/init.lua`; the entry point `config/nvim/colors/charcoal-atelier.lua` makes it discoverable by `:colorscheme charcoal-atelier`. A matching lualine theme lives in `config/nvim/lua/lualine/themes/charcoal-atelier.lua` and is picked up automatically by lualine's `auto` theme.

| Role | Hex |
|------|-----|
| Background | `#161616` |
| Foreground | `#D6D2CC` |
| Accent (cursor, titles, current line number) | `#E05D3A` |
| Selection | `#3A3835` |
| Black / bright | `#222222` / `#5F5C58` |
| Red / bright | `#D96A4D` / `#E8886E` |
| Green / bright | `#9AAB84` / `#B3C39D` |
| Yellow / bright | `#CFAE7A` / `#E0C493` |
| Blue / bright | `#8AA0B4` / `#A4B9CC` |
| Magenta / bright | `#B193A8` / `#C8ADC0` |
| Cyan / bright | `#8FAFA8` / `#A8C7C0` |
| White / bright | `#B5B1AB` / `#EFECE7` |

Syntax roles: keywords are magenta, functions blue, strings green, numbers and constants yellow, types cyan, builtins and escapes bright red, comments a dimmed foreground. Diff and diagnostic backgrounds are blended from the palette at load time rather than hand-picked.

Highlight groups are defined for the plugins in use (telescope, nvim-cmp, nvim-tree, which-key, leap, lspsaga, trouble, neogit, diffview, gitsigns, hlslens, glance, neotest, grug-far, symbols-outline, treesitter-context, zen-mode). `:terminal` colours are set to the ANSI palette.

### Trying it without a rebuild

`~/.config/nvim/lua` is a live symlink into this repo, so the module can be loaded directly in a running Neovim:

```vim
:lua require("charcoal-atelier").load()
```

`:colorscheme charcoal-atelier` needs the `nvim/colors` symlink from `home/neovim.nix`, which requires a `darwin-rebuild switch --flake .`.

### Changing the default

Edit the `vim.cmd.colorscheme(...)` call at the end of `config/nvim/lua/shinzui/onenord-nvim.lua` (or remove it to fall back to onenord). Don't set it in `init.lua`: that runs before the plugin configs, so onenord's `setup()` would override it.
