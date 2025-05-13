-- direnv.nvim
vim.cmd "packadd direnv-nvim"

require("direnv").setup({
  autoload_direnv = false,
})
