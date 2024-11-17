--nvim-lspconfig.lua
--Configure LSPs
--https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--
vim.cmd "packadd nvim-lspconfig"
vim.cmd "packadd cmp-nvim-lsp"
vim.cmd "packadd vim-rescript"

local json_opts = require("shinzui.lsp.jsonls")
local hls_opts = require("shinzui.lsp.hls")
local lua_ls_opts = require("shinzui.lsp.lua_ls")
local nil_ls_opts = require("shinzui.lsp.nil_ls")
local nls_opts = require("shinzui.lsp.nls")

-- plugin which adds support for twoslash queries into typescript projects
-- https://github.com/marilari88/twoslash-queries.nvim
vim.cmd "packadd twoslash-queries-nvim"

require("twoslash-queries").setup({
  multi_line = true,
  highlight = "Type"
})

local lspconf = require "lspconfig"
local configs = require "lspconfig.configs"
local util = require "lspconfig.util"

if not configs.rescript_relay_lsp then
  configs.rescript_relay_lsp = {
    default_config = {
      cmd = { "npx", "rescript-relay-compiler", "lsp" },
      filetypes = {
        "rescript",
      },
      root_dir = util.root_pattern "relay.config.js",
    },
    settings = {},
  }
end


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

-- Copied from LunarVim
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


local default_lsp_opts = {
  on_attach = on_attach,
  capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities()),
}


local lsps = {
  hls = hls_opts,
  jsonls = json_opts,
  ls_emmet = {},
  dhall_lsp_server = {},
  graphql = {},
  ts_ls = {
    on_attach = function(client, bufnr)
      client.server_capabilities.documentFormattingProvider = false

      require("twoslash-queries").attach(client, bufnr)

      default_lsp_opts.on_attach(client, bufnr)
    end
  },
  terraformls = {},
  tailwindcss = {},
  nil_ls = nil_ls_opts,
  nickel_ls = nls_opts,
  yamlls = {
    settings = {
      yaml = {
        format = {
          printWidth = 100,
          singleQuote = true,
        },
        keyOrdering = false,
        -- schemas = {
        --   ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        -- },
      },
    },
    on_attach = function(client, bufnr)
      default_lsp_opts.on_attach(client, bufnr)
      -- disable and reset diagnostics for helm files
      if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "helm" then
        vim.diagnostic.disable(bufnr)
        vim.defer_fn(function()
          vim.diagnostic.reset(nil, bufnr)
        end, 1000)
      end
    end
  },
  rescriptls = {
    -- TODO: Figure out a better way to do this
    cmd = { "node", vim.api.nvim_get_var "rescript_lsp_path", "--stdio" },
  },
  rescript_relay_lsp = {},
  -- Legacy deprecated ocaml lsp
  ocamlls = {
    filetypes = { "reason" },
  },
  ocamllsp = {
    filetypes = { "ocaml", "ocaml.menhir", "ocaml.interface", "ocaml.ocamllex" },
  },
  lua_ls = lua_ls_opts,
}

for lsp, lsp_opts in pairs(lsps) do
  lspconf[lsp].setup(vim.tbl_extend("force", default_lsp_opts, lsp_opts))
end
