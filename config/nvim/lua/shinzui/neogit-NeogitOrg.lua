-- neogit
-- magit for neovim
-- https://github.com/TimUntersberger/neogit
vim.cmd "packadd neogit-NeogitOrg"

local neogit = require "neogit"
neogit.setup {
  disable_commit_confirmation = true,
  integrations = {
    diffview = true,
  },
}
