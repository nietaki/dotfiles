vim.cmd 'runtime! vimscript/migration_utils.vim'
vim.cmd 'runtime! vimscript/compat.vim'
vim.cmd 'runtime! vimscript/pre_plugin_config.vim'

-- easier switching between cmp options
vim.g.chosenCmp = 'blink'

require('lazy_setup')

require('ntk_utils')

require('nerd_tree').setup()

vim.cmd 'runtime! vimscript/search_config.vim'

vim.cmd 'runtime! vimscript/git_stuff.vim'

require('workspace_stuff')
require('lsp_setup')

require('treesitter_setup')

require('autocommands').setup()

require('keymaps').setup()

local ok, _ = pcall(require, 'experimental')
if not ok then
  print('Experimental module failed to load')
end

-- # backup plan :D
-- vim.cmd 'runtime! old.init.vim'

-- last in case it needs all the mappings to be there
require('mini_setup')

--[[

## Gameplan:

- [x] break down the old config into pieces
- [x] go through the files and purge all the old keymaps and plugins - it's safe if we have a nice git history and the old config as reference
- [x] set up barebones nvim-cmp
- [x] plug in one lsp server into nvim-cmp
- [x] vim to lua cheat sheet
- [x] damn nerdfonts
- [x] blink instead of cmp? pros and cons please
- [x] lazy coder for lua lsp
- [x] shortcuts for editing config in new place
- [x] lsp polish, shortcuts
- [ ] codecompanion
- [x] which key?


## long tail
- [ ] go through all keymaps and either give them a description or delete them (<Leader>fk)
- choose a vim fragment
- translate to lua
- ???
- PROFIT

## wishlist

- [x] break down the plugins config into files (there's a way that I don't understand yet)
- [ ] fix luarocks

]]
