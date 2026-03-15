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
let s:ag_options = ' --nogroup --column --color --hidden --ignore .git/ --ignore deps/ --ignore _build/ --ignore erl_crash.dump -W 300'
" command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, {'options': '--no-sort --delimiter : --nth 4..'}, <bang>0)
command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, s:ag_options, {'options': '--no-sort --delimiter : --nth 4..'}, <bang>0)
" command! -bang -nargs=* AgFuzzy call fzf#vim#ag(<q-args>, {'options': '--delimiter : --nth 4..'}, <bang>0)
command! -bang -nargs=* AgFuzzy call fzf#vim#ag(<q-args>, s:ag_options, {'options': '--delimiter : --nth 4..'}, <bang>0)

" nnoremap <Leader>* :Ag <C-R><C-W><CR>
nnoremap <leader>* <cmd>Telescope grep_string<cr>

" TODO and set this to <Leader>*
"fu! FzfAgCurrWord()
  "call fzf#vim#ag(expand('<cword>'))
"endfu

nmap <Leader>sf :Ag<CR>
" intentional space
nmap <Leader>; :AgFuzzy<CR>
" nmap <Leader>s/ :AgFuzzy<CR>
nmap <Leader>/ :AgFuzzy<CR>
" nnoremap <leader>/ <cmd>Telescope grep_string search=<cr>

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
