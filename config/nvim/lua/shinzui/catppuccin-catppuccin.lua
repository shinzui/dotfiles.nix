-- catppuccin
-- Soothing pastel theme for Neovim
-- https://github.com/catppuccin/nvim
vim.cmd "packadd catppuccin-catppuccin"

require("catppuccin").setup({
  flavour = "mocha",
  background = {
    light = "latte",
    dark = "mocha",
  },
  transparent_background = false,
  term_colors = true,
  integrations = {
    cmp = true,
    gitsigns = true,
    treesitter = true,
    telescope = {
      enabled = true,
    },
    which_key = true,
    leap = true,
    markdown = true,
    neogit = true,
    neotest = true,
    lsp_saga = true,
    native_lsp = {
      enabled = true,
    },
  },
})
