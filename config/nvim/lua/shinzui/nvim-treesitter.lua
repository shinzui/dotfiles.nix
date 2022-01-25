-- nvim-treesitter
-- https://github.com/nvim-treesitter/nvim-treesitter
vim.cmd "packadd nvim-treesitter"

require("nvim-treesitter.configs").setup {
  ensure_installed = "all",
  ignore_install = { "php", "phpdoc" },
  highlight = { enable = true, disable = { "markdown" } },
  incremental_selection = { enable = true },
  indent = { enable = true },
  compilers = { "gcc" },
}
