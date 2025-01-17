-- which-key.nvim
-- https://github.com/folke/which-key.nvim

vim.cmd "packadd which-key.nvim"
vim.cmd "packadd! gitsigns.nvim" -- needed for some mappings
vim.cmd "packadd! nvim-spectre"
vim.cmd "packadd! neotest"
vim.cmd "packadd! neotest-haskell"
vim.cmd "packadd! mini-nvim"

require('mini.icons').setup()

local wk = require("which-key")

wk.setup {
  plugins = {
    spelling = { enabled = true, suggestions = 20 },
    presets = {
      operators = true,
      motions = true,
      text_objects = true,
      windows = true,
      nav = true,
      z = true,
      g = true
    },
  },
  icons = {
    breadcrumb = "»",
    separator = "➜",
    group = "+"
  },
  win = {
    border = "single",
    position = "bottom",
    margin = { 1, 0, 1, 0 },
    padding = { 2, 2, 2, 2 }
  },
  layout = {
    height = { min = 4, max = 25 },
    width = { min = 20, max = 50 },
    spacing = 5
  }
}

wk.add {
  -- Groups
  { "<leader>g",   group = "+Git" },
  { "<leader>l",   group = "+LSP" },
  { "<leader>n",   group = "+Navigate" },
  { "<leader>r",   group = "+Run" },
  { "<leader>s",   group = "+Search" },
  { "<leader>w",   group = "+Windows" },
  -- Git Commands
  { "<leader>gh",  group = "+Hunks" },
  { "<leader>ghs", "<cmd>lua require('gitsigns').stage_hunk()<CR>",                        desc = "Stage Hunk" },
  { "<leader>ghu", "<cmd>lua require('gitsigns').undo_stage_hunk()<CR>",                   desc = "Undo Stage" },
  { "<leader>ghr", "<cmd>lua require('gitsigns').reset_hunk()<CR>",                        desc = "Reset Hunk" },
  { "<leader>ghn", "<cmd>lua require('gitsigns').next_hunk()<CR>",                         desc = "Next Hunk" },
  { "<leader>ghp", "<cmd>lua require('gitsigns').prev_hunk()<CR>",                         desc = "Previous Hunk" },
  { "<leader>ghP", "<cmd>lua require('gitsigns').preview_hunk()<CR>",                      desc = "Preview Hunk" },
  { "<leader>gl",  group = "+Lists" },
  { "<leader>gls", "<cmd>Telescope git_status<CR>",                                        desc = "Git Status" },
  { "<leader>glc", "<cmd>Telescope git_commits<CR>",                                       desc = "Git Commits" },
  { "<leader>glb", "<cmd>Telescope git_branches<CR>",                                      desc = "Git Branches" },
  { "<leader>gd",  "<cmd>DiffviewOpen<CR>",                                                desc = "Open Diff View" },
  { "<leader>gn",  "<cmd>Neogit<CR>",                                                      desc = "Open Neogit" },

  -- LSP Commands
  { "<leader>ll",  group = "Lists" },
  { "<leader>llA", "<Cmd>Telescope lsp_range_code_actions<CR>",                            desc = "Code actions (range)" },
  { "<leader>lla", "<Cmd>Telescope lsp_code_actions<CR>",                                  desc = "Code actions" },
  { "<leader>lls", "<Cmd>Telescope lsp_document_symbols<CR>",                              desc = "Documents symbols" },
  { "<leader>ln",  "<Cmd>Lspsaga diagnostic_jump_next<CR>",                                desc = "Jump to next diagnostic" },
  { "<leader>lo",  "<Cmd>Lspsaga outline<CR>",                                             desc = "Toggle outline" },
  { "<leader>lr",  "<Cmd>Lspsaga rename<CR>",                                              desc = "Rename" },
  { "<leader>ls",  function() vim.lsp.codelens.run() end,                                  desc = "Run codelens action" },
  { "<leader>lt",  function() vim.lsp.buf.type_definition() end,                           desc = "Jump to type definition" },
  { "<leader>lu",  "<Cmd>Lspsaga lsp_finder<CR>",                                          desc = "References (usage)" },
  { "<leader>lw",  "<Cmd>Lspsaga show_line_diagnostics<CR>",                               desc = "Show line diagnostics" },

  -- Navigate Commands
  { "<leader>nc",  "<Cmd>HopChar2<CR>",                                                    desc = "Hop to any occurrence of 2 chars" },
  { "<leader>nl",  "<Cmd>HopLine<CR>",                                                     desc = "Hop to any visible line" },
  { "<leader>np",  "<Cmd>HopPattern<CR>",                                                  desc = "Hop by pattern" },

  -- Run Commands
  { "<leader>rt",  "<cmd>lua require('neotest').run.run()<CR>",                            desc = "Run nearest test" },
  { "<leader>rf",  "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<CR>",          desc = "Run tests in file" },

  -- Search Commands
  { "<leader>sb",  "<cmd>Telescope buffers<CR>",                                           desc = "Search Buffers" },
  { "<leader>sf",  "<cmd>Telescope find_files<CR>",                                        desc = "Find Files" },
  { "<leader>sg",  "<cmd>Telescope live_grep<CR>",                                         desc = "Live Grep" },
  { "<leader>sl",  "<cmd>Telescope current_buffer_fuzzy_find<CR>",                         desc = "Search Current Buffer" },
  { "<leader>so",  "<cmd>lua require('telescope.builtin').oldfiles({only_cwd= true})<CR>", desc = "Search Old Files" },
  { "<leader>sr",  group = "+Search/Replace" },
  { "<leader>sro", "<cmd>lua require('spectre').open()<CR>",                               desc = "Open Spectre" },
  { "<leader>srw", "<cmd>lua require('spectre').open_visual({select_word=true})<CR>",      desc = "Select Word for Search/Replace" },

  -- Windows Commands
  { "<leader>ws",  "<cmd>split<CR>",                                                       desc = "Split Below" },
  { "<leader>wv",  "<cmd>vsplit<CR>",                                                      desc = "Vertical Split" },
  { "<leader>wq",  "<cmd>close<CR>",                                                       desc = "Close Window" },
  { "<leader>wo",  "<cmd>only<CR>",                                                        desc = "Close Other Windows" },
}
