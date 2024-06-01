-- trouble.nvim
-- A pretty diagnostics, references, telescope results, quickfix and location list
-- https://github.com/folke/trouble.nvim

vim.cmd "packadd trouble-nvim"
local trouble = require "trouble"

trouble.setup {}
