# FFF

[fff.nvim](https://github.com/dmtrKovalenko/fff.nvim) is a fast fuzzy file finder with a Rust backend for sub-10ms searches across large codebases.

## Keybindings

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>sF` | n | Open FFF file finder |

## Commands

| Command | Description |
|---------|-------------|
| `:FFFFind [path\|query]` | Open picker with optional directory or search |
| `:FFFScan` | Rescan files |
| `:FFFRefreshGit` | Update git status |
| `:FFFClearCache [all\|frecency\|files]` | Clear cache |
| `:FFFHealth` | Check dependencies |
| `:FFFDebug [on\|off\|toggle]` | Toggle score display |

## Features

- **Frecency tracking** - ranks files by recency and frequency of use
- **Typo-resistant search** - powered by frizbee fuzzy matching
- **Git integration** - status indicators in sign column
- **Multi-select** - select multiple files with quickfix integration

## Picker Keybindings

| Key | Description |
|-----|-------------|
| `<CR>` | Open file |
| `<C-s>` | Open in horizontal split |
| `<C-v>` | Open in vertical split |
| `<C-t>` | Open in new tab |
| `<Tab>` | Toggle selection |
| `<C-q>` | Send to quickfix |
| `<C-j>/<C-k>` | Navigate results |
| `<C-d>/<C-u>` | Scroll preview |
| `<F2>` | Toggle debug mode (show scores) |

## Comparison to Telescope

FFF is a standalone file picker, not a Telescope extension:

| Feature | FFF | Telescope |
|---------|-----|-----------|
| File finding | Frecency-based | Basic fuzzy |
| Search speed | Sub-10ms (Rust) | Lua-based |
| Git status | Built-in | Via extension |
| Grep/live search | No | Yes |
| LSP integration | No | Yes |

Use `<leader>sf` for Telescope and `<leader>sF` for FFF.
