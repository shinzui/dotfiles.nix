-- Aliases

local g = vim.g
local o = vim.o
local wo = vim.wo
local opt = vim.opt
local env = vim.env
local keymap = vim.api.nvim_set_keymap


local opts = { noremap = true, silent = true }
--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
g.mapleader = " "
g.maplocalleader = ','


--which-keys doesn't work without this option
o.timeoutlen = 100 -- time to wait for a mapped sequence to complete (in milliseconds)


opt.backup = false -- don't create backup files

opt.relativenumber = true
opt.number = true

opt.expandtab = true -- expand tab to spaces
opt.tabstop = 2 --tabs are two spaces
opt.shiftwidth = 2 -- auto-indent width

opt.cmdheight = 2 --Better display for messages

opt.undofile = true -- Enable persistent undo
opt.updatetime = 300 -- Default (4000ms) is too slow

opt.mouse = "n" --allow mouse usage in normal mode

opt.hlsearch =true --highlight all matches on previous search pattern
opt.ignorecase = true --ignore case in search patterns
opt.smartcase = true

opt.wrap = false -- don't wrap lines

opt.scrolloff = 5 --number of context line above or below cursor
opt.sidescrolloff = 5 --number of context columns


opt.termguicolors = true -- -- set term gui colors

wo.signcolumn = 'yes' -- always have signcolumn open to avoid shifting




--mappings

keymap("n", "<C-f>", "<cmd>lua require('telescope.builtin').find_files()<cr>", opts)
