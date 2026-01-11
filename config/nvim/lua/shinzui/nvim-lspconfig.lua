-- nvim-lspconfig.lua
-- Configure LSPs using Neovim's built-in LSP client (for Neovim 0.11+)

vim.cmd "packadd nvim-lspconfig"
vim.cmd "packadd cmp-nvim-lsp"
vim.cmd "packadd vim-rescript"

local json_opts = require("shinzui.lsp.jsonls")
local hls_opts = require("shinzui.lsp.hls")
local lua_ls_opts = require("shinzui.lsp.lua_ls")
local nil_ls_opts = require("shinzui.lsp.nil_ls")
local nls_opts = require("shinzui.lsp.nls")

-- Plugin which adds support for twoslash queries into typescript projects
-- https://github.com/marilari88/twoslash-queries.nvim
vim.cmd "packadd twoslash-queries-nvim-marilari88"

require("twoslash-queries").setup({
  multi_line = true,
  highlight = "Type"
})

-- Copied from LunarVim - Setup code lens for LSP clients that support it
local function setup_code_lens(client, bufnr)
  local status_ok, codelens_supported = pcall(function()
    return client.supports_method "textDocument/codeLens"
  end)
  if not status_ok or not codelens_supported then
    return
  end
  local group = "lsp_code_lens_refresh"
  local cl_events = { "BufEnter", "InsertLeave" }
  local ok, cl_autocmds = pcall(vim.api.nvim_get_autocmds, {
    group = group,
    buffer = bufnr,
    event = cl_events,
  })

  if ok and #cl_autocmds > 0 then
    return
  end
  vim.api.nvim_create_augroup(group, { clear = false })
  vim.api.nvim_create_autocmd(cl_events, {
    group = group,
    buffer = bufnr,
    callback = function()
      vim.lsp.codelens.refresh { bufnr = bufnr }
    end,
  })
end

-- On-attach function for LSP clients
local function on_attach(client, bufnr)
  local function cmd(mode, key, luacmd)
    vim.api.nvim_buf_set_keymap(bufnr, mode, key, "<cmd>lua " .. luacmd .. "<CR>", { noremap = true })
  end

  cmd("n", "gd", "vim.lsp.buf.definition()")
  cmd("n", "gD", "vim.lsp.buf.declaration()")

  if client.server_capabilities.hoverProvider then
    cmd("n", "K", "vim.lsp.buf.hover()")
  end

  if client.server_capabilities.typeDefinitionProvider then
    cmd("n", "gy", "vim.lsp.buf.type_definition()")
  end

  if client.server_capabilities.signatureHelpProvider then
    cmd("n", "gt", "vim.lsp.buf.signature_help()")
  end
  setup_code_lens(client, bufnr)
end

-- Default capabilities for all LSP clients
local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Global default configuration for all LSP clients
vim.lsp.config('*', {
  on_attach = on_attach,
  capabilities = capabilities,
  -- Common root markers for all LSP clients
  root_markers = { '.git', '.hg' },
})

-- Configure specific language servers

-- Relay LSP for Rescript
vim.lsp.config('rescript_relay_lsp', {
  cmd = { "npx", "rescript-relay-compiler", "lsp" },
  filetypes = { "rescript" },
  root_dir = function(_, on_dir)
    on_dir(vim.fn.getcwd(), { "relay.config.js" }) 
  end,
})

-- ls_emmet support
vim.lsp.config('ls_emmet', {
  cmd = { "ls_emmet", "--stdio" },
  filetypes = {
    "html", "css", "scss", "javascript", "javascriptreact", 
    "typescript", "typescriptreact", "haml", "xml", "xsl", 
    "pug", "slim", "sass", "stylus", "less", "sss", 
    "hbs", "handlebars",
  },
  root_dir = function(_, on_dir)
    on_dir(vim.fn.getcwd())
  end,
})

-- Configure TypeScript LSP with custom on_attach
vim.lsp.config('ts_ls', {
  on_attach = function(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
    require("twoslash-queries").attach(client, bufnr)
    on_attach(client, bufnr)
  end,
})

-- Configure YAML LSP with custom on_attach
vim.lsp.config('yamlls', {
  settings = {
    yaml = {
      format = {
        printWidth = 100,
        singleQuote = true,
      },
      keyOrdering = false,
    },
  },
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    -- Disable and reset diagnostics for helm files
    if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "helm" then
      vim.diagnostic.disable(bufnr)
      vim.defer_fn(function()
        vim.diagnostic.reset(nil, bufnr)
      end, 1000)
    end
  end,
})

-- Configure Rescript LSP
vim.lsp.config('rescriptls', {
  cmd = { "node", vim.api.nvim_get_var "rescript_lsp_path", "--stdio" },
})

-- Legacy deprecated ocaml lsp
vim.lsp.config('ocamlls', {
  filetypes = { "reason" },
})

vim.lsp.config('ocamllsp', {
  filetypes = { "ocaml", "ocaml.menhir", "ocaml.interface", "ocaml.ocamllex" },
})

vim.lsp.config('relay_lsp', {
  cmd = { "bunx", "relay-compiler", "lsp"}
})

vim.lsp.config('oxlint', {
  cmd = { "bunx", "oxc_language_server" }
})

-- Configure language servers with custom options
vim.lsp.config('hls', hls_opts)
vim.lsp.config('jsonls', json_opts)
vim.lsp.config('lua_ls', lua_ls_opts)
vim.lsp.config('nil_ls', nil_ls_opts)
vim.lsp.config('nickel_ls', nls_opts)

-- Enable LSP clients
local lsp_servers = {
  'hls',
  'jsonls',
  'ls_emmet',
  'dhall_lsp_server',
  'graphql',
  'ts_ls',
  'terraformls',
  'tailwindcss',
  'nil_ls',
  'nickel_ls',
  'yamlls',
  'rescriptls',
  'rescript_relay_lsp',
  'ocamlls',
  'ocamllsp',
  'lua_ls',
  'relay_lsp',
  'oxlint'
}

-- Enable all configured language servers
for _, lsp in ipairs(lsp_servers) do
  vim.lsp.enable(lsp)
end
