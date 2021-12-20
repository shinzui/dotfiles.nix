-- Aliases

local g = vim.g
local o = vim.o
local env = vim.env
local keymap = vim.api.nvim_set_keymap


local opts = { noremap = true, silent = true }
--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
g.mapleader = " "
g.maplocalleader = ','


--which-keys doesn't work without this option
o.timeoutlen = 100 -- time to wait for a mapped sequence to complete (in milliseconds)
