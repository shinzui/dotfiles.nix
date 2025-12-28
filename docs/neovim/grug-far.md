# Grug Far

[grug-far.nvim](https://github.com/MagicDuck/grug-far.nvim) is a find and replace plugin with a visual interface.

## Keybindings

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>sro` | n | Open search/replace panel |
| `<leader>srw` | n | Search/replace with current word |

## Panel Keybindings

Inside the grug-far panel:

| Key | Description |
|-----|-------------|
| `<enter>` | Replace all matches |
| `<localleader>r` | Replace |
| `<localleader>q` | Send to quickfix |
| `<localleader>s` | Sync all |
| `<localleader>l` | Sync line |
| `<localleader>c` | Close |
| `<localleader>h` | Toggle history |
| `<localleader>?` | Toggle help |

## Usage

1. Press `<leader>sro` to open the panel
2. Enter search pattern in the first field
3. Enter replacement in the second field
4. Optionally add file glob patterns to filter
5. Press `<enter>` to execute replacement
