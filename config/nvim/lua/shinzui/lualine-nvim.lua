--lualine-nvim
--
--https://github.com/nvim-lualine/lualine.nvim
vim.cmd "packadd lualine.nvim"

--https://github.com/arkav/lualine-lsp-progress
vim.cmd "packadd lualine-lsp-progress"

require("lualine").setup {
  sections = {
    lualine_c = {
      "filename",
      "lsp_progress",
    },
  },
}
