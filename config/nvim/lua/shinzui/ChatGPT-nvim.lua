-- ChatGPT.nvim
-- https://github.com/jackMort/ChatGPT.nvim
vim.cmd "packadd ChatGPT.nvim"

require("chatgpt").setup({
    api_key_cmd = "bat -p /Users/shinzui/.openapi_secret"
})
