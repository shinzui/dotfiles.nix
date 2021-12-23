-- nvim-cmp.lua
-- completion plugin
-- https://github.com/hrsh7th/nvim-cmp/
--

vim.cmd "packadd nvim-cmp"
local cmp = require "cmp"

--vscode-like pictograms for neovim lsp completion items
--https://github.com/onsails/lspkind-nvim
vim.cmd "packadd lspkind-nvim"
local lspkind = require "lspkind"

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

--cmp_luasnip
--https://github.com/saadparwaiz1/cmp_luasnip
vim.cmd "packadd cmp_luasnip"

vim.cmd "packadd luasnip"
local luasnip = require "luasnip"

vim.opt.completeopt = { "menu", "menuone", "noselect" }

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
end

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
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
    ["<CR>"] = cmp.mapping.confirm { select = true },
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  },
  sources = cmp.config.sources {
    { name = "nvim_lsp" },
    { name = "nvim_lua" },
    { name = "path" },
    { name = "emoji" },
    { name = "buffer", keyword_length = 5 },
    { name = "luasnip" },
  },
  formatting = {
    format = lspkind.cmp_format {
      with_text = true,
    },
  },
}

cmp.setup.cmdline(":", {
  sources = {
    { name = "cmdline" },
  },
})

cmp.setup.cmdline("/", {
  sources = {
    { name = "buffer" },
  },
})
