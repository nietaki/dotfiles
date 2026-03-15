
nnoremap <Leader>do :SymbolsOutline<CR>

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
" nnoremap <Leader>ff <cmd>lua vim.lsp.buf.formatting()<CR>
nnoremap <Leader>fF :Neoformat<CR>

" flutter / dart config
"
let g:dart_format_on_save = 0
let g:dart_style_guide = 2

"nnoremap <Leader>nfd :FlutterDevices<CR>
"nnoremap <Leader>nfs :FlutterRun<CR>
"nnoremap <Leader>nfR :FlutterRestart<CR>
"nnoremap <Leader>nfr :FlutterReload<CR>
"nnoremap <Leader>nfq :FlutterQuit<CR>
"nnoremap <Leader>nfo :FlutterOutlineToggle<CR>
"nnoremap <Leader>nfpg :FlutterPubGet<CR>
"nnoremap <Leader>nfpu :FlutterPubUpgrade<CR>
"nnoremap <Leader>nfpc :FlutterCopyProfilerUrl<CR>

""same but , becomes <Leader> n
"nnoremap ,fd :FlutterDevices<CR>
"nnoremap ,fs :FlutterRun<CR>
"nnoremap ,fR :FlutterRestart<CR>
"nnoremap ,fr :FlutterReload<CR>
"nnoremap ,fq :FlutterQuit<CR>
"nnoremap ,fo :FlutterOutlineToggle<CR>
"nnoremap ,fpg :FlutterPubGet<CR>
"nnoremap ,fpu :FlutterPubUpgrade<CR>
"nnoremap ,fpc :FlutterCopyProfilerUrl<CR>
"nnoremap ,fc :FlutterCopyProfilerUrl<CR>


" CIACH

" make sure it's not saved in the workspace
autocmd VimLeave * NERDTreeClose
autocmd VimLeave * SymbolsOutlineClose

"lua <<EOF
"local wk = require("which-key")
"wk.register({
"  ["*"] = {"workspace search for word under cursor"},
"  ["/"] = {"workspace search"},
"  ["1"] = {"switch to tab 1"},
"  ["2"] = {"switch to tab 2"},
"  ["3"] = {"switch to tab 3"},
"  ["4"] = {"switch to tab 4"},
"  ["5"] = {"switch to tab 5"},
"  ["6"] = {"switch to tab 6"},
"  b = {
"    name = "buffers",
"    ["/"] = {"fuzzy search in current buffer"},
"    h = "MRU buffer history",
"    b = "currently open buffers",
"    d = "delete current buffer",
"    n = "next buffer",
"    p = "prev buffer",
"    },
"  c = {
"    name = "quickfix",
"    o = "open quickfix window",
"    O = "open quickfix window and search for FAILED",
"    c = "close quickfix window",
"  },
"  e = {name = "errors/diagonostics"},
"  f = {
"    name = "file", 
"    f = "format current using NeoFormat",
"    r = "check for updates from disk",
"    R = "hard reload file",
"    h = "switch between header and impl file",
"    e = {
"      name = "essential-files",
"      d = "open init.vim",
"      D = "open dotfiles in new tab",
"      p = "open puter in new tab",
"      v = "open .vimrc",
"      r = "source init.vim",
"      },
"    },
"  g = {
"    name = "git/goto",
"    b = "git blame",
"    c = "git commit",
"    d = "go to definition",
"    f = "go to file under cursor",
"    g = "custom git command",
"    i = "go to implementation",
"    u = "copy github url to current line",
"    l = "open git log",
"    L = "open git log in new tab",
"    p = "git push/shove",
"    s = "git status",
"    ["/"] = {
"      name = "git search",
"      c = "search through all commits",
"      b = "search commits for the given file",
"      }
"    },
"  m = {name = "make"},
"  p = {
"    name = "project / plug",
"    p = "telescope show projects",
"    r = "set project root to current file dir" ,
"    R = "print project root" ,
"    s = "project save - write all open files" ,
"    u = "update Plugs" ,
"    w = "which_key_ignore" ,
"    },
"  q = {name = "quit"},
"  s = {
"    name = "search",
"    f = "fuzzy search, order by file path" ,
"    c = "count search hits in current buffer" ,
"    ["/"] = "fuzzy search, order by match" ,
"    l = "resume last used search (order by match)" ,
"    L = "resume last used search (order by file path)" ,
"  },
"  t = {name = "tabs/toggle"},
"  w = {
"    name = "windows",
"    ["/"] = "split vertically" ,
"    ["-"] = "split horizontally" ,
"    l = "->" ,
"    h = "<-" ,
"    k = "up" ,
"    j = "down" ,
"    m = "maximize" ,
"    n = "next window" ,
"    o = "make this the Only window" ,
"    w = "swap this window with..." ,
"    ["="] = "distribute windows equally" ,
"    },
"  y = {
"    name = "copy special",
"    f = "relative path (src/foo.txt)" ,
"    F = "absolute path (/tmp/src/foo.txt)" ,
"    t = "filename (foo.txt)" ,
"    d = "directory name (/tmp/src)" ,
"    },
"  d = {name = "diagnostics - TODO"},
"}, {prefix = "<leader>"})
"EOF
"
 let g:go_def_mapping_enabled = 0

nnoremap <silent> ]l :call search('^'. matchstr(getline('.'), '\(^\s*\)') .'\%>' . line('.') . 'l\S', 'e')<CR>
nnoremap <silent> [l :call search('^'. matchstr(getline('.'), '\(^\s*\)') .'\%<' . line('.') . 'l\S', 'be')<CR>
