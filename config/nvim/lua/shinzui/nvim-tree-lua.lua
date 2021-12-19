--nvim-tree.lua
--A file explorer tree for neovim written in lua
--https://github.com/kyazdani42/nvim-tree.lua

vim.cmd("packadd nvim-tree.lua")

require("nvim-tree").setup({
  auto_close = true,
  diagnostics = {
    enable = true,
  },
  view = {
    auto_resize = true,
  },
})
