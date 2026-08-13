" invert — white-background variant of the bw colorscheme
" Distinctions are made with bold/italic/underline, not hue.

hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "invert"
set background=light

let s:black  = "#000000"
let s:fg     = "#1B1B1B"
let s:dim    = "#757575"
let s:faint  = "#AAAAAA"
let s:white  = "#FFFFFF"
let s:panel  = "#F0F0F0"

function! s:hi(group, fg, bg, attr)
  let cmd = "hi " . a:group
  if a:fg   != "" | let cmd .= " guifg=" . a:fg . " ctermfg=NONE" | endif
  if a:bg   != "" | let cmd .= " guibg=" . a:bg . " ctermbg=NONE" | endif
  if a:attr != "" | let cmd .= " gui=" . a:attr . " cterm=" . a:attr | endif
  execute cmd
endfunction

call s:hi("Normal",       s:fg,   s:white, "")
call s:hi("NonText",      s:faint,"",      "")
call s:hi("EndOfBuffer",  s:faint,"",      "")
call s:hi("Cursor",       s:white,s:black, "")
call s:hi("CursorLine",   "",     s:panel, "")
call s:hi("CursorLineNr", s:black,"",      "bold")
call s:hi("LineNr",       s:faint,"",      "")
call s:hi("Visual",       s:white,s:black, "")
call s:hi("Search",       s:white,s:black, "")
call s:hi("IncSearch",    s:white,s:dim,   "")
call s:hi("StatusLine",   s:white,s:black, "bold")
call s:hi("StatusLineNC", s:dim,  s:panel, "")
call s:hi("VertSplit",    s:faint,s:white, "")
call s:hi("Pmenu",        s:fg,   s:panel, "")
call s:hi("PmenuSel",     s:white,s:black, "bold")
call s:hi("MatchParen",   s:white,s:black, "bold")
call s:hi("ColorColumn",  "",     s:panel, "")

call s:hi("Comment",      s:dim,  "",      "italic")
call s:hi("Constant",     s:fg,   "",      "")
call s:hi("String",       s:dim,  "",      "")
call s:hi("Number",       s:fg,   "",      "")
call s:hi("Identifier",   s:fg,   "",      "")
call s:hi("Function",     s:black,"",      "bold")
call s:hi("Statement",    s:black,"",      "bold")
call s:hi("Keyword",      s:black,"",      "bold")
call s:hi("PreProc",      s:fg,   "",      "underline")
call s:hi("Type",         s:fg,   "",      "underline")
call s:hi("Special",      s:fg,   "",      "")
call s:hi("Underlined",   s:fg,   "",      "underline")
call s:hi("Todo",         s:white,s:black, "bold")
call s:hi("Error",        s:black,s:white, "bold,underline")
call s:hi("DiffAdd",      s:black,s:panel, "underline")
call s:hi("DiffDelete",   s:faint,s:white, "")
call s:hi("DiffChange",   s:fg,   s:panel, "")
call s:hi("DiffText",     s:black,s:panel, "bold")

delfunction s:hi
