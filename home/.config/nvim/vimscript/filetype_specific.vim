
" https://vi.stackexchange.com/a/456/23407
fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun

autocmd BufWritePre *.ex,*.exs,*.rb,*.cpp,*.h,*.hpp,*.lua :call TrimWhitespace()
" autocmd BufWritePre *.dart lua vim.lsp.buf.formatting_sync(nil, 100)

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

autocmd BufNewFile,BufRead,BufReadPost *.livemd set filetype=markdown
autocmd BufNewFile,BufRead,BufReadPost *.md set filetype=markdown syntax=markdown
autocmd BufNewFile,BufRead,BufReadPost *.ino set filetype=cpp syntax=cpp

" https://github.com/tpope/vim-fugitive/issues/1446
let g:fugitive_pty=0

" dashes shouldn't be a part of the word
:set iskeyword-=-
