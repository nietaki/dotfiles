local nerd_tree = {}

local ntk = require('ntk_utils')

local open_current_file = function()
  if vim.fn.exists('b:NERDTree') == 1 then
    vim.cmd 'NERDTreeClose'
  else
    vim.cmd 'NERDTreeFind'
  end
end

nerd_tree.setup = function()
  vim.api.nvim_create_autocmd('VimLeave', {
    pattern = '*',
    callback = function()
      vim.cmd 'NERDTreeClose'
    end,
  })

  vim.g.NERDTreeQuitOnOpen = 1
  vim.g.NERDTreeAutoDeleteBuffer = 1

  ntk.map('n', [[<C-\>]], ':NERDTreeToggle<CR>', 'toggle nerd tree')
  ntk.map('n', [[<C-'>]], open_current_file, 'open current file in nerd tree')
end

return nerd_tree
