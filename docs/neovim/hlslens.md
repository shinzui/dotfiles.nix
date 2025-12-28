# Hlslens

[nvim-hlslens](https://github.com/kevinhwang91/nvim-hlslens) enhances search with a virtual text lens showing match count and position.

## Keybindings

| Key | Mode | Description |
|-----|------|-------------|
| `n` | n | Next match (with lens) |
| `N` | n | Previous match (with lens) |
| `*` | n, v | Search word forward (stay in place) |
| `#` | n, v | Search word backward (stay in place) |
| `g*` | n, v | Search partial word forward |
| `g#` | n, v | Search partial word backward |

## Features

- Shows `[x/y]` indicator next to matches (current/total)
- Integrates with vim-asterisk for improved star search
- Cursor stays in place when using `*` and `#` (asterisk-z behavior)

## Usage

1. Press `/` or `?` to search, or use `*`/`#` on a word
2. Navigate with `n`/`N` to see match counts
3. Virtual text appears showing your position in the match list
