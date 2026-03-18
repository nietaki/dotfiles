local au = {}

au.register_on_close = function()
  vim.api.nvim_create_autocmd('VimLeave', {
    pattern = '*',
    callback = function()
      vim.cmd 'silent! SymbolsOutlineClose'
    end,
  })
end

au.trim_whitespace = function()
  local save = vim.fn.winsaveview()
  vim.cmd [[keeppatterns %s/\s\+$//e]]
  vim.fn.winrestview(save)
end

au.register_filetype_specific = function()
  vim.api.nvim_create_autocmd('BufWritePre', {
    callback = au.trim_whitespace,
  })

  vim.api.nvim_create_autocmd(
    {'BufNewFile', 'BufRead', 'BufReadPost'}, {
    pattern = {'*.livemd', '*.md'},
    callback = function()
      vim.opt.filetype = 'markdown'
      vim.opt.syntax = 'markdown'
    end,
  })

  vim.api.nvim_create_autocmd(
    {'BufNewFile', 'BufRead', 'BufReadPost'}, {
    pattern = {'*.ino'},
    callback = function()
      vim.opt.filetype = 'cpp'
      vim.opt.syntax = 'cpp'
    end,
  })
end

au.setup_spellchecks = function()
  vim.opt.nowspell = true
  vim.opt.spelllang = 'en'

  vim.api.nvim_create_autocmd('FileType', {
    pattern = {'tex', 'markdown'},
    callback = function()
      vim.opt_local.spell = true
    end,
  })
end

au.setup = function()
  -- some copy-pasted stuff, not sure what it was supposed to do
  vim.g.go_def_mappings_enabled = 0
  au.register_on_close()
  au.register_filetype_specific()
end


return au
