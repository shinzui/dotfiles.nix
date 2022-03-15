--nvim-tree.lua
--A file explorer tree for neovim written in lua
--https://github.com/kyazdani42/nvim-tree.lua

local g = vim.g
local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

vim.cmd "packadd nvim-tree.lua"
keymap("n", "-", "<cmd>NvimTreeFindFile<CR>", opts)

require("nvim-tree").setup {
  auto_close = false,
  actions = {
    open_file = {
      quit_on_open = true
    },
  },
  diagnostics = {
    enable = true,
  },
  view = {
    auto_resize = true,
  },
}
