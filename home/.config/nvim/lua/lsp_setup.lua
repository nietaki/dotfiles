
-- there's a bunch of stuff commented out before here in old.init.vim
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  float = true,
  underline = true
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



-- check which cmp we're using
if package.loaded['cmp_nvim_lsp'] then
  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  -- iterate over relevant servers and set up capabilities for each

  for _, server in ipairs(relevant_servers) do
    vim.lsp.config(
      server,
      {capabilities = capabilities}
    )
    vim.lsp.enable(server)
  end
end

if vim.g.chosenCmp == 'blink' then
  -- https://cmp.saghen.dev/configuration/appearance.html#highlight-groups
  -- make the ghost text more visible - just make it look like a comment
  vim.api.nvim_set_hl(
    0,
    'BlinkCmpGhostText',
    { link = 'Comment' }
  )

  -- vim.api.nvim_set_hl(0, 'BlinkCmpGhostText', { fg = '#cdd6f4', bg = '#1e1e2e' })
end
