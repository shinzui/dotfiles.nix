--nvim-treesitter-context.lua
-- Show code context
-- https://github.com/nvim-treesitter/nvim-treesitter-context
--
vim.cmd "packadd nvim-treesitter-context"


require'treesitter-context'.setup{
  enable = true
}
