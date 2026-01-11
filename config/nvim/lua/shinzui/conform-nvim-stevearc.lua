-- conform-nvim
-- https://github.com/stevearc/conform.nvim
--
vim.cmd "packadd conform-nvim-stevearc"

require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    graphql = { "prettier" },
    sql = { "pg_format" },
    yaml = { "yamlfmt" }
  },
  log_level = vim.log.levels.DEBUG,
})
