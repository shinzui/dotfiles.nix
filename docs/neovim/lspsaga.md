## lspsaga.nvim

[lspsaga.nvim](https://github.com/nvimdev/lspsaga.nvim) improves LSP UI and experience.

## Entering Floating Windows

To enter a floating window (hover doc, peek definition, etc.), press the keybind twice. For example:

- Press `K` once to show hover documentation
- Press `K` again to enter the hover window (cursor moves into it)

Once inside the floating window, you can navigate, copy text, or follow links with `gx`.

## Keybindings

| Key | Description |
|-----|-------------|
| `K` | Hover documentation (press twice to enter window) |
| `gp` | Peek definition (editable floating window) |
| `<leader>sc` | Show cursor diagnostics |
| `[e` | Jump to previous error |
| `]e` | Jump to next error |

## Finder Keys

When using `:Lspsaga finder`:

| Key | Action |
|-----|--------|
| `<CR>` | Expand or jump to location |
| `p` | Jump to location |
| `s` | Open in vertical split |
| `i` | Open in horizontal split |
| `t` | Open in tab |
| `q` / `<ESC>` | Quit finder |

## Outline Keys

When using `:Lspsaga outline`:

| Key | Action |
|-----|--------|
| `<CR>` | Expand or jump |
| `q` | Quit outline |

## Code Action

Code actions show numbered shortcuts. Press the number to execute, `<CR>` to confirm, or `<ESC>` to cancel.
