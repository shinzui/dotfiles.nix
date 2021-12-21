--nvim-lspconfig.lua
--Configure LSPs
--https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--
vim.cmd 'packadd nvim-lspconfig'

local lspconf = require 'lspconfig'

lspconf.hls.setup {}
lspconf.jsonls.setup {}
lspconf.rnix.setup {}
lspconf.dhall_lsp_server.setup{}
lspconf.tsserver.setup {}
lspconf.yamlls.setup {
  settings = {
    yaml = {
      format = {
        printWidth = 100,
        singleQuote = true,
      },
    },
  },
}

