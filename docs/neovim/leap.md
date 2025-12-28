# Leap

[leap.nvim](https://codeberg.org/andyg/leap.nvim) is a motion plugin for rapid cursor movement anywhere on screen - "Neovim's answer to the mouse".

## Keybindings

| Key | Mode | Description |
|-----|------|-------------|
| `s` | n, x, o | Leap forward/backward |
| `S` | n | Leap to other windows |
| `↵` | during leap | Jump to next match |
| `⌫` | during leap | Jump to previous match |

## Usage

1. Press `s` to initiate a leap
2. Type two characters to narrow down targets
3. If multiple matches exist, type the label shown to jump
4. Use `↵`/`⌫` to cycle through matches without reinvoking

## Configuration

Equivalence classes group similar characters together:
- Whitespace: space, tab, return, newline
- Opening brackets: `([{`
- Closing brackets: `)]}`
- Quotes: `'"`

This means searching for `(` will also match `[` and `{`.

## Comparison to Hop

Leap replaces the deprecated [hop.nvim](https://github.com/phaazon/hop.nvim). Key differences:
- Two-character search instead of single character
- Cross-window jumping with `S`
- More efficient targeting with fewer keystrokes
