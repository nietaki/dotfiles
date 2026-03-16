
-- "let g:workspace_session_directory = $HOME . '/.vim/sessions/'
-- let g:workspace_session_disable_on_args = 1
-- let g:workspace_autosave = 0
-- let g:workspace_autosave_untrailspaces = 0

vim.api.nvim_set_var('workspace_session_disable_on_args', '1')
vim.api.nvim_set_var('workspace_autosave', 0)
vim.api.nvim_set_var('workspace_autosave_untrailspaces', '0')

-- require('mini.clue').setup({

--     triggers = {
--       -- Leader triggers
--       { mode = 'n', keys = '<Leader>' },
--       { mode = 'x', keys = '<Leader>' },

--       -- Leader triggers
--       { mode = 'n', keys = ',' },
--       { mode = 'x', keys = ',' },
--     }
-- })
-- require('mini.surround').setup()
require("project_nvim").setup {
    -- Manual mode doesn't automatically change your root directory, so you have
    -- the option to manually do so using `:ProjectRoot` command.
    manual_mode = false,

    -- Methods of detecting the root directory. **"lsp"** uses the native neovim
    -- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
    -- order matters: if one is not detected, the other is used as fallback. You
    -- can also delete or rearangne the detection methods.
    --detection_methods = { "lsp", "pattern" },
    detection_methods = { "pattern", "lsp" },

    -- All the patterns used to detect root dir, when **"pattern"** is in
    -- detection_methods
    --patterns = { ".git", "mix.exs", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json" },
    -- patterns = { ".git", "mix.exs"},
    patterns = { "mix.exs", ".git"},

    -- Table of lsp clients to ignore by name
    -- eg: { "efm", ... }
    ignore_lsp = {},

    -- Don't calculate root dir on specific directories
    -- Ex: { "~/.cargo/*", ... }
    exclude_dirs = {},

    -- Show hidden files in telescope
    show_hidden = true,

    -- When set to false, you will get a message when project.nvim changes your
    -- directory.
    silent_chdir = false,

    -- What scope to change the directory, valid options are
    -- * global (default)
    -- * tab
    -- * win
    scope_chdir = 'tab',

    -- Path where project.nvim will store the project history for use in
    -- telescope
    datapath = vim.fn.stdpath("data"),
  }

local actions = require "telescope.actions"
require('telescope').setup{
  defaults = {
    -- Default configuration for telescope goes here:
    -- config_key = value,
    file_ignore_patterns = {"node_modules", ".git/", "_build", "deps/", "erl_crash.dump"},
    mappings = {
      i = {
      ["<C-j>"] = actions.move_selection_next,
      ["<C-k>"] = actions.move_selection_previous,
        -- map actions.which_key to <C-h> (default: <C-/>)
        -- actions.which_key shows the mappings for your picker,
        -- e.g. git_{create, delete, ...}_branch for the git_branches picker
        --["<C-h>"] = "which_key"
      },
      n = {
      ["<C-j>"] = actions.move_selection_next,
      ["<C-k>"] = actions.move_selection_previous,
      }
    }
  },
  pickers = {
    -- Default configuration for builtin pickers goes here:
    -- picker_name = {
    --   picker_config_key = value,
    --   ...
    -- }
    -- Now the picker_config_key will be applied every time you call this
    -- builtin picker
  },
  extensions = {
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    }
  }
}
require('telescope').load_extension('fzf')
require('telescope').load_extension('projects')

vim.keymap.set('n', '<leader>pp', function() require'telescope'.extensions.projects.projects{} end)
