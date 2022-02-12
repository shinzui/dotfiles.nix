--nvim-lspconfig.lua
--Configure LSPs
--https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--
vim.cmd "packadd nvim-lspconfig"
vim.cmd "packadd cmp-nvim-lsp"
vim.cmd "packadd vim-rescript"

local lspconf = require "lspconfig"
local configs = require "lspconfig.configs"

--Add support for ls_emmet since emmet_ls is broken
if not configs.ls_emmet then
  configs.ls_emmet = {
    default_config = {
      cmd = { "ls_emmet", "--stdio" },
      filetypes = {
        "html",
        "css",
        "scss",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "haml",
        "xml",
        "xsl",
        "pug",
        "slim",
        "sass",
        "stylus",
        "less",
        "sss",
        "hbs",
        "handlebars",
      },
      root_dir = function(fname)
        return vim.loop.cwd()
      end,
      settings = {},
    },
  }
end

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

  --Disable tsserver formatting since we're using prettier
  if client.name == "tsserver" then
    client.resolved_capabilities.document_formatting = false
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
  ls_emmet = {},
  dhall_lsp_server = {},
  graphql = {},
  tsserver = {},
  terraform_lsp = {},
  rnix = {},
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

  rescriptls = {
    -- TODO: Figure out a better way to do this
    cmd = { "node", vim.api.nvim_get_var "rescript_lsp_path", "--stdio" },
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
