vim.cmd 'runtime! vimscript/migration_utils.vim'
-- 1
vim.cmd 'runtime! vimscript/compat.vim'
-- 2
vim.cmd 'runtime! vimscript/pre_plugin_config.vim'

-- 3
require('lazy_setup')

-- 4
vim.cmd 'runtime! vimscript/post_plugin_keymaps.vim'

-- 5
vim.cmd 'runtime! vimscript/search_config.vim'

-- 6
vim.cmd 'runtime! vimscript/git_stuf.vim'

require('workspace_stuff')
require('lsp_setup')

-- 9
vim.cmd 'runtime! vimscript/filetype_specific.vim'

require('treesitter_setup')

-- 11
vim.cmd 'runtime! vimscript/leftovers.vim'

local ok, _ = pcall(require, 'experimental')
if not ok then
  print('Experimental module failed to load')
end



vim.cmd 'runtime! old.init.vim'

