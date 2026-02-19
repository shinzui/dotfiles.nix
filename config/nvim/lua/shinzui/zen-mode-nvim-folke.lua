-- Distraction-free coding
-- zen-mode.nvim
-- https://github.com/folke/zen-mode.nvim
vim.cmd "packadd zen-mode-nvim-folke"

local previous_colorscheme = nil
local previous_background = nil

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
  on_open = function(win)
    previous_colorscheme = vim.g.colors_name
    previous_background = vim.o.background
    vim.o.background = "light"
    vim.cmd("colorscheme catppuccin-latte")
    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
  end,
  on_close = function()
    vim.defer_fn(function()
      if previous_colorscheme then
        vim.cmd("highlight clear")
        vim.o.background = previous_background
        vim.cmd("colorscheme " .. previous_colorscheme)
      end
      vim.opt.wrap = false
      vim.opt.linebreak = false
    end, 50)
  end,
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
