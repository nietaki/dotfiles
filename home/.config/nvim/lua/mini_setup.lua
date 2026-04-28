require('mini.surround').setup()
local miniclue = require('mini.clue')
miniclue.setup(
  {
    triggers = {
      -- Leader triggers
      { mode = { 'n', 'x', 'v' }, keys = '<Leader>' },
      { mode = { 'n', 'x', 'v' }, keys = ',' },

      -- `[` and `]` keys
      { mode = 'n',               keys = '[' },
      { mode = 'n',               keys = ']' },

      -- Built-in completion
      { mode = 'i',               keys = '<C-x>' },

      -- `g` key
      { mode = { 'n', 'x' },      keys = 'g' },

      -- Marks
      { mode = { 'n', 'x' },      keys = "'" },
      { mode = { 'n', 'x' },      keys = '`' },

      -- Registers
      { mode = { 'n', 'x' },      keys = '"' },
      { mode = { 'i', 'c' },      keys = '<C-r>' },

      -- Window commands
      { mode = 'n',               keys = '<C-w>' },

      -- `z` key
      { mode = { 'n', 'x' },      keys = 'z' },
    },
    clues = {
      -- Enhance this by adding descriptions for <Leader> mapping groups
      { mode = 'n', keys = '<Leader>b',  desc = '+ buffer' },
      { mode = 'n', keys = '<Leader>c',  desc = '+ quickfix (TODO delete)' },
      { mode = 'n', keys = '<Leader>d',  desc = '+ strudel / art' },
      { mode = 'n', keys = '<Leader>f',  desc = '+ file' },
      { mode = 'n', keys = '<Leader>fe', desc = '+ edit key config files' },
      { mode = 'n', keys = '<Leader>g',  desc = '+ Git' },
      { mode = 'n', keys = '<Leader>m',  desc = '+ Make...' },
      { mode = 'n', keys = '<Leader>o',  desc = '+ OpenCode' },
      { mode = 'n', keys = '<Leader>p',  desc = '+ Project' },
      { mode = 'n', keys = '<Leader>q',  desc = '+ Quit?' },
      { mode = 'n', keys = '<Leader>s',  desc = '+ search / fuzzy...' },
      { mode = 'n', keys = '<Leader>t',  desc = '+ Tab / Toggle' },
      { mode = 'n', keys = '<Leader>w',  desc = '+ Window' },
      { mode = 'n', keys = '<Leader>y',  desc = '+ Yank (copy sth)' },
      { mode = 'n', keys = ',',          desc = '+ LSP (and similar)' },
      { mode = 'n', keys = ',a',         desc = '+ LSP actions' },
      { mode = 'n', keys = ',c',         desc = '+ quickifx' },
      { mode = 'n', keys = ',d',         desc = '+ diagnostics' },
      { mode = 'n', keys = ',g',         desc = '+ go to' },
      { mode = 'n', keys = ',l',         desc = '+ LSP list...' },
      { mode = 'n', keys = ',t',         desc = '+ Test...' },
      miniclue.gen_clues.square_brackets(),
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.windows(),
      miniclue.gen_clues.z(),
    },
    window = {
      delay = 400,
      config = {
        width = '50',
        border = 'rounded',
        -- the next two are needed for the 'anchor' to work
        row = 'auto',
        col = 'auto',
        anchor = 'NE',
      }
    }
  }
)
