-- which-key.nvim
-- https://github.com/folke/which-key.nvim
local cmd = vim.cmd

cmd "packadd which-key.nvim"
cmd "packadd! gitsigns.nvim" -- needed for some mappings
cmd "packadd! nvim-spectre"

local wk = require "which-key"
wk.setup { plugins = { spelling = { enabled = true } } }

local normal_mode_mappings = {
  -- Git
  g = {
    name = "+Git",
    -- gitsigns.nvim
    h = {
      name = "+Hunks",
      s = { require("gitsigns").stage_hunk, "Stage" },
      u = { require("gitsigns").undo_stage_hunk, "Undo stage" },
      r = { require("gitsigns").reset_hunk, "Reset" },
      n = { require("gitsigns").next_hunk, "Go to next" },
      N = { require("gitsigns").prev_hunk, "Go to prev" },
      p = { require("gitsigns").preview_hunk, "Preview" },
    },
    -- telescope.nvim lists
    l = {
      name = "+Lists",
      s = { "<Cmd>Telescope git_status<CR>", "Status" },
      c = { "<Cmd>Telescope git_commits<CR>", "Commits" },
      C = { "<Cmd>Telescope git_commits<CR>", "Buffer commits" },
      b = { "<Cmd>Telescope git_branches<CR>", "Branches" },
    },
  },
  -- Language server
  l = {
    name = "+LSP",
    h = { "<Cmd>Lspsaga hover_doc<CR>", "Hover" },
    d = { vim.lsp.buf.definition, "Jump to definition" },
    D = { vim.lsp.buf.declaration, "Jump to declaration" },
    a = { "<Cmd>Lspsaga code_action<CR>", "Code action" },
    f = { vim.lsp.buf.formatting, "Format" },
    r = { "<Cmd>Lspsaga rename<CR>", "Rename" },
    t = { vim.lsp.buf.type_definition, "Jump to type definition" },
    n = { "<Cmd>Lspsaga diagnostic_jump_next<CR>", "Jump to next diagnostic" },
    N = { "<Cmd>Lspsaga diagnostic_jump_prev<CR>", "Jump to prevdiagnostic" },
    l = {
      name = "+Lists",
      a = { "<Cmd>Telescope lsp_code_actions<CR>", "Code actions" },
      A = { "<Cmd>Telescope lsp_range_code_actions<CR>", "Code actions (range)" },
      r = { "<Cmd>Telescope lsp_references<CR>", "References" },
      s = { "<Cmd>Telescope lsp_document_symbols<CR>", "Documents symbols" },
      S = { "<Cmd>Telescope lsp_workspace_symbols<CR>", "Workspace symbols" },
    },
  },
  n = {
    name = "+Navigate",
    c = { "<Cmd>HopChar2<CR>", "Hop to any occurance of 2 chars" },
    l = { "<Cmd>HopLine<CR>", "Hop to any visible line" },
    p = { "<Cmd>HopPattern<CR>", "Hop by pattern" },
  },

  s = {
    name = "+Search",
    b = { "<Cmd>Telescope file_browser<CR>", "File Browser" },

    f = { "<Cmd>Telescope find_files<CR>", "Files in cwd" },
    g = { "<Cmd>Telescope live_grep<CR>", "Grep in cwd" },
    l = { "<Cmd>Telescope current_buffer_fuzzy_find<CR>", "Buffer lines" },
    o = { "<Cmd>Telescope oldfiles<CR>", "Old files" },
    r = {
      name = "+Search/Replace",
      o = { "<CMD>lua require('spectre').open()<cr>", "Open search/replace panel" },
      w = {
        "<CMD>lua require('spectre').open_visual({select_word=true})<cr>",
        "Select current word for search/replace",
      },
    },
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
