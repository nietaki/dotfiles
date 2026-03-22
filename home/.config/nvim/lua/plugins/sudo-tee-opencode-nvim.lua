local opts = {
  preferred_picker = 'telescope',   -- 'telescope', 'fzf', 'mini.pick', 'snacks', 'select', if nil, it will use the best available picker. Note mini.pick does not support multiple selections
  preferred_completion = 'blink',   -- 'blink', 'nvim-cmp','vim_complete' if nil, it will use the best available completion
  default_global_keymaps = true,    -- If false, disables all default global keymaps
  default_mode = 'build',           -- 'build' or 'plan' or any custom configured. @see [OpenCode Agents](https://opencode.ai/docs/modes/)
  default_system_prompt = nil,      -- Custom system prompt to use for all sessions. If nil, uses the default built-in system prompt
  keymap_prefix = '<leader>o',      -- Default keymap prefix for global keymaps change to your preferred prefix and it will be applied to all keymaps starting with <leader>o
  opencode_executable = 'opencode', -- Name of your opencode binary
  server = {
    url = 'localhost',              -- URL/hostname (e.g., 'http://192.168.1.100', 'localhost', 'https://myserver.com')
    port = 4096,                    -- Port number (e.g., 8080), 'auto' for random port
    timeout = 5,                    -- Health check timeout in seconds when connecting
    spawn_command = nil,            -- Optional function to start the server: function(port, url) ... end
    auto_kill = false,              -- Kill spawned servers when last nvim instance exits (default: true) Only applies to servers spawned by the plugin with spawn_command/kill_command
    path_map = nil,                 -- Map host paths to server paths: string ('/app') or function(path) -> string
  },
  keymap = {
    input_window = {
      -- don't close the window on escape
      ['<esc>'] = false,
      -- Shift+enter to insert a newline, enter to submit
      ['<S-cr>'] = { function()
        --just emit a newline character using the vim api
        vim.api.nvim_put({ '' }, 'c', true, true)
      end },
      ['<cr>'] = { 'submit_input_prompt', mode = { 'n', 'i' } },
    },
  },
}


return {
  "sudo-tee/opencode.nvim",
  config = function()
    require("opencode").setup(opts)
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        anti_conceal = { enabled = false },
        file_types = { 'opencode_output' },
      },
      ft = { 'copilot-chat', 'opencode_output' },
    },
    'saghen/blink.cmp',

    -- Optional, for file mentions picker, pick only one
    -- 'folke/snacks.nvim',
    'nvim-telescope/telescope.nvim',
    -- 'ibhagwan/fzf-lua',
    -- 'nvim_mini/mini.nvim',
  },
}
