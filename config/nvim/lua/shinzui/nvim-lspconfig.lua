--nvim-lspconfig.lua
--Configure LSPs
--https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--
vim.cmd "packadd nvim-lspconfig"
vim.cmd "packadd cmp-nvim-lsp"

local lspconf = require "lspconfig"

local function on_attach(client, bufnr)
  local function cmd(mode, key, luacmd)
    vim.api.nvim_buf_set_keymap(bufnr, mode, key, "<cmd>lua " .. luacmd .. "<CR>", { noremap = true })
  end

  cmd("n", "gd", "vim.lsp.buf.definition()")
  cmd("n", "gD", "vim.lsp.buf.declaration()")

  if client.resolved_capabilities.hover then
    cmd("n", "K", "vim.lsp.buf.hover()")
  end

  if client.resolved_capabilities.type_definition then
    cmd("n", "gy", "vim.lsp.buf.type_definition()")
  end
  if client.resolved_capabilities.signature_help then
    cmd("n", "gt", "vim.lsp.buf.signature_help()")
  end
  if client.resolved_capabilities.code_lens then
    vim.cmd [[
       augroup lsp_codelens
        autocmd!
        autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
        autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.display()
      augroup END
      ]]
  end
end

local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

local opts = {
  on_attach = on_attach,
  capabilities = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities()),
}

local lsps = {
  hls = {},
  jsonls = {},
  rnix = {},
  dhall_lsp_server = {},
  tsserver = {},
  terraform_lsp = {},
  yamlls = {
    settings = {
      yaml = {
        format = {
          printWidth = 100,
          singleQuote = true,
        },
      },
    },
  },

  ocamllsp = {},
  sumneko_lua = {
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using (LuaJIT in the case of Neovim)
          version = "LuaJIT",
          -- Setup your lua path
          path = runtime_path,
        },
        diagnostics = {
          -- Get the language server to recognize the `vim` global
          globals = { "vim" },
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file("", true),
        },
        telemetry = {
          enable = false,
        },
      },
    },
  },
}

for lsp, lsp_opts in pairs(lsps) do
  lspconf[lsp].setup(vim.tbl_extend("force", opts, lsp_opts))
end
