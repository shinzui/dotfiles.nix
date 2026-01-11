-- direnv.nvim
vim.cmd "packadd direnv-nvim-notashelf"

require("direnv").setup({
  autoload_direnv = false,
})
