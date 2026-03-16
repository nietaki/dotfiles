
-- there's a bunch of stuff commented out before here in old.init.vim
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  float = true
})

require('symbols-outline').setup()

-- lines 911 to 984 went to leftovers.vim

local relevant_servers = {
    'glsl_analyzer',
    'lexical',
    'gopls',
    'elixirls',
    'dockerls',
    'ansiblels',
    'bashls',
    'helm_ls',
    'lua_ls',
  }


require('mason-lspconfig').setup({
  ensure_installed = relevant_servers,
  automatic_enable = true
})

-- TODO lazydev

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- iterate over relevant servers and set up capabilities for each

for _, server in ipairs(relevant_servers) do
  vim.lsp.config(
    server,
    {capabilities = capabilities}
  )
  vim.lsp.enable(server)
end
