## Keybindings

All telescope keybindings use `<leader>` as prefix.

### File & Buffer Navigation
| Key | Description |
|-----|-------------|
| `<C-f>` | Find files (global) |
| `<leader>f` | Find files in cwd |
| `<leader>b` | List buffers |
| `<leader>o` | Recently opened files (cwd only) |
| `<leader>l` | Fuzzy find in current buffer |

### Search
| Key | Description |
|-----|-------------|
| `<leader>g` | Live grep with args (rg) |
| `<leader>w` | Grep word under cursor |

### Git
| Key | Description |
|-----|-------------|
| `<leader>gs` | Git status |
| `<leader>gc` | Git commits |
| `<leader>gC` | Buffer commits |
| `<leader>gb` | Git branches |

### LSP
| Key | Description |
|-----|-------------|
| `<leader>S` | Workspace symbols |
| `<leader>la` | Code actions |
| `<leader>lA` | Code actions (range) |
| `<leader>ls` | Document symbols |

### Vim Introspection (`<leader>v` prefix)
| Key | Description |
|-----|-------------|
| `<leader>va` | Autocommands |
| `<leader>vc` | Commands |
| `<leader>vC` | Command history |
| `<leader>vh` | Highlights |
| `<leader>vq` | Quickfix list |
| `<leader>vl` | Location list |
| `<leader>vm` | Keymaps |
| `<leader>vs` | Spell suggestions |
| `<leader>vo` | Vim options |
| `<leader>vr` | Registers |
| `<leader>vt` | Filetypes |

### Other
| Key | Description |
|-----|-------------|
| `<leader>t` | List all telescope pickers |
| `<leader>?` | Vim help tags |

## FZF Syntax (telescope-fzf-native)

The fzf extension enables powerful fuzzy matching syntax:

| Token | Match Type | Description |
|-------|-----------|-------------|
| `sbtrkt` | fuzzy | Items that fuzzy match `sbtrkt` |
| `'wild` | exact | Items that include `wild` (exact match) |
| `^music` | prefix-exact | Items that start with `music` |
| `.mp3$` | suffix-exact | Items that end with `.mp3` |
| `!fire` | inverse-exact | Items that do not include `fire` |
| `!^music` | inverse-prefix | Items that do not start with `music` |
| `!.mp3$` | inverse-suffix | Items that do not end with `.mp3` |

### Combining Tokens

Use spaces to combine multiple tokens (AND logic):

- `^src .lua$` - files starting with `src` AND ending with `.lua`
- `config !test` - files containing `config` but NOT `test`
- `'exact ^prefix` - exact match `exact` AND starts with `prefix`

## Extensions

### telescope-live-grep-args

[telescope-live-grep-args](https://github.com/nvim-telescope/telescope-live-grep-args.nvim) allows you to supply args to [rg](https://github.com/BurntSushi/ripgrep/).

Use `^k` to quote, and `^i` to quote and insert `--iglob` option.

The `--iglob` is used to include files/directories matching the given glob pattern. The pattern specified with `--iglob` is case-insensitive.

#### Common ripgrep Flags

| Flag | Description |
|------|-------------|
| `-i` | Case insensitive search |
| `-s` | Case sensitive search |
| `-w` | Match whole words only |
| `-e` | Specify multiple patterns |
| `-t <type>` | Only search files of type (e.g., `-t lua`) |
| `-T <type>` | Exclude files of type (e.g., `-T js`) |
| `-g <glob>` | Include files matching glob |
| `--iglob <glob>` | Case-insensitive glob |
| `-F` | Treat pattern as literal string (no regex) |
| `--hidden` | Search hidden files |
| `-C <num>` | Show context lines |

#### Examples

```
"TODO" -t lua                    # Search "TODO" only in lua files
"function" --iglob **/test/**    # Search in test directories only
"import" -T test                 # Exclude test file type
"error" -i -w                    # Case-insensitive, whole word
"console\.log" -t js -t ts       # In both js and ts files
```

### telescope-undo

[telescope-undo](https://github.com/debugloop/telescope-undo.nvim/) allows you to view and search your undo tree.

Use `⌃↵` to revert to the selected state, `↵` to yank the additions to the default buffer, and `⇧↵` to yank deletions.

### telescope-manix

Search Nix documentation using [manix](https://github.com/mlvzk/manix). Access via `:Telescope manix`.

### telescope_hoogle

Search Haskell documentation via Hoogle. Access via `:Telescope hoogle`.

### jsonfly

Navigate and search JSON files. Useful for large JSON structures.

## Picker-Specific Tips

### In the Results Pane
| Key | Action |
|-----|--------|
| `<C-n>` / `<C-p>` | Next/previous result |
| `<Down>` / `<Up>` | Next/previous result |
| `<CR>` | Open selection |
| `<C-x>` | Open in horizontal split |
| `<C-v>` | Open in vertical split |
| `<C-t>` | Open in new tab |
| `<C-u>` / `<C-d>` | Scroll preview up/down |
| `<Tab>` | Toggle selection + move to next |
| `<S-Tab>` | Toggle selection + move to prev |
| `<C-q>` | Send selected to quickfix |
| `<M-q>` | Send all to quickfix |

### Workflow Tips

1. **Narrow then widen**: Start with a specific search, use FZF tokens to refine
2. **Multi-select**: Use `<Tab>` to select multiple files, then `<C-q>` to send to quickfix for batch operations
3. **Combine with live_grep_args**: Quote your pattern first (`^k`), then add rg flags
4. **Use `:Telescope resume`**: Reopen your last picker with previous query
