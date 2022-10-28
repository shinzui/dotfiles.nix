-- nvim-hlslens
-- https://github.com/kevinhwang91/nvim-hlslens
--

vim.cmd "packadd nvim-hlslens"
require('hlslens').setup()

local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

keymap("n", "n", "<Cmd>execute('normal! ' . v:count1 . 'n')<CR> <Cmd>lua require('hlslens').start()<CR>", opts)
keymap("n", "N", "> N <Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>", opts)
keymap("", "*", "<Plug>(asterisk-z*)<Cmd>lua require('hlslens').start()<CR>", {})
keymap("", "#", "<Plug>(asterisk-z#)<Cmd>lua require('hlslens').start()<CR>", {})
keymap("", "g*", "<Plug>(asterisk-gz*)<Cmd>lua require('hlslens').start()<CR>", {})
keymap("", "g#", "<Plug>(asterisk-gz#)<Cmd>lua require('hlslens').start()<CR>", {})
