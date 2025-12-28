-- Leap motion plugin
-- leap.nvim
-- https://codeberg.org/andyg/leap.nvim
vim.cmd "packadd leap.nvim"

local leap = require("leap")

-- Recommended keybindings
vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap)')
vim.keymap.set('n', 'S', '<Plug>(leap-from-window)')

-- Equivalence classes for grouping similar characters
leap.opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }

-- Repeat keys for traversal without reinvoking Leap
require('leap.user').set_repeat_keys('<enter>', '<backspace>')
