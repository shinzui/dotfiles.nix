-- Dim inactive code
-- twilight.nvim
-- https://github.com/folke/twilight.nvim
vim.cmd "packadd twilight-nvim"

require("twilight").setup({
  dimming = {
    alpha = 0.25,
    inactive = false,
  },
  context = 10,
  treesitter = true,
  expand = {
    "function",
    "method",
    "table",
    "if_statement",
  },
})
