
local snippet = {
  expand = function(args)
    require('luasnip').lsp_expand(args.body)
  end
}

-- TODO LSP
-- TODO alwaysSources


local primarySources = {
  { name = 'luasnip' },
  { name = 'copilot' },
}
local backupSources = {
  { name = 'buffer' },
  { name = 'path' }
}


-- https://github.com/hrsh7th/nvim-cmp/tree/v0.0.2?tab=readme-ov-file#recommended-configuration
local configFun = function(_lazyPlugin, baseOpts)
  local cmp = require('cmp')

  -- for more: :help cmp

  opts = {
    snippet = snippet,
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
    }),
    sources = cmp.config.sources(primarySources, backupSources)
  }

  -- force meens use rightmost option
  cmp.setup(vim.tbl_deep_extend('force', baseOpts, opts))
end


return {
  {
    'hrsh7th/nvim-cmp',
    event = "InsertEnter",
    opts = {},
    config = configFun,
    dependencies = {
      {'zbirenbaum/copilot-cmp'},
      {"hrsh7th/cmp-path"},
      {"hrsh7th/cmp-buffer"},
      {
        'L3MON4D3/LuaSnip',
        build = "make install_jsregexp" ,
        version = 'v2.*'
      },
    }
  },
}
