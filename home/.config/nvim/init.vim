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

"smart case search and replace is done using %S/FooBar/BazBan/g from
"abolish.vim

" see :checkhealth for if this works
" TODO fix this to rtx
let g:python_host_prog='/home/nietaki/.asdf/shims/python2'
let g:python3_host_prog='/home/nietaki/.asdf/shims/python3'

set sessionoptions+=winpos,terminal,folds
set sessionoptions-=tabpages


"""
""" Plugins
"""

lua <<EOF

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
vim.g.mapleader = " "

require("lazy").setup(
{
  {"scrooloose/nerdtree"},
  {"vim-airline/vim-airline"},
  {"vim-airline/vim-airline-themes"},
  {"tpope/vim-fugitive"},
  {"tpope/vim-rhubarb"},
  {"rbong/vim-flog"},
  {"ctrlpvim/ctrlp.vim"},
  {"elixir-lang/vim-elixir"},
  {"junegunn/fzf", build = ":call fzf#install()"},
  {"junegunn/fzf.vim"},
  {"jremmen/vim-ripgrep"},
  {"mhinz/vim-signify"},

  {"sbdchd/neoformat"},
  {"wesQ3/vim-windowswap"},
  {"tpope/vim-commentary"},
--  {"tpope/vim-abolish"},

  {"nvim-lua/plenary.nvim"},
  {"dart-lang/dart-vim-plugin"},
  {"akinsho/flutter-tools.nvim"},

  --{"townk/vim-autoclose"},
  {"terryma/vim-multiple-cursors"},
  {"nelstrom/vim-visual-star-search"},

  {"janko/vim-test"},
  {"tpope/vim-dispatch"},
  {"tpope/vim-eunuch"},
  {"tpope/vim-surround"},

  {"thaerkh/vim-workspace"},

  -- themes
  {"joshdick/onedark.vim"},
  {"tomasr/molokai"},
  {"srcery-colors/srcery-vim", lazy = false},
  {"gcmt/taboo.vim"},

  -- experimental
  {"tpope/vim-rails"},

  {"nvim-treesitter/playground"},

  {"neovim/nvim-lspconfig"},
  {"williamboman/mason.nvim"},
  {"williamboman/mason-lspconfig.nvim"},

  {"hrsh7th/nvim-cmp"},
  {"hrsh7th/cmp-nvim-lsp"},
  {"L3MON4D3/LuaSnip"},
  {"hrsh7th/cmp-path"},
  {"hrsh7th/cmp-buffer"},

  {"VonHeikemen/lsp-zero.nvim", branch = "v2.x"},
  {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  {
    "folke/which-key.nvim",
    config = function()
      --vim.o.timeout = true
      --vim.o.timeoutlen = 300
      require("which-key").setup({
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      })
    end,
  },
  {
  'nvim-telescope/telescope.nvim', tag = '0.1.1',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  {"ahmedkhalf/project.nvim"},
  {'nvim-telescope/telescope-fzf-native.nvim', build = "make" }
})

EOF

nnoremap <Leader>pu :PlugUpdate<CR>
nnoremap <Leader>pc :PlugClean<CR>


:set runtimepath+=~/repos/utils/awesome-flutter-snippets

"""
""" Navigating to standard files, reloading the config
"""

" edit .init.vim
nnoremap <Leader>fed :e ~/.config/nvim/init.vim<CR>
" edit .vimrc
nnoremap <Leader>fev :e ~/.vimrc<CR>

nnoremap <Leader>fep :tabnew ~/repos/puter/README.md<CR>:tcd %:p:h<CR>
nnoremap <Leader>feD :tabnew ~/.homesick/repos/dotfiles/README.md<CR>:tcd %:p:h<CR>

" source .init.vim
nnoremap <Leader>fer :so ~/.config/nvim/init.vim<CR>


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
nnoremap <Leader>wo <C-W><C-O>

" maximize the window
nmap <Leader>wm <C-W>_<C-W>\|
" distribute the windows equally
nnoremap <Leader>w= <C-W>=

" splitting
nnoremap <Leader>w/ :vsp<CR>
nnoremap <Leader>w- :sp <CR>
" TODO maybe :quit would be better if :hidden is set?
nnoremap <Leader>wd :hide<CR>
" save all open buffers
nnoremap <Leader>ps :wa<CR>
nnoremap <Leader>ph :CloseHiddenBuffers<CR>

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
" nmap <C-l> :FZF<CR>
" nnoremap <C-l> <cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files<cr>
nnoremap <C-l> <cmd>lua require("telescope.builtin").find_files({hidden = true})<cr>

" nnoremap <leader>hf <cmd>Telescope find_files<cr>
" nnoremap <leader>hg <cmd>Telescope live_grep<cr>
" nnoremap <leader>hb <cmd>Telescope buffers<cr>
" nnoremap <leader>hh <cmd>Telescope help_tags<cr>

" remember, we can always go to file under cursor with gf
nnoremap <Leader>gf gF
" open file:line under cursor in new window
nnoremap <Leader>wf <C-w>F

" map <Leader>wf :vertical wincmd f<CR>
" ,, is the working directory
set path=.,,apps/chat,apps/auth,apps/shared,/usr/include,

" nnoremap <Leader>bb :CtrlPBuffer<CR>
" nnoremap <Leader>bb :Buffers<CR>
nnoremap <leader>bb <cmd>Telescope buffers<cr>
" recent buffer history
nnoremap <Leader>bh :CtrlPMRUFiles<CR>

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
nmap <Leader>; :AgFuzzy<CR>
" nmap <Leader>s/ :AgFuzzy<CR>
nnoremap <leader>/ <cmd>Telescope grep_string<cr>

" resume last :Ag search
nmap <Leader>sL :Ag<CR><C-p>
nmap <Leader>sl :AgFuzzy<CR><C-p>

nmap <Leader>b/ :BLines<CR>

" count literal searches in this file
nmap <Leader>sc :vimgrep //g%<CR>
nnoremap <leader>sh <cmd>Telescope help_tags<cr>

" REMEMBER for global search and replace
" https://stackoverflow.com/a/38004355/246337
" :grep <search term>
" :cfdo %s/<search term>/<replace term>/gc
" (If you want to save the changes in all files) :cfdo update

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
nmap <Leader>gu :.GBrowse!<CR>
let g:flog_default_opts = { 'max_count': 1000 }
nmap <Leader>gl :Flogsplit<CR>
nmap <Leader>gL :Flog<CR>
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
nnoremap <leader>yd :let @+=expand("%:p:h")<CR>

""insert newline where the cursor is
"nnoremap K i<CR><Esc>l

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
" nnoremap <Leader>cf /.*\[FAILED\]<CR>
" nnoremap <Leader>cO :copen 10<CR>
" nnoremap <Leader>cc :copen<CR>
nnoremap <Leader>cd :cclose<CR>

:command! -nargs=* Makes :Make! <args>
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

"" telescope and workspace
lua <<EOF
require("project_nvim").setup {
    -- Manual mode doesn't automatically change your root directory, so you have
    -- the option to manually do so using `:ProjectRoot` command.
    manual_mode = false,

    -- Methods of detecting the root directory. **"lsp"** uses the native neovim
    -- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
    -- order matters: if one is not detected, the other is used as fallback. You
    -- can also delete or rearangne the detection methods.
    detection_methods = { "lsp", "pattern" },

    -- All the patterns used to detect root dir, when **"pattern"** is in
    -- detection_methods
    patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json" },

    -- Table of lsp clients to ignore by name
    -- eg: { "efm", ... }
    ignore_lsp = {},

    -- Don't calculate root dir on specific directories
    -- Ex: { "~/.cargo/*", ... }
    exclude_dirs = {},

    -- Show hidden files in telescope
    show_hidden = true,

    -- When set to false, you will get a message when project.nvim changes your
    -- directory.
    silent_chdir = false,

    -- What scope to change the directory, valid options are
    -- * global (default)
    -- * tab
    -- * win
    scope_chdir = 'tab',

    -- Path where project.nvim will store the project history for use in
    -- telescope
    datapath = vim.fn.stdpath("data"),
  }

local actions = require "telescope.actions"
require('telescope').setup{
  defaults = {
    -- Default configuration for telescope goes here:
    -- config_key = value,
    file_ignore_patterns = {"node_modules", ".git/", "_build", "deps/"},
    mappings = {
      i = {
      ["<C-j>"] = actions.move_selection_next,
      ["<C-k>"] = actions.move_selection_previous,
        -- map actions.which_key to <C-h> (default: <C-/>)
        -- actions.which_key shows the mappings for your picker,
        -- e.g. git_{create, delete, ...}_branch for the git_branches picker
        --["<C-h>"] = "which_key"
      },
      n = {
      ["<C-j>"] = actions.move_selection_next,
      ["<C-k>"] = actions.move_selection_previous,
      }
    }
  },
  pickers = {
    -- Default configuration for builtin pickers goes here:
    -- picker_name = {
    --   picker_config_key = value,
    --   ...
    -- }
    -- Now the picker_config_key will be applied every time you call this
    -- builtin picker
  },
  extensions = {
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    }
  }
}
require('telescope').load_extension('fzf')
require('telescope').load_extension('projects')

vim.keymap.set('n', '<leader>pp', function() require'telescope'.extensions.projects.projects{} end)
EOF


"" LSP related code
" https://github.com/ThePrimeagen/init.lua/blob/249f3b14cc517202c80c6babd0f9ec548351ec71/after/plugin/lsp.lua
lua <<EOF
local lsp = require('lsp-zero')
lsp.preset({'recommended'})

lsp.ensure_installed({
  'elixirls', 
  'dockerls',
})

local cmp = require('cmp')
local cmp_select = {behavior = cmp.SelectBehavior.Select}
local cmp_mappings = lsp.defaults.cmp_mappings({
  ["<C-Space>"] = cmp.mapping.complete(),
  ['<C-k>'] = cmp.mapping.select_prev_item(cmp_select),
  ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
  ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
  ['<C-j>'] = cmp.mapping.select_next_item(cmp_select),
  ['<C-y>'] = cmp.mapping.confirm({ select = true }),
  ['<C-e>'] = cmp.mapping.abort(),
  ['<C-i>'] = cmp.mapping.abort(),
  ['<CR>'] = cmp.mapping.confirm({ select = true }),
  ['<C-l>'] = cmp.mapping.confirm({ select = true }),
  ['<C-u>'] = cmp.mapping.scroll_docs(-4),
  ['<C-d>'] = cmp.mapping.scroll_docs(4),
})

cmp_mappings['<Tab>'] = nil
cmp_mappings['<S-Tab>'] = nil

local sources = cmp.config.sources({
  { name = 'nvim_lsp' },
  { name = 'luasnip' },
  { name = 'path' },
}, {
  { name = 'buffer' },
  })

lsp.setup_nvim_cmp({
  mapping = cmp_mappings,
  sources = sources
})

lsp.set_preferences({
    suggest_lsp_servers = true,
    sign_icons = {
        error = 'E',
        warn = 'W',
        hint = 'H',
        info = 'I'
    }
})

lsp.on_attach(function(client, bufnr)
  local bufopts = {buffer = bufnr, remap = false}

  vim.keymap.set('n', '<leader>df', vim.diagnostic.open_float, bufopts)
  vim.keymap.set("n", "<leader>dD", function() vim.lsp.buf.declaration() end, bufopts)
  vim.keymap.set("n", "<leader>dd", function() vim.lsp.buf.definition() end, bufopts)
  vim.keymap.set("n", "<leader>di", function() vim.lsp.buf.implementation() end, bufopts)
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, bufopts)
  vim.keymap.set("n", "<C-k>", function() vim.lsp.buf.signature_help() end, bufopts)

  vim.keymap.set('n', '<space>da', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('v', '<space>da', vim.lsp.buf.range_code_action, bufopts)
  vim.keymap.set('n', '<leader>drr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>dR', vim.lsp.buf.rename, bufopts)

  vim.keymap.set('n', '<leader>dwa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>dwr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>dwl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set("n", "<leader>dws", function() vim.lsp.buf.workspace_symbol() end, bufopts)

  vim.keymap.set("n", "<leader>dn", function() vim.diagnostic.goto_next() end, bufopts)
  vim.keymap.set("n", "<leader>dp", function() vim.diagnostic.goto_prev() end, bufopts)

  vim.keymap.set("i", "<C-k>", function() vim.lsp.buf.signature_help() end, bufopts)

  vim.keymap.set('n', '<leader>ff', function() vim.lsp.buf.format { async = true } end, bufopts)
end)

lsp.setup()

vim.diagnostic.config({
    virtual_text = true
})
EOF

nnoremap <Leader>dli :LspInfo<CR>

" " TODO move this to lua config above
" " TODO add LspInfo and LspInstall
" " help
" nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>
" " nnoremap <silent> <C-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
" nnoremap <silent> <Leader>gr <cmd>lua vim.lsp.buf.references()<CR>

" " GOTO something
" nnoremap <silent> <Leader>gD <cmd>lua vim.lsp.buf.declaration()<CR>
" nnoremap <silent> <Leader>gd <cmd>lua vim.lsp.buf.definition()<CR>
" nnoremap <silent> <Leader>gi <cmd>lua vim.lsp.buf.implementation()<CR>
" nnoremap <silent> <Leader>D <cmd>lua vim.lsp.buf.type_definition()<CR>
" " nnoremap <silent> <Leader>so', [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]], opts)

" " diagnostics
" nnoremap <silent> <Leader>ee <cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>
" nnoremap <silent> <Leader>ep <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
" nnoremap <silent> <Leader>en <cmd>lua vim.lsp.diagnostic.goto_next()<CR>
" nnoremap <silent> <Leader>el <cmd>lua vim.lsp.diagnostic.set_loclist()<CR>

" " workspace stuff
" nnoremap <silent> <Leader>pwa <cmd>lua vim.lsp.buf.add_workspace_folder()<CR>
" nnoremap <silent> <Leader>pwr <cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>
" nnoremap <silent> <Leader>pwl <cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>

" " refactor stuff
" nnoremap <Leader>nrr <cmd>lua vim.lsp.buf.rename()<CR>
" nnoremap ,rr <cmd>lua vim.lsp.buf.rename()<CR>
" nnoremap <Leader>na <cmd>lua vim.lsp.buf.code_action()<CR>
" nnoremap ,a <cmd>lua vim.lsp.buf.code_action()<CR>
" vnoremap <Leader>na <cmd>lua vim.lsp.buf.range_code_action()<CR>
" vnoremap ,a <cmd>lua vim.lsp.buf.range_code_action()<CR>
" nnoremap <Leader>fF <cmd>lua vim.lsp.buf.formatting()<CR>
nnoremap <Leader>fF :Neoformat<CR>

" flutter / dart config
"
let g:dart_format_on_save = 0
let g:dart_style_guide = 2

nnoremap <Leader>nfd :FlutterDevices<CR>
nnoremap <Leader>nfs :FlutterRun<CR>
nnoremap <Leader>nfR :FlutterRestart<CR>
nnoremap <Leader>nfr :FlutterReload<CR>
nnoremap <Leader>nfq :FlutterQuit<CR>
nnoremap <Leader>nfo :FlutterOutlineToggle<CR>
nnoremap <Leader>nfpg :FlutterPubGet<CR>
nnoremap <Leader>nfpu :FlutterPubUpgrade<CR>
nnoremap <Leader>nfpc :FlutterCopyProfilerUrl<CR>

"same but , becomes <Leader> n
nnoremap ,fd :FlutterDevices<CR>
nnoremap ,fs :FlutterRun<CR>
nnoremap ,fR :FlutterRestart<CR>
nnoremap ,fr :FlutterReload<CR>
nnoremap ,fq :FlutterQuit<CR>
nnoremap ,fo :FlutterOutlineToggle<CR>
nnoremap ,fpg :FlutterPubGet<CR>
nnoremap ,fpu :FlutterPubUpgrade<CR>
nnoremap ,fpc :FlutterCopyProfilerUrl<CR>
nnoremap ,fc :FlutterCopyProfilerUrl<CR>

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
" autocmd FileType log setlocal includeexpr=substitute(v:fname, ':\\d+$', '', '')
set spelllang=en
"setlocal includeexpr=substitute(v:fname, 'foo', '', '')
" :setlocal includeexpr=substitute(v:fname,'mynamespace/','','')
" :set includeexpr=smagic(v:fname,':[0-9]+$','','g')

" https://github.com/tpope/vim-fugitive/issues/1446
let g:fugitive_pty=0

" dashes shouldn't be a part of the word
:set iskeyword-=-

"" treesitter
lua <<EOF
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the five listed parsers should always be installed)
  ensure_installed = { 
    "c", 
    "lua", 
    "vim", 
    "help", 
    "query", 
    "markdown",
    "markdown_inline",
    "json",
    "bash",
    "cpp",
    "dart",
    "dockerfile",
    "erlang",
    "elixir",
    "gleam",
    "latex",
    "make",
    "zig"
    },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  -- List of parsers to ignore installing (for "all")
  -- ignore_install = { "javascript" },
  ignore_install = {  },

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    enable = true,

    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
    -- the name of the parser)
    -- list of language that will be disabled
    -- disable = { "c", "rust" },
    -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
    disable = function(lang, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
            return true
        end
    end,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },

  indent = {enable = true},
}

local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}

local lspconfig = require "lspconfig"

lspconfig['elixirls'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
    -- prioritize outside umbrella
    root_dir = lspconfig.util.root_pattern(".git") or lspconfig.util.root_pattern("mix.exs") or vim.loop.os_homedir(),
}
EOF

" make sure it's not saved in the workspace
autocmd VimLeave * NERDTreeClose

lua <<EOF
local wk = require("which-key")
wk.register({
  ["*"] = {"workspaces search for word under cursor"},
  ["/"] = {"workspaces search"},
  ["1"] = {"switch to tab 1"},
  ["2"] = {"switch to tab 2"},
  ["3"] = {"switch to tab 3"},
  ["4"] = {"switch to tab 4"},
  ["5"] = {"switch to tab 5"},
  ["6"] = {"switch to tab 6"},
  b = {
    name = "buffers",
    ["/"] = {"fuzzy search in current buffer"},
    h = "MRU buffer history",
    b = "currently open buffers",
    d = "delete current buffer",
    n = "next buffer",
    p = "prev buffer",
    },
  c = {
    name = "quickfix",
    o = "open quickfix window",
    O = "open quickfix window and search for FAILED",
    c = "close quickfix window",
  },
  e = {name = "errors/diagonostics"},
  f = {
    name = "file", 
    f = "format current using NeoFormat",
    r = "check for updates from disk",
    R = "hard reload file",
    h = "switch between header and impl file",
    e = {
      name = "essential-files",
      d = "open init.vim",
      D = "open dotfiles in new tab",
      p = "open puter in new tab",
      v = "open .vimrc",
      r = "source init.vim",
      },
    },
  g = {
    name = "git/goto",
    b = "git blame",
    c = "git commit",
    d = "go to definition",
    f = "go to file under cursor",
    g = "custom git command",
    i = "go to implementation",
    u = "copy github url to current line",
    l = "open git log",
    L = "open git log in new tab",
    p = "git push/shove",
    s = "git status",
    ["/"] = {
      name = "git search",
      c = "search through all commits",
      b = "search commits for the given file",
      }
    },
  m = {name = "make"},
  p = {
    name = "project / plug",
    r = "set project root to current file dir" ,
    R = "print project root" ,
    s = "project save - write all open files" ,
    u = "update Plugs" ,
    w = "which_key_ignore" ,
    },
  q = {name = "quit"},
  s = {
    name = "search",
    f = "fuzzy search, order by file path" ,
    c = "count search hits in current buffer" ,
    ["/"] = "fuzzy search, order by match" ,
    l = "resume last used search (order by match)" ,
    L = "resume last used search (order by file path)" ,
  },
  t = {name = "tabs/toggle"},
  w = {
    name = "windows",
    ["/"] = "split vertically" ,
    ["-"] = "split horizontally" ,
    l = "->" ,
    h = "<-" ,
    k = "up" ,
    j = "down" ,
    m = "maximize" ,
    n = "next window" ,
    o = "make this the Only window" ,
    w = "swap this window with..." ,
    ["="] = "distribute windows equally" ,
    },
  y = {
    name = "copy special",
    f = "relative path (src/foo.txt)" ,
    F = "absolute path (/tmp/src/foo.txt)" ,
    t = "filename (foo.txt)" ,
    d = "directory name (/tmp/src)" ,
    },
  d = {name = "diagnostics - TODO"},
}, {prefix = "<leader>"})
EOF
