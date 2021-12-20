-- which-key.nvim
-- https://github.com/folke/which-key.nvim
local cmd = vim.cmd

cmd "packadd which-key.nvim"
cmd "packadd! gitsigns.nvim" -- needed for some mappings

local wk = require "which-key"
wk.setup { plugins = { spelling = { enabled = true } } }

local normal_mode_mappings = {
  s = {
    name = "+Search",
    b = { "<Cmd>Telescope file_browser<CR>", "File Browser" },

    f = { "<Cmd>Telescope find_files<CR>", "Files in cwd" },
    g = { "<Cmd>Telescope live_grep<CR>", "Grep in cwd" },
    l = { "<Cmd>Telescope current_buffer_fuzzy_find<CR>", "Buffer lines" },
    o = { "<Cmd>Telescope oldfiles<CR>", "Old files" },
    t = { "<Cmd>Telescope builtin<CR>", "Telescope lists" },
    w = { "<Cmd>Telescope grep_string<CR>", "Grep word in cwd" },
    v = {
      name = "+Vim",
      a = { "<Cmd>Telescope autocommands<CR>", "Autocommands" },
      b = { "<Cmd>Telescope buffers<CR>", "Buffers" },
      c = { "<Cmd>Telescope commands<CR>", "Commands" },
      C = { "<Cmd>Telescope command_history<CR>", "Command history" },
      h = { "<Cmd>Telescope highlights<CR>", "Highlights" },
      q = { "<Cmd>Telescope quickfix<CR>", "Quickfix list" },
      l = { "<Cmd>Telescope loclist<CR>", "Location list" },
      m = { "<Cmd>Telescope keymaps<CR>", "Keymaps" },
      s = { "<Cmd>Telescope spell_suggest<CR>", "Spell suggest" },
      o = { "<Cmd>Telescope vim_options<CR>", "Options" },
      r = { "<Cmd>Telescope registers<CR>", "Registers" },
      t = { "<Cmd>Telescope filetypes<CR>", "Filetypes" },
    },
  },
}

local normal_mode_opts = {
  mode = "n",
  prefix = "<leader>",
}

wk.register(normal_mode_mappings, normal_mode_opts)
