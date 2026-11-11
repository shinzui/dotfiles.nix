-- onenord-nvim
-- A Neovim theme that combines the Nord and Atom One
--https://github.com/rmehri01/onenord.nvim
vim.cmd "packadd onenord.nvim"
local colors = require("onenord.colors").load()

require("onenord").setup({
  theme = "dark",
  custom_highlights = {
    CmpItemKindVariable = { fg = colors.dark_blue, style = "bold" }
  }
})

-- onenord's setup() applies itself; switch to the default colorscheme afterwards.
-- onenord stays available via `:colorscheme onenord`.
vim.cmd.colorscheme("charcoal-atelier")
