" Reuse the same vim config/colorscheme so vim and nvim look identical
set runtimepath^=~/.vim
set runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" File tree via built-in netrw — no plugin manager needed
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_winsize = 25
let g:netrw_browse_split = 4
nnoremap <silent> <C-n> :Lexplore<CR>
