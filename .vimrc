" Key bindings
set term=builtin_ansi
set timeout
set timeoutlen=100
set ttimeoutlen=100

" Formatting
" set autoindent
set smartindent
set tabstop=4
set softtabstop=4
" set shiftwidth=4
set expandtab
set backspace=2
set textwidth=79
set fileformat=unix

" Display
syntax on
color delek
set number
set ruler
set showmatch
set hlsearch
set title

" Highlight unwanted white spaces
highlight default link UnwantedSpaces ErrorMsg
match UnwantedSpaces / \+\ze\t/
match UnwantedSpaces /\s\+$/

" Highlight characters that exceed column width
match UnwantedSpaces '\%>81v.\+'

" Automatically remove trailing spaces on :w
autocmd BufWritePre * :%s/\s\+$//e

" Remember last cursor position
autocmd BufReadPost * if line("'\"") > 0 && line ("'\"") <= line("$") | exe "normal! g'\"" | endif

" Filetype-specific indentation
filetype plugin indent on
autocmd BufEnter *.c setl noet ts=8 sw=8 cin
autocmd FileType make setl noet ts=8 sw=8 cin
