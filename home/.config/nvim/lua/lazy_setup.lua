-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
-- vim.g.mapleader = " "

require("lazy").setup(
{
  rocks = {
    enabled = true,
    -- for now, because :checkhealth lazy says my luarocks install is broken, and I can't be bothered
    hererocks = false
  },
  spec = {
    {"scrooloose/nerdtree"},
    {"vim-airline/vim-airline"},
    {"vim-airline/vim-airline-themes"},
    {"tpope/vim-fugitive"},
    {"tpope/vim-rhubarb"},
    {"rbong/vim-flog"},
    {"ctrlpvim/ctrlp.vim"},
    {"elixir-lang/vim-elixir"},
    {"junegunn/fzf", build = ":call fzf#install()"},
    {"junegunn/fzf.vim"},
    {"jremmen/vim-ripgrep"},
    {"mhinz/vim-signify"},

    {"sbdchd/neoformat"},
    {"wesQ3/vim-windowswap"},
    {"tpope/vim-commentary"},
    {"tpope/vim-abolish"},

    {"nvim-lua/plenary.nvim"},
    {"dart-lang/dart-vim-plugin"},
    {"akinsho/flutter-tools.nvim"},

    --{"townk/vim-autoclose"},
    {"terryma/vim-multiple-cursors"},
    {"nelstrom/vim-visual-star-search"},

    {"janko/vim-test"},
    {"tpope/vim-dispatch"},
    {"tpope/vim-eunuch"},
    --{"tpope/vim-surround"},
    { 'echasnovski/mini.surround', version = '*' },
    { 'echasnovski/mini.clue', version = '*' },

    {"thaerkh/vim-workspace"},

    -- themes
    {"joshdick/onedark.vim"},
    {"tomasr/molokai"},
    {"srcery-colors/srcery-vim", lazy = false},
    {"gcmt/taboo.vim"},

    -- experimental
    {"tpope/vim-rails"},

    {"nvim-treesitter/playground"},

    -- {"neovim/nvim-lspconfig"},
    -- {"hrsh7th/cmp-path"},
    -- {"hrsh7th/cmp-buffer"},
    {'simrat39/symbols-outline.nvim'},
    --{'hrsh7th/nvim-cmp',
    --  dependencies = {
    --    {'hrsh7th/cmp-nvim-lsp'},
    --    {"hrsh7th/cmp-path"},
    --    {"hrsh7th/cmp-buffer"},
    --    {'L3MON4D3/LuaSnip', build = "make install_jsregexp" },
    --  }
    --},

    --{
    --  'VonHeikemen/lsp-zero.nvim',
    --  branch = 'v2.x',
    --  dependencies = {
    --    -- LSP Support
    --    {'neovim/nvim-lspconfig'},             -- Required
    --    {                                      -- Optional
    --      'williamboman/mason.nvim',
    --      build = function()
    --        pcall(vim.cmd, 'MasonUpdate')
    --      end,
    --    },
    --    {'williamboman/mason-lspconfig.nvim'}, -- Optional

    --    -- Autocompletion
    --    {'hrsh7th/nvim-cmp'},     -- Required
    --    {'hrsh7th/cmp-nvim-lsp'}, -- Required
    --    {'L3MON4D3/LuaSnip', build = "make install_jsregexp" },     -- Required
    --  }
    --},
    {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  --  {
  --    "folke/which-key.nvim",
  --    config = function()
  --      --vim.o.timeout = true
  --      --vim.o.timeoutlen = 300
  --      require("which-key").setup({
  --        -- your configuration comes here
  --        -- or leave it empty to use the default settings
  --        -- refer to the configuration section below
  --      })
  --    end,
  --  },

    {
        {"Cassin01/wf.nvim", version = "*", config = function() require("wf").setup() end}
    },
    {
    'nvim-telescope/telescope.nvim', tag = '0.1.4',
      dependencies = { 'nvim-lua/plenary.nvim' }
    },
    {"ahmedkhalf/project.nvim"},
    {'nvim-telescope/telescope-fzf-native.nvim', build = "make" },
    { "lukas-reineke/indent-blankline.nvim" },
    {
      "S1M0N38/love2d.nvim",
      cmd = "LoveRun",
      opts = { },
      keys = {
        { "<leader>v", desc = "LÖVE" },
        { "<leader>vv", "<cmd>LoveRun<cr>", desc = "Run LÖVE" },
        { "<leader>vs", "<cmd>LoveStop<cr>", desc = "Stop LÖVE" },
      },
    },
    {'github/copilot.vim'},
    {'fatih/vim-go'},
  --  {
  --    "greggh/claude-code.nvim",
  --    dependencies = {
  --      "nvim-lua/plenary.nvim", -- Required for git operations
  --    },
  --    config = function()
  --      require("claude-code").setup()
  --    end
  --  }
  }
})
