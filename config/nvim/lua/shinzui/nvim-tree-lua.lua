--nvim-tree.lua
--A file explorer tree for neovim written in lua
--https://github.com/kyazdani42/nvim-tree.lua

local g = vim.g
local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

vim.cmd "packadd nvim-tree.lua"
g["nvim_tree_quit_on_open"] = 1
g["nvim_tree_disable_window_picker"] = 1
keymap("n", "-", "<cmd>NvimTreeFindFile<CR>", opts)

require("nvim-tree").setup {
  auto_close = true,
  diagnostics = {
    enable = true,
  },
  view = {
    auto_resize = true,
  },
}
