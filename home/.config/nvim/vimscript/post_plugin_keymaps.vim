nnoremap <Leader>pu :PlugUpdate<CR>
nnoremap <Leader>pc :PlugClean<CR>


" :set runtimepath+=~/repos/utils/awesome-flutter-snippets

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

let g:windowswap_map_keys = 0 "prevent default bindings
nnoremap <silent> <leader>ws :call WindowSwap#EasyWindowSwap()<CR>

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

" last-used window
nnoremap <Leader>ww <C-W><C-P>
nnoremap <Leader>wp <C-W><C-P>
" bottom-right window
nnoremap <Leader>wL <C-W><C-B>
" top-left window
nnoremap <Leader>wH <C-W><C-T>

" maximize the window
nmap <Leader>wm <C-W>_<C-W>\|
" distribute the windows equally
nnoremap <Leader>w= <C-W>=
nnoremap <Leader>w< :vertical resize -10<CR>
nnoremap <Leader>w> :vertical resize +10<CR>

" splitting
nnoremap <Leader>w/ :vsp<CR>
nnoremap <Leader>w- :sp <CR>
" split window and open alternate file in the split
nmap <Leader>w6 <C-W><C-^>
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
nnoremap <Leader>t1 :1tabnext<CR>
nnoremap <Leader>t2 :2tabnext<CR>
nnoremap <Leader>t3 :3tabnext<CR>
nnoremap <Leader>t4 :4tabnext<CR>
nnoremap <Leader>t5 :5tabnext<CR>
nnoremap <Leader>t6 :6tabnext<CR>

"TODO setting root dir for tabs

" close currently open buffer
nnoremap <Leader>bd :bp\|bd #<CR>

" quit
nnoremap <Leader>qq :qa<CR>
