-- lspsaga.nvim
-- A light-weight lsp plugin based on neovim built-in lsp with highly a performant UI.
-- https://github.com/tami5/lspsaga.nvim
local lib = require "shinzui.library"
local s = lib.symbols
local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }
vim.cmd "packadd lspsaga-nvim"

require("lspsaga").init_lsp_saga {
  use_saga_diagnostic_sign = true,
  error_sign = s.error,
  warn_sign = s.warning,
  infor_sign = s.info,
  hint_sign = s.question,
  diagnostic_header_icon = "  ",
  code_action_icon = " ",
  code_action_prompt = {
    enable = true,
    sign = false,
    sign_priority = 20,
    virtual_text = true,
  },
  code_action_keys = {
    quit = "<ESC>",
    exec = "<CR>",
  },
  rename_action_keys = {
    quit = "<ESC>",
    exec = "<CR>",
  },
  rename_prompt_prefix = "❯",
}

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  virtual_text = true,
  signs = true,
  update_in_insert = false,
})

lib.augroup {
  name = "LSP",
  cmds = {
    { "CursorHold", "*", "lua require'lspsaga.diagnostic'.show_line_diagnostics()" },
  },
}

keymap("n", "[e", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts)
keymap("n", "]e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts)
