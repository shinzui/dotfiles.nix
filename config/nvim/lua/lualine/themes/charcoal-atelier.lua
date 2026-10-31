-- lualine theme for the charcoal-atelier colorscheme.
-- lualine's "auto" theme picks this up whenever `vim.g.colors_name == "charcoal-atelier"`.
local p = require("charcoal-atelier").palette

return {
  normal = {
    a = { fg = p.bg, bg = p.blue, gui = "bold" },
    b = { fg = p.fg, bg = p.bg_raised },
    c = { fg = p.white, bg = p.bg_float },
  },
  insert = {
    a = { fg = p.bg, bg = p.green, gui = "bold" },
  },
  visual = {
    a = { fg = p.bg, bg = p.magenta, gui = "bold" },
  },
  replace = {
    a = { fg = p.bg, bg = p.accent, gui = "bold" },
  },
  command = {
    a = { fg = p.bg, bg = p.yellow, gui = "bold" },
  },
  terminal = {
    a = { fg = p.bg, bg = p.cyan, gui = "bold" },
  },
  inactive = {
    a = { fg = p.comment, bg = p.bg_float },
    b = { fg = p.comment, bg = p.bg_float },
    c = { fg = p.comment, bg = p.bg_float },
  },
}
