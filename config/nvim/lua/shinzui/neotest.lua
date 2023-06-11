-- neotest
-- https://github.com/nvim-neotest/neotest#usage
--
-- neotest adapters
-- ---------------
-- neotest-haskell
-- https://github.com/MrcJkb/neotest-haskell
--
vim.cmd "packadd neotest"
vim.cmd "packadd neotest-haskell"

require("neotest").setup {
  adapters = {
    require("neotest-haskell")
  }
}
