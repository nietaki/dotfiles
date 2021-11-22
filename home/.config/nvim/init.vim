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
" set foldmethod=syntax
" set foldlevel=20
set nofoldenable


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
set fileformats=unix

" " TODO fix this
" " Also highlight all tabs and trailing whitespace characters.
" highlight ExtraWhitespace ctermbg=darkgreen guibg=darkgreen
" match ExtraWhitespace /\s\+$\|\t/

set ignorecase          " Make searching case insensitive
set smartcase           " ... unless the query has capital letters.
"set gdefault            " Use 'g' flag by default with :s/foo/bar/.

" see :checkhealth for if this works
let g:python_host_prog='/home/nietaki/.asdf/shims/python2'
let g:python3_host_prog='/home/nietaki/.asdf/shims/python3'

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
Plug 'jremmen/vim-ripgrep'
Plug 'mhinz/vim-signify'

Plug 'sbdchd/neoformat'
Plug 'wesQ3/vim-windowswap'
Plug 'tpope/vim-commentary'
" for the :%S and cr_
Plug 'tpope/vim-abolish'

" highlighting, completion and stuff
Plug 'neovim/nvim-lspconfig'

Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'

Plug 'saadparwaiz1/cmp_luasnip'
Plug 'L3MON4D3/LuaSnip'

Plug 'nvim-lua/plenary.nvim'
Plug 'dart-lang/dart-vim-plugin'
Plug 'akinsho/flutter-tools.nvim'

Plug 'townk/vim-autoclose'

" start: <C-n> start multicursor and add a virtual cursor + selection on the match
"     next: <C-n> add a new virtual cursor + selection on the next match
"     skip: <C-x> skip the next match
"     prev: <C-p> remove current virtual cursor + selection and go back on previous match
" select all: <A-n> start multicursor and directly select all matches
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

" experimental
Plug 'tpope/vim-rails'

call plug#end()

nnoremap <Leader>pu :PlugUpdate<CR>
nnoremap <Leader>pc :PlugClean<CR>

:set runtimepath+=~/repos/utils/awesome-flutter-snippets
lua require("luasnip/loaders/from_vscode").load()

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
cnoreabbrev ct checktime

" close nerdtree when you open a file
let NERDTreeQuitOnOpen = 1
" delete the buffer when you delete a file
let NERDTreeAutoDeleteBuffer = 1
map <C-\> :NERDTreeToggle<CR>
" opens the current file in nerdtree 
" map <C-o> :NERDTreeFind<CR>
" map <C-o> :NERDTreeFind<CR>
map <C-]> :NERDTreeFind<CR>

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

" remember, we can always go to file under cursor with gf
nnoremap <Leader>gf gF
" open file:line under cursor in new window
nnoremap <Leader>wf <C-w>F

" map <Leader>wf :vertical wincmd f<CR>
" ,, is the working directory
set path=.,,apps/chat,apps/auth,apps/shared,/usr/include,

" nnoremap <Leader>bb :CtrlPBuffer<CR>
nnoremap <Leader>bb :Buffers<CR>
" recent buffer history
" nnoremap <Leader>bh :CtrlPMRUFiles<CR>
nnoremap <Leader>bh :Buffers<CR>
" c stands for "current"
nnoremap <Leader>bc :Buffers<CR>

"search just the contents
"  " Default options are --nogroup --column --color
let s:ag_options = ' --nogroup --column --color --hidden --ignore .git/ --ignore deps/ --ignore _build/ -W 300'
" command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, {'options': '--no-sort --delimiter : --nth 4..'}, <bang>0)
command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, s:ag_options, {'options': '--no-sort --delimiter : --nth 4..'}, <bang>0)
" command! -bang -nargs=* AgFuzzy call fzf#vim#ag(<q-args>, {'options': '--delimiter : --nth 4..'}, <bang>0)
command! -bang -nargs=* AgFuzzy call fzf#vim#ag(<q-args>, s:ag_options, {'options': '--delimiter : --nth 4..'}, <bang>0)

nnoremap <Leader>* :Ag <C-R><C-W><CR>

" TODO and set this to <Leader>*
"fu! FzfAgCurrWord()
  "call fzf#vim#ag(expand('<cword>'))
"endfu

nmap <Leader>sf :Ag<CR>
" intentional space
"nmap <Leader>/ :Ag
nmap <Leader>/ :AgFuzzy<CR>
" resume last :Ag search
nmap <Leader>sl :AgFuzzy<CR><C-p>
nmap <Leader>sL :Ag<CR><C-p>
nmap <Leader>b/ :BLines<CR>

" count literal searches in this file
nmap <Leader>sc :vimgrep //g%

" example:
" :vimgrep /dostuff()/j ../**/*.c
" afterwards you can move between them using :cnext and :cprev
nnoremap ]e :cnext<CR>
nnoremap [e :cprevious<CR>
nnoremap <Leader>cn :cnext<CR>
nnoremap <Leader>cp :cprevious<CR>
nnoremap <Leader>cN :cprevious<CR>
" :grep '^\s*Application.ensure_all'
" https://gist.github.com/romainl/56f0c28ef953ffc157f36cc495947ab3
" set grepprg=ag\ --vimgrep\ --all-text

if executable("rg")
    set grepprg=rg\ --vimgrep\ --no-heading
    set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

" :Rg Application
" :cfdo %s/old/new/g

"""
""" Git stuff
"""

" navigating between git changes
nmap <C-j> <plug>(signify-next-hunk)
nmap <C-k> <plug>(signify-prev-hunk)
"nmap <leader>gJ 9999<leader>gj
"nmap <leader>gK 9999<leader>gk


nmap <Leader>gs :Git<CR>
nmap <Leader>gc :Git commit<CR>
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

" yank
" relative path (src/foo.txt)
nnoremap <leader>yf :let @+=expand("%")<CR><C-g>

" absolute path (/something/src/foo.txt)
nnoremap <leader>yF :let @+=expand("%:p")<CR>

" filename (foo.txt)
nnoremap <leader>yt :let @+=expand("%:t")<CR>

" directory name (/something/src)
nnoremap <leader>yh :let @+=expand("%:p:h")<CR>

"insert newline where the cursor is
nnoremap K i<CR><Esc>l

"""
""" Terminal
"""

" just use :te
" nmap <Leader>tt :terminal<CR>
" easy exiting terminal mode
tnoremap <C-w> <C-\><C-n>
tnoremap <C-s> <C-\><C-n>

" tnoremap <Esc><Esc> <C-\><C-n>
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

set hidden
set nobackup
set nowritebackup

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

" nnoremap <Leader>co :copen 30<CR>
let g:dispatch_quickfix_height=30
nnoremap <Leader>co :Copen<CR>
nnoremap <Leader>cO :Copen<CR>/.*\[FAILED\]<CR>
nnoremap <Leader>cf /.*\[FAILED\]<CR>
" nnoremap <Leader>cO :copen 10<CR>
" nnoremap <Leader>cc :copen<CR>
nnoremap <Leader>cd :cclose<CR>

nnoremap <Leader>m<Leader> :Make 
nnoremap <Leader>mtc :Make! compile<CR>
nnoremap <Leader>mtt :Make! test<CR>
nnoremap <Leader>mtn :Make! test_native<CR>
nnoremap <Leader>mte :Make! test_embedded<CR>
nnoremap <Leader>mtf :Make! test_filesystem<CR>
nnoremap <Leader>mm :Make!<CR>
nnoremap <Leader>mk :AbortDispatch<CR>

" it's this time again
nmap ,cl :silent !pdflatex %<CR>

" vim workspace

" let g:workspace_session_directory = $HOME . '/.vim/sessions/'
let g:workspace_session_disable_on_args = 1
let g:workspace_autosave = 0
let g:workspace_autosave_untrailspaces = 0

" mostly copied from https://github.com/neovim/nvim-lspconfig/wiki/Autocompletion
lua <<EOF
-- Add additional capabilities supported by nvim-cmp
local nvim_lsp = require 'lspconfig'

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

-- Enable some language servers with the additional completion capabilities offered by nvim-cmp
local servers = { 'rust_analyzer', 'bashls' }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    -- on_attach = my_custom_on_attach,
    capabilities = capabilities,
  }
end

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  completion = {
      -- only autocomplete with C-Space
      autocomplete = false
    },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    -- this is to close the autocompletion
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end,
    ['<S-Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end,
  },
  sources = {
    { name = 'luasnip' },
    { name = 'nvim_lsp' },
    { name = 'buffer' },
  },
}

require("flutter-tools").setup{} -- use defaults
EOF

" help
nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> <C-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> <Leader>gr <cmd>lua vim.lsp.buf.references()<CR>

" GOTO something
nnoremap <silent> <Leader>gd <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> <Leader>gD <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> <Leader>gi <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <Leader>D <cmd>lua vim.lsp.buf.type_definition()<CR>
" nnoremap <silent> <Leader>so', [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]], opts)

" diagnostics
nnoremap <silent> <Leader>el <cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>
nnoremap <silent> <Leader>ep <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <silent> <Leader>en <cmd>lua vim.lsp.diagnostic.goto_next()<CR>
nnoremap <silent> <Leader>ee <cmd>lua vim.lsp.diagnostic.set_loclist()<CR>

" workspace stuff
nnoremap <silent> <Leader>pwa <cmd>lua vim.lsp.buf.add_workspace_folder()<CR>
nnoremap <silent> <Leader>pwr <cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>
nnoremap <silent> <Leader>wfp <cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>

" refactor stuff
nnoremap <Leader>cr <cmd>lua vim.lsp.buf.rename()<CR>
nnoremap <silent> <Leader>ca <cmd>lua vim.lsp.buf.code_action()<CR>
nnoremap <silent> <Leader>cA <cmd>lua vim.lsp.buf.range_code_action()<CR>
nnoremap <Leader>ff <cmd>lua vim.lsp.buf.formatting()<CR>

" vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
" vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
"

imap <silent><expr> <Tab> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<Tab>' 
inoremap <silent> <S-Tab> <cmd>lua require'luasnip'.jump(-1)<Cr>

snoremap <silent> <Tab> <cmd>lua require('luasnip').jump(1)<Cr>
snoremap <silent> <S-Tab> <cmd>lua require('luasnip').jump(-1)<Cr>

imap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
smap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'

" https://vi.stackexchange.com/a/456/23407
fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun

autocmd BufWritePre *.ex,*.exs,*.rb,*.cpp,*.h,*.hpp :call TrimWhitespace()
autocmd BufWritePre *.dart lua vim.lsp.buf.formatting_sync(nil, 100)

" jumps between c++ header and definition files
" thank you internet https://vim.fandom.com/wiki/Easily_switch_between_source_and_header_file
map <Leader>fh :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>

" https://vim.fandom.com/wiki/Replace_a_word_with_yanked_text
nnoremap S "_diwP

"" SPELL CHECKING 

" turn comment/text spellcheck on
" set spell
set nospell
autocmd FileType tex setlocal spell
autocmd FileType markdown setlocal spell
" autocmd FileType text setlocal spell
set spelllang=en

" https://github.com/tpope/vim-fugitive/issues/1446
let g:fugitive_pty=0
