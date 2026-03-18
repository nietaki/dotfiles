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
nnoremap <Leader>t1 :1tabnext<CR>
nnoremap <Leader>t2 :2tabnext<CR>
nnoremap <Leader>t3 :3tabnext<CR>
nnoremap <Leader>t4 :4tabnext<CR>
nnoremap <Leader>t5 :5tabnext<CR>
nnoremap <Leader>t6 :6tabnext<CR>
