-- telescipe-vim-bookmarks-nvim
-- https://github.com/tom-anders/telescope-vim-bookmarks.nvim

vim.cmd "packadd telescope.nvim"
vim.cmd "packadd vim-bookmarks"
vim.cmd "packadd telescope-vim-bookmarks.nvim"

local telescope = require "telescope"
telescope.load_extension "vim_bookmarks"
