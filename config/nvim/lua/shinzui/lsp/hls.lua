local opts = {
  cmd = { "haskell-language-server", "--lsp" },
  settings = {
    haskell = {
      formattingProvider = "fourmolu"
    }
  }
}

return opts
