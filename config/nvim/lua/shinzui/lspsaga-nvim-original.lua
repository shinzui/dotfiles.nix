-- lspsaga.nvim
-- Improve lsp UI and experience
-- https://github.com/nvimdev/lspsaga.nvim
--
vim.cmd "packadd lspsaga-nvim-original"

require("lspsaga").setup({
  code_action = {
    num_shortcut = true,
    show_server_name = false,
    extend_gitsigns = true,
    keys = {
      quit = "<ESC>",
      exec = "<CR>",
    },
  },
  hover = {
    max_width = 0.6,
    open_link = 'gx',
    open_browser = '!chrome',
  },
  finder = {
    max_height = 0.5,
    min_width = 30,
    force_max_height = false,
    keys = {
      jump_to = 'p',
      expand_or_jump = '<CR>',
      vsplit = 's',
      split = 'i',
      tabe = 't',
      tabnew = 'r',
      quit = { 'q', '<ESC>' },
      close_in_preview = '<ESC>',
    },
  },
  outline = {
    auto_close = true,
    close_after_jump = true,
    keys = {
      expand_or_jump = "<CR>",
      quit = "q"
    },
  }
})

local keymap = vim.keymap.set

-- Peek definition
-- You can edit the file containing the definition in the floating window
-- It also supports open/vsplit/etc operations, do refer to "definition_action_keys"
-- It also supports tagstack
-- Use <C-t> to jump back
keymap("n", "gp", "<cmd>Lspsaga peek_definition<CR>")

-- Show cursor diagnostics
keymap("n", "<leader>sc", "<cmd>Lspsaga show_cursor_diagnostics<CR>")


-- Diagnostic jump with filters such as only jumping to an error
keymap("n", "[e", function()
  require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.ERROR })
end)
keymap("n", "]e", function()
  require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.ERROR })
end)


-- Hover Doc
-- Pressing the key twice will enter the hover window
keymap("n", "K", "<cmd>Lspsaga hover_doc<CR>")
