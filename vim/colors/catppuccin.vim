" catppuccin — Mocha palette, matches kitty/polybar/i3 theme-catppuccin

hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "catppuccin"
set background=dark

let s:rosewater = "#F5E0DC"
let s:pink      = "#F5C2E7"
let s:mauve     = "#CBA6F7"
let s:red       = "#F38BA8"
let s:peach     = "#FAB387"
let s:yellow    = "#F9E2AF"
let s:green     = "#A6E3A1"
let s:teal      = "#94E2D5"
let s:blue      = "#89B4FA"
let s:text      = "#CDD6F4"
let s:subtext1  = "#BAC2DE"
let s:overlay1  = "#7F849C"
let s:overlay0  = "#6C7086"
let s:surface2  = "#585B70"
let s:surface1  = "#45475A"
let s:surface0  = "#313244"
let s:base      = "#1E1E2E"
let s:mantle    = "#181825"

function! s:hi(group, fg, bg, attr)
  let cmd = "hi " . a:group
  if a:fg   != "" | let cmd .= " guifg=" . a:fg . " ctermfg=NONE" | endif
  if a:bg   != "" | let cmd .= " guibg=" . a:bg . " ctermbg=NONE" | endif
  if a:attr != "" | let cmd .= " gui=" . a:attr . " cterm=" . a:attr | endif
  execute cmd
endfunction

call s:hi("Normal",       s:text,    s:base,    "")
call s:hi("NonText",      s:overlay0,"",        "")
call s:hi("EndOfBuffer",  s:overlay0,"",        "")
call s:hi("Cursor",       s:base,    s:rosewater,"")
call s:hi("CursorLine",   "",        s:surface0,"")
call s:hi("CursorLineNr", s:rosewater,"",       "bold")
call s:hi("LineNr",       s:overlay0,"",        "")
call s:hi("Visual",       "",        s:surface2,"")
call s:hi("Search",       s:base,    s:yellow,  "")
call s:hi("IncSearch",    s:base,    s:peach,   "")
call s:hi("StatusLine",   s:base,    s:mauve,   "bold")
call s:hi("StatusLineNC", s:overlay1,s:mantle,  "")
call s:hi("VertSplit",    s:surface1,s:base,    "")
call s:hi("Pmenu",        s:text,    s:surface0,"")
call s:hi("PmenuSel",     s:base,    s:mauve,   "bold")
call s:hi("MatchParen",   s:base,    s:peach,   "bold")
call s:hi("ColorColumn",  "",        s:surface0,"")

call s:hi("Comment",      s:overlay1,"",        "italic")
call s:hi("Constant",     s:peach,   "",        "")
call s:hi("String",       s:green,   "",        "")
call s:hi("Number",       s:peach,   "",        "")
call s:hi("Identifier",   s:subtext1,"",        "")
call s:hi("Function",     s:blue,    "",        "bold")
call s:hi("Statement",    s:mauve,   "",        "bold")
call s:hi("Keyword",      s:mauve,   "",        "bold")
call s:hi("PreProc",      s:pink,    "",        "")
call s:hi("Type",         s:yellow,  "",        "")
call s:hi("Special",      s:teal,    "",        "")
call s:hi("Underlined",   s:blue,    "",        "underline")
call s:hi("Todo",         s:base,    s:yellow,  "bold")
call s:hi("Error",        s:base,    s:red,     "bold")
call s:hi("DiffAdd",      s:base,    s:green,   "")
call s:hi("DiffDelete",   s:overlay0,s:surface0,"")
call s:hi("DiffChange",   s:text,    s:surface0,"")
call s:hi("DiffText",     s:base,    s:yellow,  "bold")

delfunction s:hi
