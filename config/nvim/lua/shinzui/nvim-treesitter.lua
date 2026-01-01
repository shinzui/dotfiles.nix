-- nvim-treesitter
-- https://github.com/nvim-treesitter/nvim-treesitter
-- Note: nvim-treesitter removed the configs module. Highlighting is now
-- enabled via vim.treesitter.start() which Neovim does automatically.
vim.cmd "packadd nvim-treesitter"

-- Enable treesitter-based highlighting for all filetypes except markdown
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft ~= "markdown" then
      pcall(vim.treesitter.start, args.buf)
    end
  end,
})
