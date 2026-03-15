" Map the leader key to SPACE
let mapleader="\<SPACE>"
let g:maplocalleader="\<SPACE>"


" make the leader key timeout a bit longer
set timeoutlen=1000

" set foldmethod=manual
"set foldmethod=indent
" set foldmethod=syntax
" set foldlevel=20
set nofoldenable

" cpp syntax highlighting config
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_posix_standard = 1
let g:cpp_experimental_template_highlight = 1

" disable continuing of the comments
" autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
autocmd FileType * setlocal formatoptions-=r formatoptions-=o

autocmd FileType go setlocal shiftwidth=2 softtabstop=2 expandtab!
autocmd FileType html setlocal shiftwidth=2 softtabstop=2 expandtab!

set showmatch           " Show matching brackets.
set number              " Show the line numbers on the left side.
set formatoptions+=o    " Continue comment marker in new lines.
set expandtab           " Insert spaces when TAB is pressed.
set tabstop=2           " Render TABs using this many spaces.
set shiftwidth=2        " Indentation amount for < and > commands.

set nojoinspaces        " Prevents inserting two spaces after punctuation on a join (J)

" More natural splits
set splitbelow          " Horizontal split below current.
set splitright          " Vertical split to right of current.

if !&scrolloff
    set scrolloff=3       " Show next 3 lines while scrolling.
endif
if !&sidescrolloff
    set sidescrolloff=5   " Show next 5 columns while side-scrolling.
endif
set nostartofline       " Do not jump to first character with page commands.


" Tell Vim which characters to show for expanded TABs,
" trailing whitespace, and end-of-lines. VERY useful!
" if &listchars ==# 'eol:$'
set listchars=tab:·\ ,trail:-,extends:>,precedes:<,nbsp:+
" endif
set list                " Show problematic characters.
set fileformats=unix

" " TODO fix this
" " Also highlight all tabs and trailing whitespace characters.
" highlight ExtraWhitespace ctermbg=darkgreen guibg=darkgreen
" match ExtraWhitespace /\s\+$\|\t/

set ignorecase          " Make searching case insensitive
set smartcase           " ... unless the query has capital letters.
"set gdefault            " Use 'g' flag by default with :s/foo/bar/.

"smart case search and replace is done using %S/FooBar/BazBan/g from
"abolish.vim

" see :checkhealth for if this works
" TODO fix this to rtx
let g:python_host_prog='/home/nietaki/.asdf/shims/python2'
let g:python3_host_prog='/home/nietaki/.asdf/shims/python3'

set sessionoptions+=winpos,terminal,folds
set sessionoptions-=tabpages
