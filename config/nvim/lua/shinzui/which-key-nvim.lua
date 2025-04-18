-- which-key.nvim
-- https://github.com/folke/which-key.nvim

vim.cmd "packadd which-key.nvim"
vim.cmd "packadd! gitsigns.nvim" -- needed for some mappings
vim.cmd "packadd! grug-far-nvim"
vim.cmd "packadd! neotest"
vim.cmd "packadd! neotest-haskell"
vim.cmd "packadd! mini-nvim"

require('mini.icons').setup()

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
    d = { "<Cmd>DiffviewOpen<CR>", "Open Diff view" },
    n = { "<Cmd>Neogit<CR>", "Open Neogit" },
  },
  -- Language server
  l = {
    name = "+LSP",
    h = { "<Cmd>Lspsaga hover_doc<CR>", "Hover" },
    d = { vim.lsp.buf.definition, "Jump to definition" },
    D = { vim.lsp.buf.declaration, "Jump to declaration" },
    a = { "<Cmd>Lspsaga code_action<CR>", "Code action" },
    c = { "<Cmd>Lspsaga incoming_calls<CR>", "Incoming Call Hierachry"},
    s = { vim.lsp.codelens.run, "Run codelens action" },
    f = { function() vim.lsp.buf.format { async = true } end, "Format" },
    r = { "<Cmd>Lspsaga rename<CR>", "Rename" },
    t = { vim.lsp.buf.type_definition, "Jump to type definition" },
    T = { "<Cmd>SymbolsOutline<CR>", "Show symbols outline" },
    n = { "<Cmd>Lspsaga diagnostic_jump_next<CR>", "Jump to next diagnostic" },
    N = { "<Cmd>Lspsaga diagnostic_jump_prev<CR>", "Jump to prevdiagnostic" },
    o = { "<Cmd>Lspsaga outline<CR>", "Toggle outline"},
    u = { "<Cmd>Lspsaga lsp_finder<CR>", "References (usage)" },
    w = { "<Cmd>Lspsaga show_line_diagnostics<CR>", "Show line diagnostics" },
    S = { "<Cmd>Telescope lsp_dynamic_workspace_symbols<CR>", "Workspace symbols" },
    l = {
      name = "+Lists",
      a = { "<Cmd>Telescope lsp_code_actions<CR>", "Code actions" },
      A = { "<Cmd>Telescope lsp_range_code_actions<CR>", "Code actions (range)" },
      s = { "<Cmd>Telescope lsp_document_symbols<CR>", "Documents symbols" },
    },
  },
  n = {
    name = "+Navigate",
    c = { "<Cmd>HopChar2<CR>", "Hop to any occurance of 2 chars" },
    l = { "<Cmd>HopLine<CR>", "Hop to any visible line" },
    p = { "<Cmd>HopPattern<CR>", "Hop by pattern" },
  },
  r = {
    name = "+Run",
    t = {"<CMD>lua require('neotest').run.run()<CR>", "Run nearest test" },
    f = {"<CMD>lua require('neotest').run.run(vim.fn.expand('%'))<CR>", "Run tests in file" }
  },
  s = {
    name = "+Search",
    b = { "<Cmd>Telescope buffers<CR>", "Buffers" },
    f = { "<Cmd>Telescope find_files<CR>", "Files in cwd" },
    g = { "<Cmd>Telescope live_grep_args<CR>", "Grep in cwd" },
    l = { "<Cmd>Telescope current_buffer_fuzzy_find<CR>", "Buffer lines" },
    o = { "<Cmd>lua require('telescope.builtin').oldfiles({only_cwd= true})<CR>", "Old files" },
    r = {
      name = "+Search/Replace",
      o = { "<CMD>GrugFar<CR>", "Open search/replace panel" },
      w = {
        "<CMD>lua require('grug-far').with_visual_selection()<CR>",
        "Select current word for search/replace",
      },
    },
    t = { "<Cmd>Telescope builtin<CR>", "Telescope lists" },
    w = { "<Cmd>Telescope grep_string<CR>", "Grep word in cwd" },
    v = {
      name = "+Vim",
      a = { "<Cmd>Telescope autocommands<CR>", "Autocommands" },
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
    ['?'] = { '<Cmd>Telescope help_tags<CR>', 'Vim help' },
  },
  w = {
    name = "+Windows",
    -- Split creation
    s = { "<Cmd>split<CR>", "Split below" },
    v = { "<Cmd>vsplit<CR>", "Split right" },
    q = { "<Cmd>q<CR>", "Close" },
    o = { "<Cmd>only<CR>", "Close all other" },
  },
}

local normal_mode_opts = {
  mode = "n",
  prefix = "<leader>",
}

local visual_mode_mappings = {
  l = {
    name = "+LSP",
    f = { vim.lsp.buf.range_formatting, "Format range", mode = "v" },
  },
}

local visual_mode_opts = {
  mode = "v",
  prefix = "<leader>",
}

wk.register(normal_mode_mappings, normal_mode_opts)
wk.register(visual_mode_mappings, visual_mode_opts)
