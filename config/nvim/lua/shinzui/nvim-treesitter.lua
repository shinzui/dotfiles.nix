-- nvim-treesitter
-- https://github.com/nvim-treesitter/nvim-treesitter
-- Note: nvim-treesitter removed the configs module. Highlighting is now
-- enabled via vim.treesitter.start() which Neovim does automatically.
vim.cmd "packadd nvim-treesitter"

-- Ensure nvim-treesitter query files take priority over Neovim's built-in
-- runtime queries. The nvim-treesitter grammars are newer than Neovim's
-- bundled queries, which reference removed node types (e.g. string_content
-- in lua, latex_block in markdown_inline).
--
-- Note: nixpkgs ships the parsers and queries in a separate `start` plugin
-- (pack/hm/start/nvim-treesitter-grammars), which already sorts ahead of
-- $VIMRUNTIME in 'runtimepath'. This prepend is kept as a belt-and-braces
-- guard for the plugin's own runtime files.
local ts_path = vim.fn.globpath(vim.o.packpath, "pack/hm/opt/nvim-treesitter", false)
if ts_path ~= "" then
  vim.opt.runtimepath:prepend(ts_path)
end

-- Enable treesitter-based highlighting for all filetypes.
-- Markdown needs treesitter started so that language injection works
-- for fenced code blocks (used by markview.nvim for syntax highlighting).
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})
