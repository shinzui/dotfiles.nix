--telescope-fzf-native.nvim
--https://github.com/nvim-telescope/telescope-fzf-native.nvim
vim.cmd "packadd telescope.nvim"
vim.cmd "packadd telescope-fzf-native.nvim"

local telescope = require "telescope"
telescope.load_extension "fzf"
