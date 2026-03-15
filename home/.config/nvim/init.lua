vim.cmd 'runtime! vimscript/migration_utils.vim'
vim.cmd 'runtime! vimscript/compat.vim'
vim.cmd 'runtime! vimscript/pre_plugin_config.vim'

require('lazy_setup')

vim.cmd 'runtime! vimscript/post_plugin_keymaps.vim'

vim.cmd 'runtime! vimscript/search_config.vim'

vim.cmd 'runtime! vimscript/git_stuff.vim'

require('workspace_stuff')
require('lsp_setup')

vim.cmd 'runtime! vimscript/filetype_specific.vim'

require('treesitter_setup')

vim.cmd 'runtime! vimscript/leftovers.vim'

local ok, _ = pcall(require, 'experimental')
if not ok then
  print('Experimental module failed to load')
end
-- # backup plan :D
-- vim.cmd 'runtime! old.init.vim'


--[[

## Gameplan:

- [x] break down the old config into pieces
- [ ] go through the files and purge all the old keymaps and plugins - it's safe if we have a nice git history and the old config as reference
- [ ] set up barebones nvim-cmp
- [ ] plug in one lsp server into nvim-cmp


## long tail
- choose a vim fragment
- translate to lua
- ???
- PROFIT

## wishlist

- [ ] break down the plugins config into files (there's a way that I don't understand yet)
- [ ] fix luarocks

]]
