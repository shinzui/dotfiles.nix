# Tree-sitter Query Errors After Flake Update

**Date:** 2026-01-21
**Status:** Rolling back flake.lock

## Summary

After running `nix flake update`, Neovim fails with tree-sitter query errors due to version mismatches between updated grammar parsers and the bundled nvim-treesitter queries.

## Error Messages

### Error 1: `latex_block` (markdown_inline)
```
Error executing lua callback: ...d-0.11.5/share/nvim/runtime/lua/vim/treesitter/query.lua:373: Query error at 5:3. Invalid node type "latex_block":
```

**Location:** `/Users/shinzui/.local/share/nvim/site/pack/hm/opt/nvim-treesitter/runtime/queries/markdown_inline/injections.scm:5`

```scheme
((latex_block) @injection.content
  (#set! injection.language "latex")
  (#set! injection.include-children))
```

### Error 2: `uri` (comment)
```
Error executing lua callback: ...d-0.11.5/share/nvim/runtime/lua/vim/treesitter/query.lua:373: Query error at 49:2. Invalid node type "uri":
(uri) @string.special.url @nospell
```

**Location:** `/Users/shinzui/.local/share/nvim/site/pack/hm/opt/nvim-treesitter/runtime/queries/comment/highlights.scm:49`

```scheme
(uri) @string.special.url @nospell
```

## Root Cause

The nixpkgs flake update brought newer versions of tree-sitter grammars (e.g., `tree-sitter-markdown`, `tree-sitter-comment`) that have renamed or removed certain node types:

- `latex_block` → removed/renamed in tree-sitter-markdown_inline
- `uri` → removed/renamed in tree-sitter-comment

However, the nvim-treesitter plugin's bundled query files still reference the old node types, causing parsing errors.

## Affected Components

1. **nvim-treesitter.withAllGrammars** - Provides the grammars from nixpkgs
2. **nvim-treesitter runtime queries** - Located at:
   - `/Users/shinzui/.local/share/nvim/site/pack/hm/opt/nvim-treesitter/runtime/queries/`
   - `/Users/shinzui/.local/share/nvim/site/pack/hm/start/nvim-treesitter-grammars/queries/`
3. **Neovim 0.11.5 bundled queries** - Located at:
   - `/nix/store/*-neovim-unwrapped-0.11.5/share/nvim/runtime/queries/`

## Query File Locations (Runtime Priority)

Neovim loads queries from multiple paths. For `markdown_inline/highlights.scm`:
```
/Users/shinzui/.local/share/nvim/site/pack/hm/start/nvim-treesitter-grammars/queries/markdown_inline/highlights.scm
/nix/store/*-neovim-unwrapped-0.11.5/share/nvim/runtime/queries/markdown_inline/highlights.scm
```

## Attempted Fixes

### 1. Local Query Overrides (Partial Success)

Created override files in `config/nvim/after/queries/` to replace the bundled queries:

- `after/queries/markdown_inline/injections.scm` - Removed `latex_block` reference
- `after/queries/comment/highlights.scm` - Removed `uri` reference

Added symlink to `home/neovim.nix`:
```nix
xdg.configFile."nvim/after".source = mkOutOfStoreSymlink "${nixConfigDir}/config/nvim/after";
```

**Result:** Did not fully resolve the issue. The override mechanism may not be taking precedence, or there are additional query files with the same problems.

## Why Overrides May Not Work

1. **Multiple query sources:** Both nvim-treesitter and nvim-treesitter-grammars provide queries
2. **Load order:** The `after/` directory queries should take precedence, but injected queries (like comment into markdown) may bypass this
3. **Cascading errors:** Fixing one grammar reveals errors in others

## Potential Long-term Solutions

### Option 1: Pin nvim-treesitter to a Compatible Version
Use an overlay to pin nvim-treesitter to a version that matches the grammar versions.

### Option 2: Pin Tree-sitter Grammars
Use an overlay to pin specific grammars (tree-sitter-markdown, tree-sitter-comment) to older versions.

### Option 3: Wait for Upstream Fix
The nvim-treesitter project needs to update their queries to match the new grammar node types. Track:
- https://github.com/nvim-treesitter/nvim-treesitter/issues

### Option 4: Use Neovim's Built-in Tree-sitter
Neovim 0.11+ has built-in tree-sitter support. Consider using only Neovim's bundled queries instead of nvim-treesitter's.

## Rollback Instructions

```bash
cd ~/.config/dotfiles.nix
git checkout flake.lock
darwin-rebuild switch --flake .
```

## Files Created During Debugging

These can be removed after rollback:
- `config/nvim/after/queries/markdown_inline/injections.scm`
- `config/nvim/after/queries/comment/highlights.scm`

The `after` symlink in `home/neovim.nix` can also be removed if not needed.

## Related Issues

- [nvim-treesitter #3084](https://github.com/nvim-treesitter/nvim-treesitter/issues/3084) - Markdown invalid node type
- [nvim-treesitter #7342](https://github.com/nvim-treesitter/nvim-treesitter/issues/7342) - Query error invalid node type
