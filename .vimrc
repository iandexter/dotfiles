" Key bindings
set term=builtin_ansi
set timeout
set timeoutlen=100
set ttimeoutlen=100

" Formatting
" set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set backspace=2
set textwidth=80

" Display
color delek
set number
set ruler
syntax on
set showmatch
set hlsearch

" Highlight characters that exceed column width
match ErrorMsg '\%>80v.\+'
" Automatically remove trailing spaces on :w
autocmd BufWritePre * :%s/\s\+$//e
" Remember last cursor position
autocmd BufReadPost * if line("'\"") > 0 && line ("'\"") <= line("$") | exe "normal! g'\"" | endif
