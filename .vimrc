" Formatting
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set backspace=2

" Display
color delek
set number
set ruler
syntax on

" Automatically remove trailing spaces on :w
autocmd BufWritePre * :%s/\s\+$//e
" Remember last cursor position
autocmd BufReadPost * if line("'\"") > 0 && line ("'\"") <= line("$") | exe "normal! g'\"" | endif
