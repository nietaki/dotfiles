set nocompatible

set showmatch
set autoindent
set smartindent

set hlsearch
:set ts=2
:set softtabstop=2
:set shiftwidth=2
:set laststatus=2

:filetype plugin indent on

"set ofu=syntaxcomplete#Complete
":set completeopt=longest,menuone
  
" " zamienianie tabow na spacje
:set expandtab
:set langmenu=en_US.UTF-8

map <Down> g<Down>
map <Up> g<Up>
nmap j gj
nmap k gk
vmap j gj
vmap k gk

nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" dashes are parts of words
set iskeyword+=-

":map <C-p> :set  paste<CR>
":set pastetoggle=<C-p>

syntax on
" https://vim.fandom.com/wiki/Fix_syntax_highlighting
syntax sync minlines=2000

" highlight the line the cursor is in
set cursorline
set autoread
