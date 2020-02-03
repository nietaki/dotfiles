"""
""" Vim defaults integration
"""
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

source ~/.vimrc

"""
""" Fixing colours (makes the theme work)
"""

"Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
"If you're using tmux version 2.2 or later, you can remove the outermost $TMUX check and use tmux's 24-bit color support
"(see < http://sunaku.github.io/tmux-24bit-color.html#usage > for more information.)
if (empty($TMUX))
  if (has("nvim"))
    "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
  "For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
  "Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
  " < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
  if (has("termguicolors"))
    set termguicolors
  endif
endif

if (has("termguicolors"))
  set termguicolors
endif

" Nuclear option
"set termguicolors


" TODO group these (search, git, navigation, files, editor config)
" TODO clean up unused stuff

"""
""" General settings
"""

" Map the leader key to SPACE
let mapleader="\<SPACE>"

" make the leader key timeout a bit longer
set timeoutlen=4000

" set foldmethod=manual
"set foldmethod=indent
set foldmethod=syntax
set foldlevel=20

" turn comment/text spellcheck on
" set spell
autocmd FileType tex setlocal spell
autocmd FileType markdown setlocal spell
autocmd FileType text setlocal spell
set spelllang=en

" disable continuing of the comments
" autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
autocmd FileType * setlocal formatoptions-=r formatoptions-=o

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
if &listchars ==# 'eol:$'
  set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
endif
set list                " Show problematic characters.

" TODO fix this
" Also highlight all tabs and trailing whitespace characters.
highlight ExtraWhitespace ctermbg=darkgreen guibg=darkgreen
match ExtraWhitespace /\s\+$\|\t/

set ignorecase          " Make searching case insensitive
set smartcase           " ... unless the query has capital letters.
"set gdefault            " Use 'g' flag by default with :s/foo/bar/.

" see :checkhealth for if this works
let g:python_host_prog='$HOME/.asdf/shims/python2'
let g:python3_host_prog='$HOME/.asdf/shims/python3'

"""
""" Plugins
"""

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')
" plugs go here
Plug 'scrooloose/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'rbong/vim-flog'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'elixir-lang/vim-elixir'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'mhinz/vim-signify'

Plug 'sbdchd/neoformat'
Plug 'wesQ3/vim-windowswap'
Plug 'tpope/vim-commentary'

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'terryma/vim-multiple-cursors'
Plug 'nelstrom/vim-visual-star-search'
Plug 'vale1410/vim-minizinc'
Plug 'sudar/vim-arduino-syntax'

Plug 'janko/vim-test'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-eunuch'

Plug 'thaerkh/vim-workspace'

" themes
Plug 'joshdick/onedark.vim'
Plug 'tomasr/molokai'
Plug 'srcery-colors/srcery-vim'
Plug 'gcmt/taboo.vim'

call plug#end()

nnoremap <Leader>pu :PlugUpdate<CR>
nnoremap <Leader>pc :PlugClean<CR>

"""
""" Navigating to standard files, reloading the config
"""

" edit .init.vim
nnoremap <Leader>fed :e ~/.config/nvim/init.vim<CR>
" edit .vimrc
nnoremap <Leader>fev :e ~/.vimrc<CR>

" source .init.vim
nnoremap <Leader>fer :so ~/.config/nvim/init.vim<CR>
nnoremap <Leader>feR :so ~/.config/nvim/init.vim<CR>

nnoremap <Leader>ff :e ~/

"""
""" Managing windows and buffers
"""

" switching between the last two buffers in the window
nnoremap <Leader><tab> :b#<CR>
nnoremap <Leader>bp :bp<CR>
nnoremap <Leader>bn :bn<CR>

" moving around windows
nnoremap <Leader>wl <C-W><C-L>
nnoremap <Leader>wj <C-W><C-J>
nnoremap <Leader>wk <C-W><C-K>
nnoremap <Leader>wh <C-W><C-H>
nnoremap <Leader>wn <C-W><C-W>
" open file:line under cursor in new window
nnoremap <Leader>wf <C-W>F

" maximize the window
nmap <Leader>wm <C-W>_ <C-W>\|
" distribute the windows equally
nnoremap <Leader>w= <C-W>=

" splitting
nnoremap <Leader>w/ :vsp<CR>
nnoremap <Leader>w- :sp <CR>
" TODO maybe :quit would be better if :hidden is set?
nnoremap <Leader>wd :hide<CR>
" save all open buffers
nnoremap <Leader>ps :wa<CR>

nnoremap <Leader>tw :ToggleWorkspace<CR>

" set Project Root to directory containing current file
nnoremap <Leader>pr :tcd %:p:h<CR>
nnoremap <Leader>pR :pwd<CR>
" refresh the currently edited file from disk
nnoremap <Leader>fR :e!<CR>

" https://vi.stackexchange.com/questions/458/how-can-i-reload-all-buffers-at-once
nnoremap <Leader>fr :checktime<CR>

" close nerdtree when you open a file
let NERDTreeQuitOnOpen = 1
" delete the buffer when you delete a file
let NERDTreeAutoDeleteBuffer = 1
map <C-\> :NERDTreeToggle<CR>
" opens the current file in nerdtree 
map <C-o> :NERDTreeFind<CR>

" tabs

nnoremap <Leader>tt :tabnew<CR>
nnoremap <Leader>te :tabedit 
nnoremap <Leader>tl :tabnext<CR>
nnoremap <Leader>th :tabprevious<CR>
nnoremap <Leader>tp :tabprevious<CR>
nnoremap <Leader>tN :tabprevious<CR>
nnoremap <Leader>tn :tabnext<CR>
nnoremap <Leader>td :tabclose<CR>
nnoremap <Leader>tc :tabclose<CR>
nnoremap <Leader>1 :1tabnext<CR>
nnoremap <Leader>2 :2tabnext<CR>
nnoremap <Leader>3 :3tabnext<CR>
nnoremap <Leader>4 :4tabnext<CR>
nnoremap <Leader>5 :5tabnext<CR>
nnoremap <Leader>6 :6tabnext<CR>

"TODO setting root dir for tabs

" close currently open buffer
nnoremap <Leader>bd :bp\|bd #<CR>

" quit
nnoremap <Leader>qq :qa<CR>

"""
""" Searching and stuff
"""

" Search and Replace
"nmap <Leader>ss :%s//g<Left><Left>

" --hidden makes ag not skip the hidden files when searching
let $FZF_DEFAULT_COMMAND = 'ag --ignore-dir .git --hidden -g ""'

" ctrl-p and ctrl-n for previous fzf searches
let g:fzf_history_dir = '~/.fzf-history'

" go to file in project
nmap <C-l> :FZF<CR>

" remember, we can always go to file with gf
nnoremap <Leader>gf gF
nnoremap <Leader>wf <C-w>F
" map <Leader>wf :vertical wincmd f<CR>
" ,, is the working directory
set path=.,,apps/chat,apps/auth,apps/shared,/usr/include,

nnoremap <Leader>bb :CtrlPBuffer<CR>
" recent buffer history
nnoremap <Leader>bh :CtrlPMRUFiles<CR>
" c stands for "current"
nnoremap <Leader>bc :Buffers<CR>

"search just the contents
"  " Default options are --nogroup --column --color
let s:ag_options = ' --nogroup --column --color --hidden --ignore .git/ --ignore deps/ --ignore _build/ -W 300'
" command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, {'options': '--no-sort --delimiter : --nth 4..'}, <bang>0)
command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, s:ag_options, {'options': '--no-sort --delimiter : --nth 4..'}, <bang>0)
" command! -bang -nargs=* AgFuzzy call fzf#vim#ag(<q-args>, {'options': '--delimiter : --nth 4..'}, <bang>0)
command! -bang -nargs=* AgFuzzy call fzf#vim#ag(<q-args>, s:ag_options, {'options': '--delimiter : --nth 4..'}, <bang>0)

" TODO and set this to <Leader>*
"fu! FzfAgCurrWord()
  "call fzf#vim#ag(expand('<cword>'))
"endfu

nmap <Leader>sf :Ag<CR>
" intentional space
"nmap <Leader>/ :Ag
nmap <Leader>/ :AgFuzzy<CR>
" resume last :Ag search
nmap <Leader>sl :Ag<CR><C-p>
nmap <Leader>b/ :BLines<CR>

" count literal searches in this file
nmap <Leader>sc :vimgrep //g%
" afterwards you can move between them using :cnext and :cprev

"""
""" Git stuff
"""

" navigating between git changes
nmap <C-j> <plug>(signify-next-hunk)
nmap <C-k> <plug>(signify-prev-hunk)
"nmap <leader>gJ 9999<leader>gj
"nmap <leader>gK 9999<leader>gk


nmap <Leader>gs :Gstatus<CR>
nmap <Leader>gc :Gcommit<CR>
nmap <Leader>gp :Git shove<CR>
nmap <Leader>gb :Gblame<CR>
nmap <Leader>gll :.Gbrowse!<CR>
let g:flog_default_arguments = { 'max_count': 1000 }
nmap <Leader>gl :Flog<CR>
nmap <Leader>gL :Flogsplit<CR>
" the trailing space is here for a reason!
nmap <Leader>gg :Git 
" search through commits
nmap <Leader>g/c :Commits<CR>
" search through commits for the current file
nmap <Leader>g/b :BCommits<CR>

"""
""" Editing
"""

nmap <C-_> gcc
vmap <C-_> gc

set clipboard=unnamedplus

" relative path (src/foo.txt)
nnoremap <leader>cf :let @+=expand("%")<CR>

" absolute path (/something/src/foo.txt)
nnoremap <leader>cF :let @+=expand("%:p")<CR>

" filename (foo.txt)
nnoremap <leader>ct :let @+=expand("%:t")<CR>

" directory name (/something/src)
nnoremap <leader>ch :let @+=expand("%:p:h")<CR>

"insert newline where the cursor is
nnoremap K i<CR><Esc>l

"""
""" Terminal
"""

" just use :te
" nmap <Leader>tt :terminal<CR>
" easy exiting terminal mode
tnoremap <C-w> <C-\><C-n>
" openint terminal in Terminal-mode (ready to go)
autocmd TermOpen * startinsert

"""
""" Look & feel
"""

"colorscheme onedark
"colorscheme molokai
"colorscheme default
colorscheme srcery

" this disables the branch name in the config
let g:airline_section_b = airline#section#create(['hunks'])
" this disables the utf-8[unix] part
let g:airline_section_y = airline#section#create([])

"""
""" IDE stuff / completion / CoC nvim
"""

""" Copied from CoC nvim README

set hidden
set nobackup
set nowritebackup

" uske tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"<Paste>

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"


" Remap keys for gotos
nmap <silent> ,gd <Plug>(coc-definition)
nmap <silent> ,gg <Plug>(coc-definition)
nmap <silent> ,gy <Plug>(coc-type-definition)
nmap <silent> ,gi <Plug>(coc-implementation)
nmap <silent> ,gr <Plug>(coc-references)
" nmap <silent> ,gr :<C-u>call CocActionAsync('jumpReferences')<CR>

" THIS IS BEAUTIFUL
" show documentation in preview window
"nnoremap <silent> K :call <SID>show_documentation()<CR>
nmap <silent> ,hh :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" TODO fix this, it doesn't work
" Highlight symbol under cursor on CursorHold
" autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <silent> ,er <Plug>(coc-rename)

" Remap for do codeAction of current line
nmap <silent> ,al  <Plug>(coc-codeaction)

" nmap <silent> ,ff :Format<CR>
" TODO configure this to run mix from a subdirectory (to inherit same .tool_versions)
" but not compile the whole project
nmap <silent> ,ff :Neoformat<CR>
"command! -nargs=0 FormatBuffer :call CocAction('format')

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

"xmap <leader>f  <Plug>(coc-format-selected)
"nmap <leader>f  <Plug>(coc-format-selected)

" Show commands
nnoremap <silent> ,cc  :<C-u>CocList commands<cr>

" show completion server logs
nmap <silent> ,ll :CocCommand workspace.showOutput<CR>
nmap <silent> ,lc :CocOpenLog<CR>
" nmap <silent> ,cl :CocCommand workspace.showOutput<CR>
nmap ,cr :<C-u>CocRestart<CR>

" Warnings List
nnoremap <silent> ,wl  :<C-u>CocList diagnostics<cr>
" Use `[c` and `]c` to navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ,wN <Plug>(coc-diagnostic-prev)
nmap <silent> ,wp <Plug>(coc-diagnostic-prev)
nmap <silent> ,wk <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)
nmap <silent> ,wn <Plug>(coc-diagnostic-next)
nmap <silent> ,wj <Plug>(coc-diagnostic-next)
nmap <silent> ,wf  <Plug>(coc-fix-current)

nmap <silent> ,ws <Plug>(coc-diagnostic-info)
nmap <silent> ,ww <Plug>(coc-diagnostic-info)

" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Find symbol of current document
nnoremap <silent> ,o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> ,s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> ,n  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> ,N  :<C-u>CocPrev<CR>
nnoremap <silent> ,p  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> ,sl  :<C-u>CocListResume<CR>

" Testing using vim test
" let test#strategy = "neovim"
let test#strategy = "dispatch"
" let test#strategy = "dispatch_background"
nnoremap ,tt :TestNearest<CR>
nnoremap ,tl :TestLast<CR>
nnoremap ,tf :TestFile<CR>
nnoremap ,ts :TestSuite<CR>
nnoremap ,ta :TestSuite<CR>

" test results can be open in the quickfix window
" nnoremap <Leader>co :copen<CR>
nnoremap <Leader>co :copen 30<CR>
nnoremap <Leader>cO :copen 10<CR>
nnoremap <Leader>cc :cclose<CR>
nnoremap <Leader>cd :cclose<CR>

" it's this time again
nmap ,cl :silent !pdflatex %<CR>

" vim workspace

" let g:workspace_session_directory = $HOME . '/.vim/sessions/'
let g:workspace_session_disable_on_args = 1
let g:workspace_autosave = 0
let g:workspace_autosave_untrailspaces = 0

" https://vi.stackexchange.com/a/456/23407
fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun

autocmd BufWritePre *.ex,*.exs :call TrimWhitespace()
