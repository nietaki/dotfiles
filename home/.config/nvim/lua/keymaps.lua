local km = {}

local ntk = require('ntk_utils')

local function key_files_keymaps()
  ntk.map('n', '<Leader>fed', ':e ~/.config/nvim/init.lua<CR>')
  ntk.map('n', '<Leader>feD', ':tabnew ~/.homesick/repos/dotfiles/README.md<CR>:tcd %:p:h<CR>', 'open dotfiles in new tab')
  ntk.map('n', '<Leader>feP', ':tabnew ~/puter/README.md<CR>:tcd %:p:h<CR>', 'open puter in new tab')
  ntk.map('n', '<Leader>fev', ':e ~/.vimrc<CR>')
  ntk.map('n', '<Leader>fez', ':e ~/.zshrc<CR>')
  -- todo an implementation that actually works, this will only work on experimental stuff
  ntk.map('n', '<Leader>fer', ':so ~/.config/nvim/init.lua<CR>', 'reload vim config')
end

local function buffers_and_windows()
  vim.g.windowswap_map_keys = 0 -- prevent default bindings

  -- buffers
  ntk.map('n', '<Leader>bb', ':b#<CR>', 'switch to last buffer')
  ntk.map('n', '<Leader>bn', ':bn<CR>')
  ntk.map('n', '<Leader>bp', ':bp<CR>')
  ntk.map('n', '<Leader>bd', ':bp|:bd #<CR>', 'close currently open buffer')
  ntk.map('n', '<Leader>bh', ':CtrlPMRUFiles<CR>', 'FZF in recent buffers')
  ntk.map('n', '<Leader>b/', ':BLines<CR>', 'FZF in current Buffer')
  ntk.map('n', '<Leader><Tab>', ':b#<CR>', 'switch between last two buffers')

  -- windows
  ntk.map('n', '<Leader>wd', ':hide<CR>', 'quit current window')
  ntk.map('n', '<Leader>ws', ':call WindowSwap#EasyWindowSwap()<CR>', 'easy WindowSwap')
  ntk.map('n', '<Leader>wl', '<C-W><C-L>', 'go one window right')
  ntk.map('n', '<Leader>wj', '<C-W><C-J>', 'go one window down')
  ntk.map('n', '<Leader>wk', '<C-W><C-K>', 'go one window up')
  ntk.map('n', '<Leader>wh', '<C-W><C-H>', 'go one window left')
  ntk.map('n', '<Leader>wn', '<C-W><C-W>', 'go to Next window')
  ntk.map('n', '<Leader>wo', '<C-W><C-O>', 'make this the Only window')
  ntk.map('n', '<Leader>ww', '<C-W><C-P>', 'toggle to previous window')
  ntk.map('n', '<Leader>wL', '<C-W><C-B>', 'go to bottom-right window')
  ntk.map('n', '<Leader>wH', '<C-W><C-T>', 'go to top-left window')
  ntk.map('n', '<Leader>wm', [[<C-W>_<C-W>|]], 'Maximize!')
  ntk.map('n', '<Leader>w=', '<C-W>=', 'distribute windows equally')
  ntk.map('n', '<Leader>w>', ':vertical resize +10<CR>', 'make wider')
  ntk.map('n', '<Leader>w<', ':vertical resize -10<CR>', 'make narrower')
  ntk.map('n', '<Leader>w/', ':vsp<CR>')
  ntk.map('n', '<Leader>w-', ':sp<CR>')
  ntk.map('n', '<Leader>wf', '<C-w>F', 'open file:line under curson in new window')
end

local others = function()
  ntk.map('n', '<Leader>qq', ':qa<CR>', 'Quit!')
end

function km.setup()
  ntk.map('n', 'S', '"_diwP', 'replace word with yanked text')
  key_files_keymaps()
  buffers_and_windows()
  others()
end

return km
