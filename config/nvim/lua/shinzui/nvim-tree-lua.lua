--nvim-tree.lua
--A file explorer tree for neovim written in lua
--https://github.com/kyazdani42/nvim-tree.lua

local g = vim.g

vim.cmd "packadd nvim-tree.lua"
g["nvim_tree_quit_on_open"] = 1

require("nvim-tree").setup {
  auto_close = true,
  diagnostics = {
    enable = true,
  },
  view = {
    auto_resize = true,
  },
}
