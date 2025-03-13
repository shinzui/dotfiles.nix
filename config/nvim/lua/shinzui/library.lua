local vim = vim

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
  for i, v in ipairs(t.cmds) do
    vim.cmd("au " .. table.concat(v, " "))
  end
  vim.cmd "augroup END"
end

return M
