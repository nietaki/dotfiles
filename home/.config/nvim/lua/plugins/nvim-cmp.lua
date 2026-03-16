-- TODO switch to blink (or not, because it needs nerd fonts)
-- but it does ghost text better than
-- ...it has much better documentation than cmp though


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
  { name = 'nvim_lsp' },
}
local backupSources = {
  { name = 'buffer' },
  { name = 'path' }
}


-- https://github.com/hrsh7th/nvim-cmp/tree/v0.0.2?tab=readme-ov-file#recommended-configuration
local configFun = function(_lazyPlugin, baseOpts)
  local cmp = require('cmp')

  -- for more: :help cmp

  local opts = {
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
    enabled = function()
      return vim.g.chosenCmp == 'cmp'
    end,
    dependencies = {
      {'zbirenbaum/copilot-cmp'},
      {"hrsh7th/cmp-path"},
      {'hrsh7th/cmp-nvim-lsp'},
      -- TODO https://github.com/hrsh7th/cmp-nvim-lsp-document-symbol
      -- TODO https://github.com/hrsh7th/cmp-nvim-lsp-signature-help
      {"hrsh7th/cmp-buffer"},
      {
        'L3MON4D3/LuaSnip',
        build = "make install_jsregexp" ,
        version = 'v2.*'
      },
    }
  },
  {
    'zbirenbaum/copilot-cmp',
    -- TODO lspkind https://github.com/zbirenbaum/copilot-cmp?tab=readme-ov-file#highlighting--icon
    enabled = function()
      return vim.g.chosenCmp == 'cmp'
    end,
    opts = {
      event = {
        'InsertEnter',
        'LspAttach',
      },
      fix_pairs = true
    },
    dependencies = {
      'zbirenbaum/copilot.lua'
    }
  },
}
