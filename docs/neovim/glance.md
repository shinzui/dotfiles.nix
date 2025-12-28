# Glance

[glance.nvim](https://github.com/DNLHC/glance.nvim) provides a pretty preview window for LSP locations (definitions, references, etc.).

## Commands

| Command | Description |
|---------|-------------|
| `:Glance definitions` | Show definitions |
| `:Glance references` | Show references |
| `:Glance type_definitions` | Show type definitions |
| `:Glance implementations` | Show implementations |

## Preview Window Keybindings

| Key | Description |
|-----|-------------|
| `<enter>` | Jump to location |
| `o` | Jump to location |
| `<leader>l` | Open in vsplit |
| `<leader>h` | Open in split |
| `<leader>t` | Open in new tab |
| `q` | Close |
| `<esc>` | Close |
| `<tab>` | Next location |
| `<s-tab>` | Previous location |
| `<c-n>` | Next list item |
| `<c-p>` | Previous list item |

## Usage

Glance opens a floating window showing all matches with preview. Navigate between items to see the context before jumping.
