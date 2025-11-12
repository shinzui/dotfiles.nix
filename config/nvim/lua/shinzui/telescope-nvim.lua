-- telescope.nvim
-- https://github.com/nvim-telescope/telescope.nvim
vim.cmd "packadd telescope.nvim"
vim.cmd "packadd telescope-symbols.nvim"
vim.cmd "packadd telescope_hoogle"
vim.cmd "packadd telescope-manix"
vim.cmd "packadd telescope-live-grep-args.nvim"
vim.cmd "packadd telescope-undo.nvim"
vim.cmd "packadd jsonfly.nvim"

local telescope = require "telescope"
local actions = require "telescope.actions"
local previewers = require "telescope.previewers"
local lga_actions = require("telescope-live-grep-args.actions")

telescope.setup {
  defaults = {
    color_devicons = true,
  },
  extensions = {
    live_grep_args = {
      -- enable/disable auto-quoting
      auto_quoting = true,
      mappings = {
        i = {
          ["<C-k>"] = lga_actions.quote_prompt(),
          ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
        },
      },
    }
  }
}

-- important to load after calling setup
telescope.load_extension('hoogle')
telescope.load_extension('manix')
telescope.load_extension('live_grep_args')
telescope.load_extension('undo')
telescope.load_extension('jsonfly')
