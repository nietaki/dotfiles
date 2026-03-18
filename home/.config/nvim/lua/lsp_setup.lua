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
      { capabilities = capabilities }
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


---  :help lsp
-- GLOBAL DEFAULTS
--                                           *grr* *gra* *grn* *gri* *grt* *i_CTRL-S*
-- These GLOBAL keymaps are created unconditionally when Nvim starts:
-- - "grn" is mapped in Normal mode to |vim.lsp.buf.rename()|
-- - "gra" is mapped in Normal and Visual mode to |vim.lsp.buf.code_action()|
-- - "grr" is mapped in Normal mode to |vim.lsp.buf.references()|
-- - "gri" is mapped in Normal mode to |vim.lsp.buf.implementation()|
-- - "grt" is mapped in Normal mode to |vim.lsp.buf.type_definition()|
-- - "gO" is mapped in Normal mode to |vim.lsp.buf.document_symbol()|
-- - CTRL-S is mapped in Insert mode to |vim.lsp.buf.signature_help()|

-- BUFFER-LOCAL DEFAULTS
-- - 'omnifunc' is set to |vim.lsp.omnifunc()|, use |i_CTRL-X_CTRL-O| to trigger
--   completion.
-- - 'tagfunc' is set to |vim.lsp.tagfunc()|. This enables features like
--   go-to-definition, |:tjump|, and keymaps like |CTRL-]|, |CTRL-W_]|,
--   |CTRL-W_}| to utilize the language server.
-- - 'formatexpr' is set to |vim.lsp.formatexpr()|, so you can format lines via
--   |gq| if the language server supports it.
--   - To opt out of this use |gw| instead of gq, or clear 'formatexpr' on |LspAttach|.
-- - |K| is mapped to |vim.lsp.buf.hover()| unless |'keywordprg'| is customized or
--   a custom keymap for `K` exists.

local ntk = require('ntk_utils')

local telescope_document_symbols = function()
  require('telescope.builtin').lsp_document_symbols()
end

ntk.map('n', '<Leader>li', ':LspInfo<CR>', ':LspInfo')

-- LSP code actions
ntk.map('n', '<Leader>laf', vim.lsp.buf.format, 'format file with LSP')
ntk.map({'n', 'v'}, '<Leader>laa', vim.lsp.buf.code_action, 'code action')
ntk.map('n', '<Leader>lar', vim.lsp.buf.rename, 'rename thing under cursor')

-- LSP go to...
ntk.map('n', '<Leader>lgD', vim.lsp.buf.declaration, 'go to Declaration')
ntk.map('n', '<Leader>lgd', vim.lsp.buf.definition, 'go to definition')
ntk.map('n', '<Leader>lgi', vim.lsp.buf.implementation, 'go to implementation')
ntk.map('n', '<Leader>lgt', vim.lsp.buf.type_definition, 'go to type definition')

-- LSP list..
ntk.map('n', '<Leader>llr', vim.lsp.buf.references, 'list references')
ntk.map('n', '<Leader>llt', vim.lsp.buf.typehierarchy, 'show type hierarchy')
ntk.map('n', '<Leader>lls', telescope_document_symbols, 'FZF document symbols')
ntk.map('n', '<Leader>llo', ':SymbolsOutline<CR>', 'symbol outline')
