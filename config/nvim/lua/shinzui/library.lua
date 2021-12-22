local vim = vim
local _ = require "moses"

-- Clear environment
local _ENV = {}

-- Init module
local M = {}

M.symbols = {
  error = "",
  errorShape = "",
  gitBranch = "",
  ibar = "",
  info = "",
  infoShape = "",
  list = "",
  lock = "",
  pencil = "",
  question = "",
  questionShape = "",
  sepRoundLeft = "",
  sepRoundRight = "",
  spinner = "",
  term = "",
  vim = "",
  wand = "",
  warning = "",
  warningShape = "",
}

---Makes an autocommand group
---`augroup(t:{name:string, cmds:[[string]])`
---Where `cmds` is a list of autocommands of the form `{ '[event]', '[pattern]', '[cmd]' }`
function M.augroup(t)
  vim.cmd("augroup " .. t.name)
  vim.cmd "au!"
  _.eachi(t.cmds, function(v)
    vim.cmd("au " .. _.concat(v, " "))
  end)
  vim.cmd "augroup END"
end

return M
