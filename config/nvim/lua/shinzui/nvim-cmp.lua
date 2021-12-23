-- nvim-cmp.lua
-- completion plugin
-- https://github.com/hrsh7th/nvim-cmp/
--

vim.cmd "packadd nvim-cmp"
local cmp = require "cmp"

--nvim-cmp source for nvim lua
--https://github.com/hrsh7th/cmp-nvim-lua/
vim.cmd "packadd cmp-nvim-lua"

--nvim-cmp source for vim's cmdline
--https://github.com/hrsh7th/cmp-cmdline/
vim.cmd "packadd cmp-cmdline"

--nvim-cmp source for path
--https://github.com/hrsh7th/cmp-path/
vim.cmd "packadd cmp-path"

--nvim-cmp source for emojis
--https://github.com/hrsh7th/cmp-emoji/
vim.cmd "packadd cmp-emoji"

--nvim-cmp source for buffer words
--https://github.com/hrsh7th/cmp-buffer/
vim.cmd "packadd cmp-buffer"

--nvim-cmp source for neovim builtin LSP client
--https://github.com/hrsh7th/cmp-nvim-lsp/
vim.cmd "packadd cmp-nvim-lsp"


vim.opt.completeopt = { "menu", "menuone", "noselect" }

cmp.setup {
  mapping = {
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-e>"] = cmp.mapping.close(),
    ["<c-y>"] = cmp.mapping(
      cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Insert,
        select = true,
      },
      { "i", "c" }
    ),

    ["<c-space>"] = cmp.mapping {
      i = cmp.mapping.complete(),
      c = function(
        _ --[[fallback]]
      )
        if cmp.visible() then
          if not cmp.confirm { select = true } then
            return
          end
        else
          cmp.complete()
        end
      end,
    },
  },
  sources = cmp.config.sources {
    { name = "nvim_lsp" },
    { name = "nvim_lua" },
    { name = "path" },
    { name = "emoji" },
    { name = "buffer", keyword_length = 5 },
  },
}

cmp.setup.cmdline(':', {
  sources = {
    { name = 'cmdline' }
  }
})

cmp.setup.cmdline('/', {
  sources = {
    { name = 'buffer' }
  }
})
