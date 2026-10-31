-- charcoal-atelier
-- A warm, muted dark colorscheme built from a terminal palette:
-- near-black background, parchment foreground, terracotta accent,
-- and dusty sage / sand / slate / mauve / teal ANSI colors.
--
-- Entry point: `:colorscheme charcoal-atelier` (see colors/charcoal-atelier.lua).
-- The palette is exported so other modules (e.g. the lualine theme) can
-- reuse it: `require("charcoal-atelier").palette`.

local M = {}

-- Base palette (straight from the terminal colour settings)

local palette = {
  bg = "#161616", -- terminal background
  fg = "#D6D2CC", -- terminal text
  accent = "#E05D3A", -- cursor
  selection = "#3A3835", -- selection background
  selection_fg = "#EFECE7", -- selected text

  -- ANSI standard
  black = "#222222",
  red = "#D96A4D",
  green = "#9AAB84",
  yellow = "#CFAE7A",
  blue = "#8AA0B4",
  magenta = "#B193A8",
  cyan = "#8FAFA8",
  white = "#B5B1AB",

  -- ANSI bright
  bright_black = "#5F5C58",
  bright_red = "#E8886E",
  bright_green = "#B3C39D",
  bright_yellow = "#E0C493",
  bright_blue = "#A4B9CC",
  bright_magenta = "#C8ADC0",
  bright_cyan = "#A8C7C0",
  bright_white = "#EFECE7",
}

-- Colour helpers

local function hex_to_rgb(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

--- Mix `color` into `base` by `alpha` (0 = base, 1 = color).
local function blend(color, base, alpha)
  local cr, cg, cb = hex_to_rgb(color)
  local br, bg, bb = hex_to_rgb(base)
  local function channel(c, b)
    return math.floor(b + (c - b) * alpha + 0.5)
  end
  return string.format("#%02X%02X%02X", channel(cr, br), channel(cg, bg), channel(cb, bb))
end

M.blend = blend

-- Derived shades (all mixed from palette colours so the theme stays coherent)

palette.bg_cursorline = blend(palette.fg, palette.bg, 0.05) -- CursorLine / ColorColumn
palette.bg_float = palette.black -- floats, popup menus, statusline
palette.bg_raised = blend(palette.fg, palette.bg, 0.10) -- menu selection, hunk headers
palette.bg_faint = blend(palette.fg, palette.bg, 0.12) -- whitespace glyphs, hidden text
palette.comment = blend(palette.fg, palette.bg, 0.48) -- comments, dimmed UI text
palette.border = palette.bright_black -- window / float borders

M.palette = palette

-- Highlight groups

local function highlights(p)
  local hl = {}

  -- Diff / diagnostic background tints
  local tint = {
    add = blend(p.green, p.bg, 0.18),
    add_strong = blend(p.green, p.bg, 0.32),
    change = blend(p.yellow, p.bg, 0.14),
    delete = blend(p.red, p.bg, 0.18),
    delete_strong = blend(p.red, p.bg, 0.32),
    text = blend(p.yellow, p.bg, 0.32),
    error = blend(p.red, p.bg, 0.12),
    warn = blend(p.yellow, p.bg, 0.12),
    info = blend(p.blue, p.bg, 0.12),
    hint = blend(p.cyan, p.bg, 0.12),
  }

  --  Editor UI
  hl.Normal = { fg = p.fg, bg = p.bg }
  hl.NormalNC = { fg = p.fg, bg = p.bg }
  hl.NormalFloat = { fg = p.fg, bg = p.bg_float }
  hl.FloatBorder = { fg = p.border, bg = p.bg_float }
  hl.FloatTitle = { fg = p.accent, bg = p.bg_float, bold = true }
  hl.FloatFooter = { fg = p.comment, bg = p.bg_float }
  hl.MsgArea = { fg = p.fg }
  hl.MsgSeparator = { fg = p.border, bg = p.bg_float }

  hl.Cursor = { fg = p.bg, bg = p.accent }
  hl.lCursor = { link = "Cursor" }
  hl.CursorIM = { link = "Cursor" }
  hl.TermCursor = { link = "Cursor" }
  hl.TermCursorNC = { fg = p.bg, bg = p.bright_black }
  hl.CursorLine = { bg = p.bg_cursorline }
  hl.CursorColumn = { link = "CursorLine" }
  hl.ColorColumn = { bg = p.bg_cursorline }
  hl.CursorLineNr = { fg = p.accent, bold = true }
  hl.CursorLineSign = { link = "SignColumn" }
  hl.CursorLineFold = { link = "FoldColumn" }
  hl.LineNr = { fg = p.bright_black }
  hl.LineNrAbove = { link = "LineNr" }
  hl.LineNrBelow = { link = "LineNr" }
  hl.SignColumn = { fg = p.bright_black, bg = p.bg }
  hl.FoldColumn = { fg = p.bright_black, bg = p.bg }
  hl.Folded = { fg = p.comment, bg = p.bg_cursorline, italic = true }

  hl.WinSeparator = { fg = p.selection, bg = p.bg }
  hl.VertSplit = { link = "WinSeparator" }
  hl.StatusLine = { fg = p.fg, bg = p.bg_float }
  hl.StatusLineNC = { fg = p.comment, bg = p.bg_float }
  hl.StatusLineTerm = { link = "StatusLine" }
  hl.StatusLineTermNC = { link = "StatusLineNC" }
  hl.WinBar = { fg = p.fg, bold = true }
  hl.WinBarNC = { fg = p.comment }
  hl.TabLine = { fg = p.white, bg = p.bg_float }
  hl.TabLineFill = { bg = p.bg_float }
  hl.TabLineSel = { fg = p.bright_white, bg = p.selection, bold = true }

  hl.Pmenu = { fg = p.fg, bg = p.bg_float }
  hl.PmenuSel = { fg = p.selection_fg, bg = p.selection, bold = true }
  hl.PmenuKind = { fg = p.white, bg = p.bg_float }
  hl.PmenuKindSel = { fg = p.selection_fg, bg = p.selection }
  hl.PmenuExtra = { fg = p.comment, bg = p.bg_float }
  hl.PmenuExtraSel = { fg = p.selection_fg, bg = p.selection }
  hl.PmenuSbar = { bg = p.bg_raised }
  hl.PmenuThumb = { bg = p.bright_black }
  hl.PmenuMatch = { fg = p.yellow, bg = p.bg_float, bold = true }
  hl.PmenuMatchSel = { fg = p.bright_yellow, bg = p.selection, bold = true }
  hl.WildMenu = { fg = p.bg, bg = p.yellow, bold = true }

  hl.Visual = { fg = p.selection_fg, bg = p.selection }
  hl.VisualNOS = { link = "Visual" }
  hl.Search = { fg = p.bg, bg = p.yellow }
  hl.CurSearch = { fg = p.bg, bg = p.accent, bold = true }
  hl.IncSearch = { link = "CurSearch" }
  hl.Substitute = { fg = p.bg, bg = p.bright_red }
  hl.MatchParen = { fg = p.accent, bg = p.selection, bold = true }
  hl.QuickFixLine = { bg = p.selection, bold = true }

  hl.NonText = { fg = p.bright_black }
  hl.Whitespace = { fg = p.bg_faint }
  hl.SpecialKey = { fg = p.bright_black }
  hl.EndOfBuffer = { fg = p.bg_faint }
  hl.Conceal = { fg = p.comment }
  hl.Directory = { fg = p.blue }
  hl.Title = { fg = p.accent, bold = true }
  hl.Question = { fg = p.green }
  hl.MoreMsg = { fg = p.green }
  hl.ModeMsg = { fg = p.fg, bold = true }
  hl.ErrorMsg = { fg = p.red, bold = true }
  hl.WarningMsg = { fg = p.yellow }
  hl.SpellBad = { sp = p.red, undercurl = true }
  hl.SpellCap = { sp = p.yellow, undercurl = true }
  hl.SpellLocal = { sp = p.cyan, undercurl = true }
  hl.SpellRare = { sp = p.magenta, undercurl = true }
  hl.healthError = { fg = p.red }
  hl.healthSuccess = { fg = p.green }
  hl.healthWarning = { fg = p.yellow }

  hl.DiffAdd = { bg = tint.add }
  hl.DiffChange = { bg = tint.change }
  hl.DiffDelete = { fg = blend(p.red, p.bg, 0.55), bg = tint.delete }
  hl.DiffText = { bg = tint.text, bold = true }
  hl.Added = { fg = p.green }
  hl.Changed = { fg = p.yellow }
  hl.Removed = { fg = p.red }
  hl.diffAdded = { link = "Added" }
  hl.diffChanged = { link = "Changed" }
  hl.diffRemoved = { link = "Removed" }
  hl.diffFile = { fg = p.blue, bold = true }
  hl.diffIndexLine = { fg = p.comment }
  hl.diffLine = { fg = p.magenta }
  hl.diffOldFile = { fg = p.red }
  hl.diffNewFile = { fg = p.green }

  --  Base syntax
  hl.Comment = { fg = p.comment, italic = true }
  hl.Constant = { fg = p.yellow }
  hl.String = { fg = p.green }
  hl.Character = { fg = p.bright_green }
  hl.Number = { fg = p.yellow }
  hl.Boolean = { fg = p.yellow }
  hl.Float = { link = "Number" }
  hl.Identifier = { fg = p.fg }
  hl.Function = { fg = p.blue }
  hl.Statement = { fg = p.magenta }
  hl.Conditional = { fg = p.magenta }
  hl.Repeat = { fg = p.magenta }
  hl.Label = { fg = p.magenta }
  hl.Operator = { fg = p.white }
  hl.Keyword = { fg = p.magenta }
  hl.Exception = { fg = p.bright_magenta }
  hl.PreProc = { fg = p.bright_magenta }
  hl.Include = { fg = p.magenta }
  hl.Define = { link = "PreProc" }
  hl.Macro = { fg = p.bright_red }
  hl.PreCondit = { link = "PreProc" }
  hl.Type = { fg = p.cyan }
  hl.StorageClass = { fg = p.cyan }
  hl.Structure = { fg = p.cyan }
  hl.Typedef = { fg = p.cyan }
  hl.Special = { fg = p.bright_red }
  hl.SpecialChar = { fg = p.bright_red }
  hl.Tag = { fg = p.accent }
  hl.Delimiter = { fg = p.white }
  hl.SpecialComment = { fg = p.comment, bold = true }
  hl.Debug = { fg = p.bright_red }
  hl.Underlined = { underline = true }
  hl.Bold = { bold = true }
  hl.Italic = { italic = true }
  hl.Ignore = { fg = p.bg }
  hl.Error = { fg = p.red }
  hl.Todo = { fg = p.bg, bg = p.yellow, bold = true }

  --  Treesitter
  hl["@variable"] = { fg = p.fg }
  hl["@variable.builtin"] = { fg = p.bright_red, italic = true }
  hl["@variable.parameter"] = { fg = p.fg, italic = true }
  hl["@variable.parameter.builtin"] = { link = "@variable.builtin" }
  hl["@variable.member"] = { fg = p.bright_blue }
  hl["@constant"] = { fg = p.yellow }
  hl["@constant.builtin"] = { fg = p.bright_yellow }
  hl["@constant.macro"] = { link = "Macro" }
  hl["@module"] = { fg = p.cyan }
  hl["@module.builtin"] = { fg = p.bright_cyan }
  hl["@label"] = { link = "Label" }

  hl["@string"] = { link = "String" }
  hl["@string.documentation"] = { fg = p.comment, italic = true }
  hl["@string.regexp"] = { fg = p.bright_red }
  hl["@string.escape"] = { fg = p.bright_red }
  hl["@string.special"] = { fg = p.bright_green }
  hl["@string.special.symbol"] = { fg = p.bright_cyan }
  hl["@string.special.path"] = { fg = p.green, underline = true }
  hl["@string.special.url"] = { fg = p.blue, underline = true }
  hl["@character"] = { link = "Character" }
  hl["@character.special"] = { link = "SpecialChar" }
  hl["@boolean"] = { link = "Boolean" }
  hl["@number"] = { link = "Number" }
  hl["@number.float"] = { link = "Float" }

  hl["@type"] = { link = "Type" }
  hl["@type.builtin"] = { fg = p.bright_cyan }
  hl["@type.definition"] = { link = "Typedef" }
  hl["@attribute"] = { fg = p.accent }
  hl["@attribute.builtin"] = { fg = p.accent }
  hl["@property"] = { fg = p.bright_blue }

  hl["@function"] = { link = "Function" }
  hl["@function.builtin"] = { fg = p.bright_blue }
  hl["@function.call"] = { link = "Function" }
  hl["@function.macro"] = { link = "Macro" }
  hl["@function.method"] = { link = "Function" }
  hl["@function.method.call"] = { link = "Function" }
  hl["@constructor"] = { fg = p.cyan, bold = true }
  hl["@operator"] = { link = "Operator" }

  hl["@keyword"] = { link = "Keyword" }
  hl["@keyword.coroutine"] = { fg = p.bright_magenta }
  hl["@keyword.function"] = { fg = p.magenta }
  hl["@keyword.operator"] = { fg = p.magenta }
  hl["@keyword.import"] = { link = "Include" }
  hl["@keyword.type"] = { fg = p.magenta }
  hl["@keyword.modifier"] = { fg = p.magenta, italic = true }
  hl["@type.qualifier"] = { link = "@keyword.modifier" }
  hl["@keyword.repeat"] = { link = "Repeat" }
  hl["@keyword.return"] = { fg = p.bright_magenta }
  hl["@keyword.debug"] = { link = "Debug" }
  hl["@keyword.exception"] = { link = "Exception" }
  hl["@keyword.conditional"] = { link = "Conditional" }
  hl["@keyword.conditional.ternary"] = { link = "Operator" }
  hl["@keyword.directive"] = { link = "PreProc" }
  hl["@keyword.directive.define"] = { link = "Define" }

  hl["@punctuation.delimiter"] = { fg = p.white }
  hl["@punctuation.bracket"] = { fg = p.white }
  hl["@punctuation.special"] = { fg = p.bright_red }

  hl["@comment"] = { link = "Comment" }
  hl["@comment.documentation"] = { link = "@string.documentation" }
  hl["@comment.error"] = { fg = p.bg, bg = p.red, bold = true }
  hl["@comment.warning"] = { fg = p.bg, bg = p.yellow, bold = true }
  hl["@comment.todo"] = { link = "Todo" }
  hl["@comment.note"] = { fg = p.bg, bg = p.blue, bold = true }

  hl["@markup.strong"] = { bold = true }
  hl["@markup.italic"] = { italic = true }
  hl["@markup.strikethrough"] = { strikethrough = true }
  hl["@markup.underline"] = { underline = true }
  hl["@markup.heading"] = { fg = p.accent, bold = true }
  hl["@markup.heading.1"] = { fg = p.accent, bold = true }
  hl["@markup.heading.2"] = { fg = p.bright_red, bold = true }
  hl["@markup.heading.3"] = { fg = p.yellow, bold = true }
  hl["@markup.heading.4"] = { fg = p.green, bold = true }
  hl["@markup.heading.5"] = { fg = p.blue, bold = true }
  hl["@markup.heading.6"] = { fg = p.magenta, bold = true }
  hl["@markup.quote"] = { fg = p.white, italic = true }
  hl["@markup.math"] = { fg = p.cyan }
  hl["@markup.link"] = { fg = p.blue }
  hl["@markup.link.label"] = { fg = p.bright_blue }
  hl["@markup.link.url"] = { fg = p.blue, underline = true }
  hl["@markup.raw"] = { fg = p.cyan }
  hl["@markup.raw.block"] = { fg = p.fg }
  hl["@markup.list"] = { fg = p.accent }
  hl["@markup.list.checked"] = { fg = p.green }
  hl["@markup.list.unchecked"] = { fg = p.comment }

  hl["@tag"] = { fg = p.accent }
  hl["@tag.builtin"] = { fg = p.bright_red }
  hl["@tag.attribute"] = { fg = p.yellow, italic = true }
  hl["@tag.delimiter"] = { fg = p.white }

  hl["@diff.plus"] = { link = "Added" }
  hl["@diff.minus"] = { link = "Removed" }
  hl["@diff.delta"] = { link = "Changed" }

  --  LSP semantic tokens
  hl["@lsp.type.class"] = { link = "@type" }
  hl["@lsp.type.comment"] = { link = "@comment" }
  hl["@lsp.type.decorator"] = { link = "@attribute" }
  hl["@lsp.type.enum"] = { link = "@type" }
  hl["@lsp.type.enumMember"] = { link = "@constant" }
  hl["@lsp.type.function"] = { link = "@function" }
  hl["@lsp.type.interface"] = { link = "@type" }
  hl["@lsp.type.keyword"] = { link = "@keyword" }
  hl["@lsp.type.macro"] = { link = "@function.macro" }
  hl["@lsp.type.method"] = { link = "@function.method" }
  hl["@lsp.type.namespace"] = { link = "@module" }
  hl["@lsp.type.number"] = { link = "@number" }
  hl["@lsp.type.operator"] = { link = "@operator" }
  hl["@lsp.type.parameter"] = { link = "@variable.parameter" }
  hl["@lsp.type.property"] = { link = "@property" }
  hl["@lsp.type.string"] = { link = "@string" }
  hl["@lsp.type.struct"] = { link = "@type" }
  hl["@lsp.type.type"] = { link = "@type" }
  hl["@lsp.type.typeParameter"] = { link = "@type" }
  hl["@lsp.type.variable"] = { link = "@variable" }
  hl["@lsp.mod.deprecated"] = { strikethrough = true }
  hl["@lsp.typemod.variable.readonly"] = { link = "@constant" }
  hl["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" }
  hl["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" }

  --  Diagnostics / LSP
  hl.DiagnosticError = { fg = p.red }
  hl.DiagnosticWarn = { fg = p.yellow }
  hl.DiagnosticInfo = { fg = p.blue }
  hl.DiagnosticHint = { fg = p.cyan }
  hl.DiagnosticOk = { fg = p.green }
  hl.DiagnosticVirtualTextError = { fg = p.red, bg = tint.error }
  hl.DiagnosticVirtualTextWarn = { fg = p.yellow, bg = tint.warn }
  hl.DiagnosticVirtualTextInfo = { fg = p.blue, bg = tint.info }
  hl.DiagnosticVirtualTextHint = { fg = p.cyan, bg = tint.hint }
  hl.DiagnosticVirtualTextOk = { fg = p.green, bg = tint.add }
  hl.DiagnosticUnderlineError = { sp = p.red, undercurl = true }
  hl.DiagnosticUnderlineWarn = { sp = p.yellow, undercurl = true }
  hl.DiagnosticUnderlineInfo = { sp = p.blue, undercurl = true }
  hl.DiagnosticUnderlineHint = { sp = p.cyan, undercurl = true }
  hl.DiagnosticUnderlineOk = { sp = p.green, undercurl = true }
  hl.DiagnosticUnnecessary = { fg = p.comment }
  hl.DiagnosticDeprecated = { sp = p.comment, strikethrough = true }
  hl.DiagnosticFloatingError = { link = "DiagnosticError" }
  hl.DiagnosticFloatingWarn = { link = "DiagnosticWarn" }
  hl.DiagnosticFloatingInfo = { link = "DiagnosticInfo" }
  hl.DiagnosticFloatingHint = { link = "DiagnosticHint" }
  hl.DiagnosticSignError = { link = "DiagnosticError" }
  hl.DiagnosticSignWarn = { link = "DiagnosticWarn" }
  hl.DiagnosticSignInfo = { link = "DiagnosticInfo" }
  hl.DiagnosticSignHint = { link = "DiagnosticHint" }
  hl.DiagnosticSignOk = { link = "DiagnosticOk" }

  hl.LspReferenceText = { bg = p.bg_raised }
  hl.LspReferenceRead = { bg = p.bg_raised }
  hl.LspReferenceWrite = { bg = blend(p.yellow, p.bg, 0.22) }
  hl.LspReferenceTarget = { bg = p.bg_raised, bold = true }
  hl.LspInlayHint = { fg = p.comment, italic = true }
  hl.LspCodeLens = { fg = p.comment, italic = true }
  hl.LspCodeLensSeparator = { fg = p.bright_black }
  hl.LspSignatureActiveParameter = { fg = p.yellow, bg = p.selection, bold = true }

  --  Plugins
  -- gitsigns.nvim
  hl.GitSignsAdd = { fg = p.green }
  hl.GitSignsChange = { fg = p.yellow }
  hl.GitSignsDelete = { fg = p.red }
  hl.GitSignsChangedelete = { fg = p.bright_red }
  hl.GitSignsTopdelete = { fg = p.red }
  hl.GitSignsUntracked = { fg = p.cyan }
  hl.GitSignsAddLn = { bg = tint.add }
  hl.GitSignsChangeLn = { bg = tint.change }
  hl.GitSignsDeleteLn = { bg = tint.delete }
  hl.GitSignsAddInline = { bg = tint.add_strong }
  hl.GitSignsChangeInline = { bg = tint.text }
  hl.GitSignsDeleteInline = { bg = tint.delete_strong }
  hl.GitSignsAddPreview = { bg = tint.add }
  hl.GitSignsDeletePreview = { bg = tint.delete }
  hl.GitSignsCurrentLineBlame = { fg = p.comment, italic = true }

  -- telescope.nvim
  hl.TelescopeNormal = { fg = p.fg, bg = p.bg }
  hl.TelescopeBorder = { fg = p.border, bg = p.bg }
  hl.TelescopePromptNormal = { fg = p.fg, bg = p.bg }
  hl.TelescopePromptBorder = { link = "TelescopeBorder" }
  hl.TelescopeResultsBorder = { link = "TelescopeBorder" }
  hl.TelescopePreviewBorder = { link = "TelescopeBorder" }
  hl.TelescopeTitle = { fg = p.accent, bold = true }
  hl.TelescopePromptTitle = { link = "TelescopeTitle" }
  hl.TelescopeResultsTitle = { link = "TelescopeTitle" }
  hl.TelescopePreviewTitle = { link = "TelescopeTitle" }
  hl.TelescopePromptPrefix = { fg = p.accent }
  hl.TelescopePromptCounter = { fg = p.comment }
  hl.TelescopeSelection = { fg = p.selection_fg, bg = p.selection, bold = true }
  hl.TelescopeSelectionCaret = { fg = p.accent, bg = p.selection }
  hl.TelescopeMultiSelection = { fg = p.magenta }
  hl.TelescopeMultiIcon = { fg = p.magenta }
  hl.TelescopeMatching = { fg = p.yellow, bold = true }
  hl.TelescopeResultsDiffAdd = { fg = p.green }
  hl.TelescopeResultsDiffChange = { fg = p.yellow }
  hl.TelescopeResultsDiffDelete = { fg = p.red }
  hl.TelescopeResultsDiffUntracked = { fg = p.cyan }
  hl.TelescopeResultsComment = { fg = p.comment }
  hl.TelescopeResultsSpecialComment = { fg = p.comment }
  hl.TelescopeResultsLineNr = { fg = p.bright_black }
  hl.TelescopePreviewLine = { bg = p.selection }
  hl.TelescopePreviewMatch = { link = "Search" }

  -- nvim-cmp
  hl.CmpItemAbbr = { fg = p.fg }
  hl.CmpItemAbbrDeprecated = { fg = p.comment, strikethrough = true }
  hl.CmpItemAbbrMatch = { fg = p.yellow, bold = true }
  hl.CmpItemAbbrMatchFuzzy = { fg = p.yellow, bold = true }
  hl.CmpItemMenu = { fg = p.comment, italic = true }
  hl.CmpItemKind = { fg = p.white }
  hl.CmpItemKindText = { fg = p.fg }
  hl.CmpItemKindMethod = { fg = p.blue }
  hl.CmpItemKindFunction = { fg = p.blue }
  hl.CmpItemKindConstructor = { fg = p.cyan }
  hl.CmpItemKindField = { fg = p.bright_blue }
  hl.CmpItemKindProperty = { fg = p.bright_blue }
  hl.CmpItemKindVariable = { fg = p.bright_blue, bold = true }
  hl.CmpItemKindClass = { fg = p.cyan }
  hl.CmpItemKindInterface = { fg = p.cyan }
  hl.CmpItemKindStruct = { fg = p.cyan }
  hl.CmpItemKindTypeParameter = { fg = p.cyan }
  hl.CmpItemKindModule = { fg = p.cyan }
  hl.CmpItemKindUnit = { fg = p.yellow }
  hl.CmpItemKindValue = { fg = p.yellow }
  hl.CmpItemKindEnum = { fg = p.yellow }
  hl.CmpItemKindEnumMember = { fg = p.yellow }
  hl.CmpItemKindConstant = { fg = p.yellow }
  hl.CmpItemKindKeyword = { fg = p.magenta }
  hl.CmpItemKindOperator = { fg = p.white }
  hl.CmpItemKindSnippet = { fg = p.bright_magenta }
  hl.CmpItemKindColor = { fg = p.bright_red }
  hl.CmpItemKindFile = { fg = p.blue }
  hl.CmpItemKindFolder = { fg = p.blue }
  hl.CmpItemKindReference = { fg = p.magenta }
  hl.CmpItemKindEvent = { fg = p.magenta }
  hl.CmpItemKindCopilot = { fg = p.green }

  -- nvim-tree.lua
  hl.NvimTreeNormal = { fg = p.fg, bg = p.bg }
  hl.NvimTreeNormalNC = { link = "NvimTreeNormal" }
  hl.NvimTreeEndOfBuffer = { fg = p.bg }
  hl.NvimTreeWinSeparator = { fg = p.selection, bg = p.bg }
  hl.NvimTreeCursorLine = { bg = p.bg_cursorline }
  hl.NvimTreeRootFolder = { fg = p.accent, bold = true }
  hl.NvimTreeFolderName = { fg = p.blue }
  hl.NvimTreeFolderIcon = { fg = p.blue }
  hl.NvimTreeOpenedFolderName = { fg = p.bright_blue }
  hl.NvimTreeOpenedFolderIcon = { fg = p.bright_blue }
  hl.NvimTreeEmptyFolderName = { fg = p.comment }
  hl.NvimTreeIndentMarker = { fg = p.selection }
  hl.NvimTreeSymlink = { fg = p.cyan }
  hl.NvimTreeExecFile = { fg = p.green }
  hl.NvimTreeImageFile = { fg = p.magenta }
  hl.NvimTreeSpecialFile = { fg = p.yellow, underline = true }
  hl.NvimTreeOpenedFile = { fg = p.bright_white }
  hl.NvimTreeModifiedFile = { fg = p.yellow }
  hl.NvimTreeGitDirty = { fg = p.yellow }
  hl.NvimTreeGitNew = { fg = p.green }
  hl.NvimTreeGitStaged = { fg = p.green }
  hl.NvimTreeGitDeleted = { fg = p.red }
  hl.NvimTreeGitMerge = { fg = p.magenta }
  hl.NvimTreeGitRenamed = { fg = p.magenta }
  hl.NvimTreeGitIgnored = { fg = p.comment }
  hl.NvimTreeLspDiagnosticsError = { link = "DiagnosticError" }
  hl.NvimTreeLspDiagnosticsWarning = { link = "DiagnosticWarn" }
  hl.NvimTreeLspDiagnosticsInformation = { link = "DiagnosticInfo" }
  hl.NvimTreeLspDiagnosticsHint = { link = "DiagnosticHint" }

  -- which-key.nvim
  hl.WhichKey = { fg = p.accent }
  hl.WhichKeyGroup = { fg = p.blue }
  hl.WhichKeyDesc = { fg = p.fg }
  hl.WhichKeySeparator = { fg = p.comment }
  hl.WhichKeyValue = { fg = p.comment }
  hl.WhichKeyFloat = { bg = p.bg_float }
  hl.WhichKeyBorder = { fg = p.border, bg = p.bg_float }
  hl.WhichKeyTitle = { fg = p.accent, bold = true }
  hl.WhichKeyIcon = { fg = p.cyan }

  -- leap.nvim
  hl.LeapMatch = { fg = p.bright_white, bold = true, underline = true }
  hl.LeapLabelPrimary = { fg = p.bg, bg = p.accent, bold = true }
  hl.LeapLabelSecondary = { fg = p.bg, bg = p.blue, bold = true }
  hl.LeapLabelSelected = { fg = p.bg, bg = p.magenta, bold = true }
  hl.LeapBackdrop = { fg = p.comment }

  -- lspsaga.nvim
  hl.SagaNormal = { fg = p.fg, bg = p.bg_float }
  hl.SagaBorder = { fg = p.border, bg = p.bg_float }
  hl.SagaTitle = { fg = p.accent, bold = true }
  hl.SagaToggle = { fg = p.comment }
  hl.SagaSep = { fg = p.selection }
  hl.SagaCount = { fg = p.bg, bg = p.yellow, bold = true }
  hl.SagaBeacon = { bg = p.accent }
  hl.SagaButton = { fg = p.fg, bg = p.bg_raised }
  hl.SagaActionTitle = { fg = p.accent, bold = true }
  hl.SagaFinderFname = { fg = p.blue }
  hl.SagaSelect = { fg = p.yellow, bold = true }
  hl.SagaVirtLine = { fg = p.selection }
  hl.SagaSpinner = { fg = p.yellow }
  hl.SagaSpinnerTitle = { fg = p.yellow, bold = true }
  hl.SagaText = { fg = p.fg }
  hl.SagaFileName = { fg = p.blue }
  hl.SagaFolderName = { fg = p.bright_blue }
  hl.SagaWinbarSep = { fg = p.comment }
  hl.SagaWinbarFileName = { fg = p.fg, bold = true }
  hl.SagaWinbarFolderName = { fg = p.blue }
  hl.SagaWinbarFileIcon = { fg = p.yellow }
  hl.SagaImpIcon = { fg = p.cyan }
  hl.CodeActionText = { fg = p.yellow }
  hl.CodeActionNumber = { fg = p.green }
  hl.RenameNormal = { link = "SagaNormal" }
  hl.RenameBorder = { link = "SagaBorder" }
  hl.HoverNormal = { link = "SagaNormal" }
  hl.HoverBorder = { link = "SagaBorder" }

  -- trouble.nvim
  hl.TroubleNormal = { fg = p.fg, bg = p.bg }
  hl.TroubleNormalNC = { link = "TroubleNormal" }
  hl.TroubleText = { fg = p.fg }
  hl.TroubleCount = { fg = p.magenta, bold = true }
  hl.TroubleCode = { fg = p.comment }
  hl.TroubleDirectory = { fg = p.comment }
  hl.TroubleFilename = { fg = p.blue }
  hl.TroubleBasename = { fg = p.blue }
  hl.TroublePos = { fg = p.comment }
  hl.TroubleSource = { fg = p.comment, italic = true }
  hl.TroubleIndent = { fg = p.selection }
  hl.TroubleIndentFoldOpen = { fg = p.bright_black }
  hl.TroubleIndentFoldClosed = { fg = p.bright_black }
  hl.TroubleIconDirectory = { fg = p.blue }
  hl.TroubleIconFile = { fg = p.fg }
  hl.TroublePreview = { bg = p.selection }

  -- neogit
  hl.NeogitNormal = { fg = p.fg, bg = p.bg }
  hl.NeogitWinSeparator = { link = "WinSeparator" }
  hl.NeogitCursorLine = { bg = p.bg_cursorline }
  hl.NeogitBranch = { fg = p.magenta, bold = true }
  hl.NeogitBranchHead = { fg = p.magenta, bold = true, underline = true }
  hl.NeogitRemote = { fg = p.green, bold = true }
  hl.NeogitObjectId = { fg = p.comment }
  hl.NeogitStash = { fg = p.comment }
  hl.NeogitTagName = { fg = p.yellow }
  hl.NeogitSectionHeader = { fg = p.accent, bold = true }
  hl.NeogitSectionHeaderCount = { fg = p.yellow }
  hl.NeogitUntrackedfiles = { fg = p.cyan, bold = true }
  hl.NeogitUnstagedchanges = { fg = p.red, bold = true }
  hl.NeogitStagedchanges = { fg = p.green, bold = true }
  hl.NeogitUnmergedchanges = { fg = p.magenta, bold = true }
  hl.NeogitUnpulledchanges = { fg = p.blue, bold = true }
  hl.NeogitUnpushedchanges = { fg = p.blue, bold = true }
  hl.NeogitRecentcommits = { fg = p.blue, bold = true }
  hl.NeogitStashes = { fg = p.comment, bold = true }
  hl.NeogitRebasing = { fg = p.yellow, bold = true }
  hl.NeogitChangeModified = { fg = p.yellow, bold = true }
  hl.NeogitChangeAdded = { fg = p.green, bold = true }
  hl.NeogitChangeDeleted = { fg = p.red, bold = true }
  hl.NeogitChangeRenamed = { fg = p.magenta, bold = true }
  hl.NeogitChangeCopied = { fg = p.magenta, bold = true }
  hl.NeogitChangeUpdated = { fg = p.yellow, bold = true }
  hl.NeogitChangeNewFile = { fg = p.green, bold = true }
  hl.NeogitChangeBothModified = { fg = p.bright_red, bold = true }
  hl.NeogitChangeUntracked = { fg = p.cyan, bold = true }
  hl.NeogitFilePath = { fg = p.blue, italic = true }
  hl.NeogitHunkHeader = { fg = p.fg, bg = p.bg_raised, bold = true }
  hl.NeogitHunkHeaderHighlight = { fg = p.bright_white, bg = p.selection, bold = true }
  hl.NeogitHunkHeaderCursor = { fg = p.bright_white, bg = p.selection, bold = true }
  hl.NeogitHunkMergeHeader = { fg = p.fg, bg = p.bg_raised, bold = true }
  hl.NeogitHunkMergeHeaderHighlight = { fg = p.bright_white, bg = p.selection, bold = true }
  hl.NeogitHunkMergeHeaderCursor = { fg = p.bright_white, bg = p.selection, bold = true }
  hl.NeogitDiffHeader = { fg = p.blue, bg = p.bg_raised, bold = true }
  hl.NeogitDiffHeaderHighlight = { fg = p.bright_blue, bg = p.selection, bold = true }
  hl.NeogitDiffContext = { fg = p.fg, bg = p.bg }
  hl.NeogitDiffContextHighlight = { fg = p.fg, bg = p.bg_cursorline }
  hl.NeogitDiffContextCursor = { fg = p.fg, bg = p.bg_cursorline }
  hl.NeogitDiffAdd = { fg = p.green, bg = tint.add }
  hl.NeogitDiffAddHighlight = { fg = p.bright_green, bg = tint.add_strong }
  hl.NeogitDiffAddCursor = { fg = p.bright_green, bg = tint.add_strong }
  hl.NeogitDiffDelete = { fg = p.red, bg = tint.delete }
  hl.NeogitDiffDeleteHighlight = { fg = p.bright_red, bg = tint.delete_strong }
  hl.NeogitDiffDeleteCursor = { fg = p.bright_red, bg = tint.delete_strong }
  hl.NeogitCommitViewHeader = { fg = p.bg, bg = p.blue, bold = true }
  hl.NeogitCommitViewDescription = { fg = p.fg, bold = true }
  hl.NeogitPopupSectionTitle = { fg = p.accent, bold = true }
  hl.NeogitPopupBranchName = { fg = p.magenta, bold = true }
  hl.NeogitPopupBold = { bold = true }
  hl.NeogitPopupActionKey = { fg = p.magenta }
  hl.NeogitPopupSwitchKey = { fg = p.magenta }
  hl.NeogitPopupOptionKey = { fg = p.magenta }
  hl.NeogitPopupConfigKey = { fg = p.magenta }
  hl.NeogitPopupSwitchEnabled = { fg = p.green }
  hl.NeogitPopupSwitchDisabled = { fg = p.comment }
  hl.NeogitPopupOptionEnabled = { fg = p.green }
  hl.NeogitPopupOptionDisabled = { fg = p.comment }
  hl.NeogitPopupConfigEnabled = { fg = p.green }
  hl.NeogitPopupConfigDisabled = { fg = p.comment }
  hl.NeogitGraphAuthor = { fg = p.yellow }
  hl.NeogitGraphRed = { fg = p.red }
  hl.NeogitGraphGreen = { fg = p.green }
  hl.NeogitGraphYellow = { fg = p.yellow }
  hl.NeogitGraphBlue = { fg = p.blue }
  hl.NeogitGraphPurple = { fg = p.magenta }
  hl.NeogitGraphCyan = { fg = p.cyan }
  hl.NeogitGraphWhite = { fg = p.fg }
  hl.NeogitGraphGray = { fg = p.comment }
  hl.NeogitGraphOrange = { fg = p.accent }
  hl.NeogitGraphBoldRed = { fg = p.red, bold = true }
  hl.NeogitGraphBoldGreen = { fg = p.green, bold = true }
  hl.NeogitGraphBoldYellow = { fg = p.yellow, bold = true }
  hl.NeogitGraphBoldBlue = { fg = p.blue, bold = true }
  hl.NeogitGraphBoldPurple = { fg = p.magenta, bold = true }
  hl.NeogitGraphBoldCyan = { fg = p.cyan, bold = true }
  hl.NeogitGraphBoldWhite = { fg = p.fg, bold = true }
  hl.NeogitGraphBoldGray = { fg = p.comment, bold = true }
  hl.NeogitGraphBoldOrange = { fg = p.accent, bold = true }
  hl.NeogitSignatureGood = { fg = p.green }
  hl.NeogitSignatureBad = { fg = p.red, bold = true }
  hl.NeogitSignatureMissing = { fg = p.magenta }
  hl.NeogitSignatureNone = { fg = p.comment }
  hl.NeogitSignatureGoodUnknown = { fg = p.blue }
  hl.NeogitSignatureGoodExpired = { fg = p.yellow }
  hl.NeogitSignatureGoodExpiredKey = { fg = p.yellow }
  hl.NeogitSignatureGoodRevokedKey = { fg = p.red }
  hl.NeogitFloatHeader = { fg = p.bg, bg = p.accent, bold = true }
  hl.NeogitFloatHeaderHighlight = { fg = p.bg, bg = p.bright_red, bold = true }

  -- diffview.nvim
  hl.DiffviewNormal = { fg = p.fg, bg = p.bg }
  hl.DiffviewCursorLine = { bg = p.bg_cursorline }
  hl.DiffviewWinSeparator = { link = "WinSeparator" }
  hl.DiffviewFilePanelTitle = { fg = p.accent, bold = true }
  hl.DiffviewFilePanelCounter = { fg = p.magenta, bold = true }
  hl.DiffviewFilePanelRootPath = { fg = p.blue, bold = true }
  hl.DiffviewFilePanelFileName = { fg = p.fg }
  hl.DiffviewFilePanelSelected = { fg = p.yellow, bold = true }
  hl.DiffviewFilePanelPath = { fg = p.comment }
  hl.DiffviewFilePanelInsertions = { fg = p.green }
  hl.DiffviewFilePanelDeletions = { fg = p.red }
  hl.DiffviewFilePanelConflicts = { fg = p.bright_red }
  hl.DiffviewFolderName = { fg = p.blue }
  hl.DiffviewFolderSign = { fg = p.comment }
  hl.DiffviewPrimary = { fg = p.accent }
  hl.DiffviewSecondary = { fg = p.blue }
  hl.DiffviewReference = { fg = p.cyan }
  hl.DiffviewHash = { fg = p.comment }
  hl.DiffviewDim1 = { fg = p.comment }
  hl.DiffviewNonText = { fg = p.bright_black }
  hl.DiffviewStatusAdded = { fg = p.green }
  hl.DiffviewStatusUntracked = { fg = p.green }
  hl.DiffviewStatusModified = { fg = p.yellow }
  hl.DiffviewStatusRenamed = { fg = p.magenta }
  hl.DiffviewStatusCopied = { fg = p.magenta }
  hl.DiffviewStatusTypeChange = { fg = p.yellow }
  hl.DiffviewStatusUnmerged = { fg = p.bright_red }
  hl.DiffviewStatusUnknown = { fg = p.comment }
  hl.DiffviewStatusDeleted = { fg = p.red }
  hl.DiffviewStatusBroken = { fg = p.red }
  hl.DiffviewStatusIgnored = { fg = p.comment }
  hl.DiffviewDiffAdd = { link = "DiffAdd" }
  hl.DiffviewDiffChange = { link = "DiffChange" }
  hl.DiffviewDiffText = { link = "DiffText" }
  hl.DiffviewDiffDelete = { fg = p.bg_faint }
  hl.DiffviewDiffAddAsDelete = { bg = tint.delete }
  hl.DiffviewDiffDeleteDim = { fg = p.bg_faint }

  -- nvim-hlslens
  hl.HlSearchNear = { fg = p.bg, bg = p.accent, bold = true }
  hl.HlSearchLens = { fg = p.comment, bg = p.bg_float }
  hl.HlSearchLensNear = { fg = p.bg, bg = p.accent }
  hl.HlSearchFloat = { link = "CurSearch" }

  -- nvim-treesitter-context
  hl.TreesitterContext = { bg = p.bg_float }
  hl.TreesitterContextLineNumber = { fg = p.bright_black, bg = p.bg_float }
  hl.TreesitterContextBottom = { sp = p.selection, underline = true }
  hl.TreesitterContextLineNumberBottom = { sp = p.selection, underline = true }
  hl.TreesitterContextSeparator = { fg = p.selection }

  -- glance.nvim
  hl.GlanceListNormal = { fg = p.fg, bg = p.bg_float }
  hl.GlancePreviewNormal = { fg = p.fg, bg = p.bg }
  hl.GlanceListFilename = { fg = p.blue }
  hl.GlanceListFilepath = { fg = p.comment }
  hl.GlanceListCount = { fg = p.magenta, bold = true }
  hl.GlanceListMatch = { fg = p.yellow, bold = true }
  hl.GlanceListCursorLine = { bg = p.selection }
  hl.GlanceListEndOfBuffer = { fg = p.bg_float, bg = p.bg_float }
  hl.GlancePreviewEndOfBuffer = { fg = p.bg, bg = p.bg }
  hl.GlancePreviewLineNr = { fg = p.bright_black }
  hl.GlancePreviewCursorLine = { bg = p.bg_cursorline }
  hl.GlancePreviewMatch = { link = "Search" }
  hl.GlanceWinBarFilename = { fg = p.fg, bg = p.bg_raised, bold = true }
  hl.GlanceWinBarFilepath = { fg = p.comment, bg = p.bg_raised }
  hl.GlanceWinBarTitle = { fg = p.accent, bg = p.bg_raised, bold = true }
  hl.GlanceBorderTop = { fg = p.selection, bg = p.bg_raised }
  hl.GlanceListBorderBottom = { fg = p.selection, bg = p.bg_float }
  hl.GlancePreviewBorderBottom = { fg = p.selection, bg = p.bg }
  hl.GlanceFoldIcon = { fg = p.bright_black }
  hl.GlanceIndent = { fg = p.selection }

  -- neotest
  hl.NeotestPassed = { fg = p.green }
  hl.NeotestFailed = { fg = p.red }
  hl.NeotestRunning = { fg = p.yellow }
  hl.NeotestSkipped = { fg = p.comment }
  hl.NeotestUnknown = { fg = p.comment }
  hl.NeotestWatching = { fg = p.yellow }
  hl.NeotestTest = { fg = p.fg }
  hl.NeotestNamespace = { fg = p.magenta }
  hl.NeotestFile = { fg = p.blue }
  hl.NeotestDir = { fg = p.blue }
  hl.NeotestFocused = { bold = true, underline = true }
  hl.NeotestIndent = { fg = p.selection }
  hl.NeotestExpandMarker = { fg = p.bright_black }
  hl.NeotestAdapterName = { fg = p.accent, bold = true }
  hl.NeotestWinSelect = { fg = p.cyan, bold = true }
  hl.NeotestMarked = { fg = p.bright_red, bold = true }
  hl.NeotestTarget = { fg = p.accent }

  -- grug-far.nvim
  hl.GrugFarHelpHeader = { fg = p.magenta }
  hl.GrugFarHelpHeaderKey = { fg = p.yellow }
  hl.GrugFarHelpWinHeader = { fg = p.accent, bold = true }
  hl.GrugFarHelpWinActionPrefix = { fg = p.comment }
  hl.GrugFarHelpWinActionText = { fg = p.fg }
  hl.GrugFarHelpWinActionKey = { fg = p.yellow }
  hl.GrugFarHelpWinActionDescription = { fg = p.comment }
  hl.GrugFarInputLabel = { fg = p.accent, bold = true }
  hl.GrugFarInputPlaceholder = { fg = p.comment, italic = true }
  hl.GrugFarResultsHeader = { fg = p.comment }
  hl.GrugFarResultsStats = { fg = p.green }
  hl.GrugFarResultsActionMessage = { fg = p.green }
  hl.GrugFarResultsMatch = { fg = p.yellow, bold = true }
  hl.GrugFarResultsMatchAdded = { fg = p.green, bold = true }
  hl.GrugFarResultsMatchRemoved = { fg = p.red, bold = true }
  hl.GrugFarResultsPath = { fg = p.blue, underline = true }
  hl.GrugFarResultsLineNo = { fg = p.comment }
  hl.GrugFarResultsLineColumn = { fg = p.comment }
  hl.GrugFarResultsNumberLabel = { fg = p.magenta }
  hl.GrugFarResultsChangeIndicator = { fg = p.yellow }
  hl.GrugFarResultsRemoveIndicator = { fg = p.red }
  hl.GrugFarResultsAddIndicator = { fg = p.green }
  hl.GrugFarResultsDiffSeparatorIndicator = { fg = p.selection }
  hl.GrugFarResultsCmdHeader = { fg = p.magenta }
  hl.GrugFarResultsNumbersSeparator = { fg = p.selection }
  hl.GrugFarResultsLongLineStr = { fg = p.comment, italic = true }

  -- symbols-outline.nvim
  hl.FocusedSymbol = { fg = p.accent, bg = p.selection, bold = true }
  hl.SymbolsOutlineConnector = { fg = p.selection }

  -- marks.nvim
  hl.MarkSignHL = { fg = p.accent }
  hl.MarkSignNumHL = { fg = p.accent }
  hl.MarkVirtTextHL = { fg = p.comment, italic = true }

  -- toggleterm.nvim
  hl.ToggleTermNormalFloat = { link = "NormalFloat" }
  hl.ToggleTermFloatBorder = { link = "FloatBorder" }

  -- zen-mode.nvim / twilight.nvim
  hl.ZenBg = { fg = p.fg, bg = p.bg }
  hl.Twilight = { fg = p.comment }

  -- git-blame.nvim (uses Comment by default; keep it explicit)
  hl.gitblame = { fg = p.comment, italic = true }

  return hl
end

-- Terminal

local function terminal_colors(p)
  vim.g.terminal_color_0 = p.black
  vim.g.terminal_color_1 = p.red
  vim.g.terminal_color_2 = p.green
  vim.g.terminal_color_3 = p.yellow
  vim.g.terminal_color_4 = p.blue
  vim.g.terminal_color_5 = p.magenta
  vim.g.terminal_color_6 = p.cyan
  vim.g.terminal_color_7 = p.white
  vim.g.terminal_color_8 = p.bright_black
  vim.g.terminal_color_9 = p.bright_red
  vim.g.terminal_color_10 = p.bright_green
  vim.g.terminal_color_11 = p.bright_yellow
  vim.g.terminal_color_12 = p.bright_blue
  vim.g.terminal_color_13 = p.bright_magenta
  vim.g.terminal_color_14 = p.bright_cyan
  vim.g.terminal_color_15 = p.bright_white
end

-- Loader

function M.load()
  if vim.g.colors_name then
    vim.cmd "highlight clear"
  end
  if vim.fn.exists "syntax_on" == 1 then
    vim.cmd "syntax reset"
  end

  vim.o.termguicolors = true
  vim.o.background = "dark"
  vim.g.colors_name = "charcoal-atelier"

  for group, spec in pairs(highlights(palette)) do
    vim.api.nvim_set_hl(0, group, spec)
  end

  terminal_colors(palette)
end

return M
