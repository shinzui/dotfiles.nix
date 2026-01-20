## lspsaga.nvim

[lspsaga.nvim](https://github.com/nvimdev/lspsaga.nvim) improves LSP UI and experience.

## Entering Floating Windows

To enter a floating window to scroll or copy text:

**Method 1: Press keybind twice**
- Press `K` once to show hover documentation
- Press `K` again to enter the hover window (cursor moves into it)

**Method 2: Use `++keep` to pin the window**
- Press `gK` to open hover and pin it to the top right
- The window stays open and you can interact with it immediately

Once inside the floating window:
- Use `j`/`k` or `<C-d>`/`<C-u>` to scroll
- Use normal yank commands to copy text
- Use `gx` to open links
- Press `q` or `<ESC>` to close

## Keybindings

| Key | Description |
|-----|-------------|
| `K` | Hover documentation (press twice to enter window) |
| `gK` | Hover documentation pinned (++keep) |
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
