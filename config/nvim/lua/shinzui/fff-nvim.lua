-- Fast Fuzzy File Finder
-- fff.nvim
-- https://github.com/dmtrKovalenko/fff.nvim
vim.cmd "packadd fff.nvim"

require("fff").setup({
  -- Use defaults for most settings
  -- Frecency tracking enabled by default
  -- Git status integration enabled by default
})
