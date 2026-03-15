
" navigating between git changes
nmap <C-j> <plug>(signify-next-hunk)
nmap <C-k> <plug>(signify-prev-hunk)
"nmap <leader>gJ 9999<leader>gj
"nmap <leader>gK 9999<leader>gk


nmap <Leader>gs :Git<CR>
nmap <Leader>gc :Git commit<CR>
nmap <Leader>gp :Git shove<CR>
nmap <Leader>gb :Git blame<CR>
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

nmap <C-/> gcc
nmap <C-_> gcc
vmap <C-_> gc
vmap <C-/> gc

set clipboard=unnamedplus

" yank
" relative path (src/foo.txt)
nnoremap <leader>yf :let @+=expand("%")<CR><C-g>

" relative path and line no (src/foo.txt:42)
nnoremap <leader>yl :let @+=(expand("%") . ":" . line("."))<CR><C-g>

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
tnoremap <C-h> <C-\><C-n>

" tnoremap <Esc><Esc> <C-\><C-n>
" openint terminal in Terminal-mode (ready to go)
autocmd TermOpen * startinsert
autocmd FileType glsl setlocal commentstring=//\ %s
autocmd FileType glsl setlocal tabstop=4
autocmd FileType glsl setlocal shiftwidth=4
autocmd FileType terraform setlocal commentstring=//\ %s

autocmd FileType c setlocal tabstop=2
autocmd FileType c setlocal shiftwidth=2

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

nnoremap ,cs :Copilot status<CR>
nnoremap ,ce :Copilot enable<CR>
nnoremap ,cd :Copilot disable<CR>
nnoremap ,co :Copilot panel<CR>

imap <C-j> <Plug>(copilot-next)
imap <C-l> <Plug>(copilot-accept-word)
imap <C-h> <Plug>(copilot-dismiss)
imap <C-;> <Plug>(copilot-suggest)

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
nnoremap <Leader>mf :Dispatch! mix format<CR>
nnoremap <Leader>mtc :Make! compile<CR>
nnoremap <Leader>mtt :Make! test<CR>
nnoremap <Leader>mtn :Make! test_native<CR>
nnoremap <Leader>mte :Make! test_embedded<CR>
nnoremap <Leader>mtf :Make! test_filesystem<CR>
nnoremap <Leader>mm :Make!<CR>
nnoremap <Leader>mk :AbortDispatch<CR>

" it's this time again
nmap ,cl :silent !pdflatex %<CR>

let g:markdown_recommended_style = 0
nmap <Leader>mll :Dispatch! pkill -9 -f livebook; livebook server -p 9876 %:p<CR>
nmap <Leader>mlk :Dispatch! pkill -9 -f livebook<CR>

" this doesn't work for whatever reason?
"map <silent> <C-i> i_<Esc>r
