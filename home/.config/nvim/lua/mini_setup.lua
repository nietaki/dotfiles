require('mini.surround').setup()
local miniclue = require('mini.clue')
miniclue.setup(
  {
    triggers = {
      -- Leader triggers
      { mode = { 'n', 'x', 'v' }, keys = '<Leader>' },
      { mode = { 'n', 'x', 'v' }, keys = ','},

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
      { mode = 'n', keys = '<Leader>f', desc = '+ Fuzzy / file' },
      { mode = 'n', keys = '<Leader>w', desc = '+ Window' },
      { mode = 'n', keys = '<Leader>t', desc = '+ Tab' },
      { mode = 'n', keys = '<Leader>p', desc = '+ Project' },
      { mode = 'n', keys = '<Leader>y', desc = '+ Yank (copy sth)' },
      { mode = 'n', keys = '<Leader>y', desc = '+ Git actions' },
      { mode = 'n', keys = ',', desc = '+ LSP (and similar)' },
      { mode = 'n', keys = ',a', desc = '+ LSP actions' },
      { mode = 'n', keys = ',c', desc = '+ quickifx' },
      { mode = 'n', keys = ',d', desc = '+ diagnostics' },
      { mode = 'n', keys = ',g', desc = '+ go to' },
      { mode = 'n', keys = ',l', desc = '+ LSP list...' },
      { mode = 'n', keys = ',t', desc = '+ Test...' },
      miniclue.gen_clues.square_brackets(),
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.windows(),
      miniclue.gen_clues.z(),
    },
    window = {
      delay = 300,
      config = {
        width = 'auto',
        border = 'rounded',
      }
    }
  }
)
