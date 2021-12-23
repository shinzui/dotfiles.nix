-- nvim-spectre
-- https://github.com/nvim-pack/nvim-spectre
vim.cmd "packadd nvim-spectre"
local keymap = vim.api.nvim_set_keymap

local spectre = require('spectre')

spectre.setup {}
