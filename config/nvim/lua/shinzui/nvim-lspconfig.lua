--nvim-lspconfig.lua
--Configure LSPs
--https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--
vim.cmd "packadd nvim-lspconfig"
vim.cmd "packadd cmp-nvim-lsp"

local lspconf = require "lspconfig"
local capabilities = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities())

lspconf.hls.setup {
  capabilities = capabilities,
}
lspconf.jsonls.setup {
  capabilities = capabilities,
}
lspconf.rnix.setup {
  capabilities = capabilities,
}
lspconf.dhall_lsp_server.setup {
  capabilities = capabilities,
}
lspconf.tsserver.setup {
  capabilities = capabilities,
}

lspconf.terraform_lsp.setup{}

lspconf.yamlls.setup {
  capabilities = capabilities,
  settings = {
    yaml = {
      format = {
        printWidth = 100,
        singleQuote = true,
      },
    },
  },
}
local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
lspconf.sumneko_lua.setup {
  capabilities = capabilities,
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
}
