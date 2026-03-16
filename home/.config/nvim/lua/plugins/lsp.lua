return {
  {'neovim/nvim-lspconfig'},
  {
    'mason-org/mason.nvim',
    opts = {},
     build = function()
       pcall(vim.cmd, 'MasonUpdate')
     end,
  },
  {
      "mason-org/mason-lspconfig.nvim",
      opts = {
        -- cause we want to advertise capabilities in lsp_setup
        automatic_enable = false,
      },
      dependencies = {
          { "mason-org/mason.nvim", opts = {} },
          "neovim/nvim-lspconfig",
      },
  }
}
