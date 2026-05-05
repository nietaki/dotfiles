local au = {}

au.register_on_close = function()
  vim.api.nvim_create_autocmd('VimLeave', {
    pattern = '*',
    callback = function()
      vim.cmd 'silent! SymbolsOutlineClose'
    end,
  })
end

local trim_whitespace = function()
  local save = vim.fn.winsaveview()
  vim.cmd [[keeppatterns %s/\s\+$//e]]
  vim.fn.winrestview(save)
end

au.register_filetype_specific = function()
  vim.api.nvim_create_autocmd('BufWritePre', {
    callback = function(opts)
      local bufno = opts.buf
      trim_whitespace()
      local capable_clients =
          vim.lsp.get_clients({ bufnr = bufno, method = vim.lsp.protocol.Methods.textDocument_formatting })
      if #capable_clients > 0 then
        vim.lsp.buf.format({ bufnr = bufno })
      end
    end
  })

  vim.api.nvim_create_autocmd(
    { 'BufNewFile', 'BufRead', 'BufReadPost' }, {
      pattern = { '*.livemd', '*.md' },
      callback = function()
        vim.opt.filetype = 'markdown'
        vim.opt.syntax = 'markdown'
      end,
    })

  vim.api.nvim_create_autocmd(
    { 'BufNewFile', 'BufRead', 'BufReadPost' }, {
      pattern = { '*.ino' },
      callback = function()
        vim.opt.filetype = 'cpp'
        vim.opt.syntax = 'cpp'
      end,
    })
end

au.setup_spellchecks = function()
  vim.opt.spell = false
  vim.opt.spelllang = 'en'

  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'tex', 'markdown' },
    callback = function()
      vim.opt_local.spell = true
    end,
  })
end

au.close_opencode_on_exit = function()
  vim.api.nvim_create_autocmd('VimLeave', {
    pattern = '*',
    callback = function()
      vim.cmd 'Opencode close'
    end,
  })
end

au.setup_tresitter = function()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'lua', 'elixir', 'elixirscript', 'go', 'python', 'javascript', 'html', 'css' },
    callback = function()
      vim.treesitter.start()
      vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.wo[0][0].foldmethod = 'expr'
    end,
  })
end

au.detect_extensionless_shell_scripts = function()
  vim.filetype.add({
    pattern = {
      ['.*'] = {
        function(path, bufnr)
          -- skip files that have an extension
          if path:match('%.[^/]+$') then return end
          local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ''
          if first_line:match('^#!/.*bash') then
            return 'sh', function(b)
              vim.b[b].is_bash = 1
            end
          elseif first_line:match('^#!/.*zsh') then
            return 'zsh'
          elseif first_line:match('^#!/.*sh') then
            return 'sh', function(b)
              vim.b[b].is_sh = 1
            end
          end
        end,
        { priority = -math.huge },
      },
    },
  })
end

au.setup = function()
  -- some copy-pasted stuff, not sure what it was supposed to do
  vim.g.go_def_mappings_enabled = 0
  au.register_on_close()
  au.register_filetype_specific()
  au.setup_spellchecks()
  au.detect_extensionless_shell_scripts()
  -- au.setup_tresitter()
  -- au.close_opencode_on_exit()
end


return au
