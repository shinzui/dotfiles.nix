-- nvim-lint
-- https://github.com/mfussenegger/nvim-lint
--
vim.cmd "packadd nvim-lint-mfussenegger"

require('lint').linters_by_ft = {
  yaml = { 'yamllint' },
}
