-- telescope.nvim
-- https://github.com/nvim-telescope/telescope.nvim
vim.cmd "packadd telescope.nvim"
vim.cmd "packadd telescope-symbols.nvim"
vim.cmd "packadd telescope-hoogle"

local telescope = require "telescope"
local actions = require "telescope.actions"
local previewers = require "telescope.previewers"

telescope.setup {
  defaults = {
    color_devicons = true,
  },
}

telescope.load_extension('hoogle')
