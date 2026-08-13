" bw — a strictly black & white colorscheme
" Distinctions are made with bold/italic/underline, not hue.

hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "bw"
set background=dark

let s:white  = "#FFFFFF"
let s:fg     = "#E4E4E4"
let s:dim    = "#8A8A8A"
let s:faint  = "#555555"
let s:black  = "#000000"
let s:panel  = "#0A0A0A"

function! s:hi(group, fg, bg, attr)
  let cmd = "hi " . a:group
  if a:fg   != "" | let cmd .= " guifg=" . a:fg . " ctermfg=NONE" | endif
  if a:bg   != "" | let cmd .= " guibg=" . a:bg . " ctermbg=NONE" | endif
  if a:attr != "" | let cmd .= " gui=" . a:attr . " cterm=" . a:attr | endif
  execute cmd
endfunction

call s:hi("Normal",       s:fg,   s:black, "")
call s:hi("NonText",      s:faint,"",      "")
call s:hi("EndOfBuffer",  s:faint,"",      "")
call s:hi("Cursor",       s:black,s:white, "")
call s:hi("CursorLine",   "",     s:panel, "")
call s:hi("CursorLineNr", s:white,"",      "bold")
call s:hi("LineNr",       s:faint,"",      "")
call s:hi("Visual",       s:black,s:white, "")
call s:hi("Search",       s:black,s:white, "")
call s:hi("IncSearch",    s:black,s:dim,   "")
call s:hi("StatusLine",   s:black,s:white, "bold")
call s:hi("StatusLineNC", s:dim,  s:panel, "")
call s:hi("VertSplit",    s:faint,s:black, "")
call s:hi("Pmenu",        s:fg,   s:panel, "")
call s:hi("PmenuSel",     s:black,s:white, "bold")
call s:hi("MatchParen",   s:black,s:white, "bold")
call s:hi("ColorColumn",  "",     s:panel, "")

call s:hi("Comment",      s:dim,  "",      "italic")
call s:hi("Constant",     s:fg,   "",      "")
call s:hi("String",       s:dim,  "",      "")
call s:hi("Number",       s:fg,   "",      "")
call s:hi("Identifier",   s:fg,   "",      "")
call s:hi("Function",     s:white,"",      "bold")
call s:hi("Statement",    s:white,"",      "bold")
call s:hi("Keyword",      s:white,"",      "bold")
call s:hi("PreProc",      s:fg,   "",      "underline")
call s:hi("Type",         s:fg,   "",      "underline")
call s:hi("Special",      s:fg,   "",      "")
call s:hi("Underlined",   s:fg,   "",      "underline")
call s:hi("Todo",         s:black,s:white, "bold")
call s:hi("Error",        s:white,s:black, "bold,underline")
call s:hi("DiffAdd",      s:white,s:panel, "underline")
call s:hi("DiffDelete",   s:faint,s:black, "")
call s:hi("DiffChange",   s:fg,   s:panel, "")
call s:hi("DiffText",     s:white,s:panel, "bold")

delfunction s:hi
