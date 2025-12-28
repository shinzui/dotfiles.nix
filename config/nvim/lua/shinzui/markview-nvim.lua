-- Markdown previewer
-- markview.nvim
-- https://github.com/OXY2DEV/markview.nvim
vim.cmd "packadd markview.nvim"

require("markview").setup({
  preview = {
    icon_provider = "devicons",
  },
})
