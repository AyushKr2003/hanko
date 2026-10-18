-- Hanko 判子 for Neovim (Kaze 風, docs/kaze mockup 12): the editor on the
-- bar's paper. Read from the current Omarchy theme each time it is applied,
-- so it follows `omarchy theme set`. Keywords in ink, strings in muted
-- italic, comments faint, errors red, the cursor a bone block; the eight
-- ANSI colours stay quiet. Red is only for errors and "now".
package.loaded["hanko.ink"] = nil
local ok, Ink = pcall(require, "hanko.ink")
if not ok then return end
local c = Ink.current()

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.o.background = c.light and "light" or "dark"
vim.o.termguicolors = true
vim.g.colors_name = "hanko"

local sel = Ink.mix(c.bone, c.paper, 0.18)
local raised = Ink.mix(c.bone, c.paper, c.light and 0.05 or 0.06)
local warn = Ink.mix(c.seal, c.inkDim, 0.45)

local groups = {
  Normal = { fg = c.inkDim, bg = c.paper },
  NormalNC = { fg = c.inkDim, bg = c.paper },
  NormalFloat = { fg = c.inkDim, bg = c.paper },
  FloatBorder = { fg = c.line, bg = c.paper },
  FloatTitle = { fg = c.ink, bg = c.paper, bold = true },
  WinSeparator = { fg = c.line },
  VertSplit = { fg = c.line },
  EndOfBuffer = { fg = c.paper },
  Cursor = { fg = c.paper, bg = c.bone },
  lCursor = { link = "Cursor" },
  TermCursor = { link = "Cursor" },
  CursorLine = { bg = raised },
  CursorColumn = { bg = raised },
  ColorColumn = { bg = raised },
  CursorLineNr = { fg = c.seal },
  LineNr = { fg = c.line },
  SignColumn = { bg = c.paper },
  FoldColumn = { fg = c.line },
  Folded = { fg = c.inkMuted, bg = raised },
  Visual = { bg = sel },
  VisualNOS = { bg = sel },
  Search = { fg = c.paper, bg = c.inkMuted },
  IncSearch = { fg = c.paper, bg = c.bone },
  CurSearch = { link = "IncSearch" },
  Substitute = { fg = c.paper, bg = c.seal },
  MatchParen = { fg = c.ink, bold = true, underline = true },
  NonText = { fg = c.line },
  Whitespace = { fg = c.line },
  SpecialKey = { fg = c.line },
  Conceal = { fg = c.inkFaint },
  Pmenu = { fg = c.inkDim, bg = raised },
  PmenuSel = { fg = c.paper, bg = c.bone },
  PmenuSbar = { bg = raised },
  PmenuThumb = { bg = c.line },
  StatusLine = { fg = c.inkDim, bg = raised },
  StatusLineNC = { fg = c.inkFaint, bg = c.paper },
  TabLine = { fg = c.inkFaint, bg = c.paper },
  TabLineSel = { fg = c.paper, bg = c.bone },
  TabLineFill = { bg = c.paper },
  WinBar = { fg = c.inkMuted },
  WinBarNC = { fg = c.inkFaint },
  Title = { fg = c.ink, bold = true },
  Directory = { fg = c.ink },
  Question = { fg = c.ink },
  MoreMsg = { fg = c.inkDim },
  ModeMsg = { fg = c.ink },
  ErrorMsg = { fg = c.seal },
  WarningMsg = { fg = warn },
  WildMenu = { link = "PmenuSel" },
  QuickFixLine = { bg = sel },

  -- Code: shape over colour.
  Comment = { fg = c.inkFaint, italic = true },
  Constant = { fg = c.ink },
  String = { fg = c.inkMuted, italic = true },
  Character = { link = "String" },
  Number = { fg = c.ink },
  Boolean = { fg = c.ink },
  Float = { link = "Number" },
  Identifier = { fg = c.inkDim },
  Function = { fg = c.ink },
  Statement = { fg = c.ink, bold = true },
  Keyword = { fg = c.ink, bold = true },
  Conditional = { link = "Keyword" },
  Repeat = { link = "Keyword" },
  Label = { link = "Keyword" },
  Exception = { link = "Keyword" },
  Operator = { fg = c.inkMuted },
  PreProc = { fg = c.inkDim, bold = true },
  Include = { link = "PreProc" },
  Define = { link = "PreProc" },
  Macro = { link = "PreProc" },
  Type = { fg = c.ink, italic = true },
  StorageClass = { link = "Keyword" },
  Structure = { link = "Type" },
  Typedef = { link = "Type" },
  Special = { fg = c.inkDim },
  Delimiter = { fg = c.inkFaint },
  SpecialComment = { fg = c.inkMuted, italic = true },
  Underlined = { underline = true },
  Todo = { fg = c.paper, bg = c.inkMuted, bold = true },
  Error = { fg = c.seal },

  ["@variable"] = { fg = c.inkDim },
  ["@variable.builtin"] = { fg = c.ink, italic = true },
  ["@variable.member"] = { fg = c.inkDim },
  ["@property"] = { fg = c.inkDim },
  ["@function.builtin"] = { fg = c.ink, italic = true },
  ["@constructor"] = { fg = c.ink },
  ["@punctuation"] = { fg = c.inkFaint },
  ["@punctuation.bracket"] = { fg = c.inkFaint },
  ["@punctuation.delimiter"] = { fg = c.inkFaint },
  ["@tag"] = { fg = c.ink },
  ["@tag.attribute"] = { fg = c.inkMuted },
  ["@tag.delimiter"] = { fg = c.inkFaint },
  ["@markup.heading"] = { fg = c.ink, bold = true },
  ["@markup.strong"] = { bold = true },
  ["@markup.italic"] = { italic = true },
  ["@markup.link"] = { fg = c.inkDim, underline = true },
  ["@markup.raw"] = { fg = c.inkMuted },
  ["@comment.error"] = { fg = c.seal, bold = true },
  ["@comment.warning"] = { fg = warn, bold = true },
  ["@comment.todo"] = { link = "Todo" },

  -- Diagnostics: red is the error; the rest are inks.
  DiagnosticError = { fg = c.seal },
  DiagnosticWarn = { fg = warn },
  DiagnosticInfo = { fg = c.inkDim },
  DiagnosticHint = { fg = c.inkMuted },
  DiagnosticOk = { fg = c.inkDim },
  DiagnosticUnderlineError = { undercurl = true, sp = c.seal },
  DiagnosticUnderlineWarn = { undercurl = true, sp = warn },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.inkMuted },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.inkFaint },
  DiagnosticVirtualTextError = { fg = c.seal, italic = true },
  DiagnosticVirtualTextWarn = { fg = warn, italic = true },
  DiagnosticVirtualTextInfo = { fg = c.inkFaint, italic = true },
  DiagnosticVirtualTextHint = { fg = c.inkFaint, italic = true },

  -- Diffs and git: added in ink, changed muted, removed red.
  DiffAdd = { bg = Ink.mix(c.bone, c.paper, 0.1) },
  DiffChange = { bg = raised },
  DiffDelete = { fg = c.seal, bg = Ink.mix(c.seal, c.paper, 0.1) },
  DiffText = { bg = sel },
  Added = { fg = c.ink },
  Changed = { fg = c.inkMuted },
  Removed = { fg = c.seal },
  GitSignsAdd = { fg = c.inkDim },
  GitSignsChange = { fg = c.inkFaint },
  GitSignsDelete = { fg = c.seal },

  -- Plugins LazyVim ships.
  SnacksDashboardHeader = { fg = c.seal },
  SnacksDashboardKey = { fg = c.ink },
  SnacksDashboardDesc = { fg = c.inkDim },
  SnacksDashboardIcon = { fg = c.inkMuted },
  SnacksDashboardFooter = { fg = c.inkFaint },
  SnacksIndent = { fg = c.lineSoft },
  SnacksIndentScope = { fg = c.line },
  SnacksPickerMatch = { fg = c.ink, bold = true },
  SnacksPickerDir = { fg = c.inkFaint },
  WhichKey = { fg = c.ink },
  WhichKeyGroup = { fg = c.inkDim, italic = true },
  WhichKeyDesc = { fg = c.inkDim },
  WhichKeySeparator = { fg = c.inkFaint },
  BlinkCmpMenu = { link = "Pmenu" },
  BlinkCmpMenuSelection = { link = "PmenuSel" },
  BlinkCmpLabelMatch = { fg = c.ink, bold = true },
  NeoTreeNormal = { fg = c.inkDim, bg = c.paper },
  NeoTreeDirectoryName = { fg = c.ink },
  NeoTreeRootName = { fg = c.ink, bold = true },
  MiniStatuslineModeNormal = { fg = c.paper, bg = c.bone, bold = true },
  MiniStatuslineModeInsert = { fg = c.paper, bg = c.seal, bold = true },
  MiniStatuslineModeVisual = { fg = c.paper, bg = c.inkMuted, bold = true },
}

for name, spec in pairs(groups) do vim.api.nvim_set_hl(0, name, spec) end

-- The terminal's sixteen colours: quiet inks, red kept for red.
local term = { c.paper, c.seal, c.inkDim, c.inkMuted, c.inkDim, c.inkMuted, c.inkDim, c.inkDim,
               c.inkFaint, c.seal, c.ink, c.inkDim, c.ink, c.inkDim, c.ink, c.ink }
for i, col in ipairs(term) do vim.g["terminal_color_" .. (i - 1)] = col end

-- lualine, if present, gets a matching theme (normal mode a bone plate,
-- insert the seal: "now").
local lualine = {
  normal = { a = { fg = c.paper, bg = c.bone, gui = "bold" }, b = { fg = c.inkDim, bg = raised }, c = { fg = c.inkMuted, bg = c.paper } },
  insert = { a = { fg = c.paper, bg = c.seal, gui = "bold" } },
  visual = { a = { fg = c.paper, bg = c.inkMuted, gui = "bold" } },
  replace = { a = { fg = c.paper, bg = c.seal, gui = "bold" } },
  command = { a = { fg = c.paper, bg = c.ink, gui = "bold" } },
  inactive = { a = { fg = c.inkFaint, bg = c.paper }, b = { fg = c.inkFaint, bg = c.paper }, c = { fg = c.inkFaint, bg = c.paper } },
}
package.loaded["lualine.themes.hanko"] = lualine
