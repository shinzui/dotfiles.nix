-- Distraction-free coding
-- zen-mode.nvim
-- https://github.com/folke/zen-mode.nvim
vim.cmd "packadd zen-mode-nvim-folke"

require("zen-mode").setup({
  window = {
    backdrop = 0.95,
    width = 240,
    height = 1,
    options = {
      signcolumn = "no",
      number = false,
      relativenumber = false,
      cursorline = false,
      cursorcolumn = false,
      foldcolumn = "0",
      list = false,
    },
  },
  plugins = {
    options = {
      enabled = true,
      ruler = false,
      showcmd = false,
      laststatus = 0,
    },
    twilight = { enabled = false },
    gitsigns = { enabled = false },
    tmux = { enabled = true },
    wezterm = {
      enabled = true,
      font = "+4",
    },
  },
})
