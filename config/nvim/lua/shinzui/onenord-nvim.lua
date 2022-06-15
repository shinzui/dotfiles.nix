-- onenord-nvim
-- A Neovim theme that combines the Nord and Atom One
--https://github.com/rmehri01/onenord.nvim
vim.cmd "packadd onenord-nvim"

require("onenord").setup({
  theme = "dark"
})
