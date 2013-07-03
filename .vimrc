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

" Automatically remove trailing spaces on :w
autocmd BufWritePre * :%s/\s\+$//e
" Remember last cursor position
autocmd BufReadPost * if line("'\"") > 0 && line ("'\"") <= line("$") | exe "normal! g'\"" | endif
