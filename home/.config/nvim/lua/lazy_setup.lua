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
  ui = {
    -- still stupid, but still better than nerdfonts
    icons = {
      cmd = '⌘',
      config = '🛠',
      debug = "[dbg]",
      event = '📅',
      ft = '📂',
      import = "[imp]",
      init = '⚙',
      keys = '🗝',
      lazy = '💤 ',
      loaded = "●",
      not_loaded = "○",
      plugin = '🔌',
      require = '🌙',
      runtime = '💻',
      source = '📄',
      start = '🚀',
      task = '📌',
      list = {
        "●",
        "➜",
        "★",
        "‒",
      },
    },
  },
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

    --{"townk/vim-autoclose"},
    -- {"terryma/vim-multiple-cursors"},
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
    -- TODO taboo is unmaintained, figure out why I added it and replace with something else
    {"gcmt/taboo.vim"},

    {"nvim-treesitter/playground"},

    {'simrat39/symbols-outline.nvim'},
    {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
    -- which-key, needs configuration
    -- {"Cassin01/wf.nvim", version = "*", config = function() require("wf").setup() end},
    {
    'nvim-telescope/telescope.nvim', tag = '0.1.4',
      dependencies = { 'nvim-lua/plenary.nvim' }
    },
    {"ahmedkhalf/project.nvim"},
    {'nvim-telescope/telescope-fzf-native.nvim', build = "make" },
    { "lukas-reineke/indent-blankline.nvim" },
    {'github/copilot.vim'},
    {'fatih/vim-go'},
  }
})
