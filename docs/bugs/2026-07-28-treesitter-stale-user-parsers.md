# Tree-sitter Query Errors From Stale User-Installed Parsers

**Date:** 2026-07-28
**Status:** Fixed

## Summary

Neovim failed with tree-sitter query errors (`latex_block`, `string_content`)
that looked like the recurring "flake update broke the grammars" problem
documented in [2026-01-21](./2026-01-21-treesitter-query-errors.md). It wasn't.

The real cause was 82 hand-installed parsers from **2021–2022** in
`~/.local/share/nvim/site/parser/`, left over from old `:TSInstall` runs.
That directory sits *earlier* in `runtimepath` than the Nix-provided
plugins, so those ancient `.so` files shadowed the current ones. The queries
came from nvim-treesitter (nixpkgs, 2026-07-23) while the parsers were four
years old — so the queries referenced node types the parsers had never heard of.

## Error Messages

```
Query error at 5:3. Invalid node type "latex_block":
Query error at 50:17. Invalid node type "string_content":
```

## Diagnosis

`vim.api.nvim_get_runtime_file("parser/lua.*", true)` showed the shadowing:

```
/Users/shinzui/.local/share/nvim/site/parser/lua.so                          <- stale, 2022
/Users/shinzui/.local/share/nvim/site/pack/hm/start/nvim-treesitter-grammars/parser/lua.so
/nix/store/...-neovim-unwrapped-0.12.4/lib/nvim/parser/lua.so
```

Confirmed by re-running with a temporary `XDG_DATA_HOME` containing only a
symlink to `site/pack` — both query errors vanished and `bin/test-treesitter.sh`
passed.

## Fix

Moved the stale directories out of the runtime path:

```
~/.local/share/nvim/site/parser      -> ~/.local/share/nvim/stale-parsers-backup-20260728/parser
~/.local/share/nvim/site/parser-info -> ~/.local/share/nvim/stale-parsers-backup-20260728/parser-info
```

Kept as a backup rather than deleted. Once you're satisfied, remove the backup.

## Why the previous workaround didn't help

`config/nvim/after/queries/markdown_inline/injections.scm` existed to strip the
`latex_block` rule. It never took effect: Neovim's
`vim.treesitter.query.get_files()` uses the **first non-`;; extends` file** in
runtimepath, and `after/` sorts *last*. `get_files("markdown_inline",
"injections")` returned only the grammars-plugin file; the override was never
read. It was also treating a symptom — with correct parsers the markdown_inline
grammar does have `latex_block`. Removed.

To genuinely override a query, the file must sort *earlier* in runtimepath
(e.g. `~/.config/nvim/queries/...`), not in `after/`.

## Lesson

`~/.local/share/nvim/site/` is unmanaged user state that survives every
`darwin-rebuild switch`. When treesitter breaks after a nixpkgs bump, check for
shadowing parsers there *before* concluding the grammars and queries are
out of sync in nixpkgs.
