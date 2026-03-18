

" " workspace stuff
" nnoremap <silent> <Leader>pwa <cmd>lua vim.lsp.buf.add_workspace_folder()<CR>
" nnoremap <silent> <Leader>pwr <cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>
" nnoremap <silent> <Leader>pwl <cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>

autocmd VimLeave * NERDTreeClose
autocmd VimLeave * SymbolsOutlineClose

" TODO port those to mini.clue

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
