local opts = {
  -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
  -- 'super-tab' for mappings similar to vscode (tab to accept)
  -- 'enter' for enter to accept
  -- 'none' for no mappings
  --
  -- All presets have the following mappings:
  -- C-space: Open menu or open docs if already open
  -- C-n/C-p or Up/Down: Select next/previous item
  -- C-e: Hide menu
  -- C-k: Toggle signature help (if signature.enabled = true)
  --
  -- See :h blink-cmp-config-keymap for defining your own keymap
  keymap = {
    preset = 'default',
    ['<CR>'] = { 'select_and_accept', 'fallback' },
    ['<Esc>'] = { 'cancel', 'fallback' },
    ['C-e'] = { 'hide', 'cancel', 'fallback' },
    ['<Tab>'] = {
      function(cmp)
        if cmp.is_menu_visible() or cmp.is_ghost_text_visible() then
          return cmp.select_and_accept({ force = true })
        end
      end,

      'fallback' },
  },

  appearance = {
    -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
    -- Adjusts spacing to ensure icons are aligned
    nerd_font_variant = 'mono'
  },

  -- (Default) Only show the documentation popup when manually triggered
  completion = {
    menu = {
      -- showing it too quickly interferes with the ghost text a bit
      -- remember, you can use <C-Space>
      auto_show = true,
      auto_show_delay_ms = 600,
      direction_priority = function()
        local ctx = require('blink.cmp').get_context()
        local item = require('blink.cmp').get_selected_item()
        if ctx == nil or item == nil then return { 's', 'n' } end

        local item_text = item.textEdit ~= nil and item.textEdit.newText or item.insertText or item.label
        local is_multi_line = item_text:find('\n') ~= nil

        -- after showing the menu upwards, we want to maintain that direction
        -- until we re-open the menu, so store the context id in a global variable
        if is_multi_line or vim.g.blink_cmp_upwards_ctx_id == ctx.id then
          vim.g.blink_cmp_upwards_ctx_id = ctx.id
          return { 'n', 's' }
        end
        return { 's', 'n' }
      end,
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 400,
    },
    ghost_text = {
      enabled = true,
      show_with_selection = true,
      show_without_selection = false,
      show_with_menu = true,
      show_without_menu = true,
    }
  },

  -- -- snippets = { preset = 'default' | 'luasnip' | 'mini_snippets' | 'vsnip' },
  snippets = {
    preset = 'default',
  },

  -- Default list of enabled providers defined so that you can extend it
  -- elsewhere in your config, without redefining it, due to `opts_extend`
  cmdline = {
    sources = { 'cmdline', 'path' },
    keymap = { preset = 'inherit' },
    completion = { menu = { auto_show = true } },
  },
  sources = {
    default = { 'lazydev', 'copilot', 'lsp', 'snippets', 'emoji', 'path' },
    per_filetype = {
      copilot = { 'lsp', 'path' }
    },
    providers = {
      copilot = {
        name = 'copilot',
        module = 'blink-copilot',
        score_offset = 100,
        async = true
      },
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        -- make lazydev completions top priority (see `:h blink.cmp`)
        score_offset = 100,
      },
      emoji = {
        module = "blink-emoji",
        name = "Emoji",
        score_offset = 15, -- Tune by preference
        opts = {
          insert = true,   -- Insert emoji (default) or complete its name
          ---@type string|table|fun():table
          trigger = function()
            return { ":" }
          end,
        },
        should_show_items = function()
          return vim.tbl_contains(
          -- Enable emoji completion only for git commits and markdown.
          -- By default, enabled for all file-types.
            { "gitcommit", "markdown" },
            vim.o.filetype
          )
        end,
      },

      snippets = {
        opts = {
          filter_snippets = function(ft, file)
            if vim.tbl_contains({ 'opencode', 'gitcommit' }, ft) then
              return false
            end
          end
        }
      }
    }
  },
  -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
  -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
  -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
  --
  -- See the fuzzy documentation for more information
  fuzzy = { implementation = "prefer_rust_with_warning" },
  enabled = function()
    if vim.snippet.active() then
      return false
    end
    -- local filetype = vim.api.nvim_buf_get_option(0, 'filetype')
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = 0 })
    if vim.tbl_contains({ 'gitcommit' }, filetype) then
      return false
    end
    local path = vim.api.nvim_buf_get_name(0)
    if vim.tbl_contains({ 'bash', 'zsh', 'sh' }, filetype) then
      if string.match(path, '%.env') then
        return false
      end
    end
    if string.match(path, '%.ansible') then
      return false
    end
    return true
  end,
  -- Experimental signature help support
  signature = { enabled = true }
}

return {
  {
    'saghen/blink.cmp',
    -- optional: provides snippets for the snippet source
    dependencies = {
      'rafamadriz/friendly-snippets',
      'fang2hou/blink-copilot',
      'moyiz/blink-emoji.nvim',
    },

    enabled = function()
      return vim.g.chosenCmp == 'blink'
    end,

    -- use a release tag to download pre-built binaries
    version = '1.*',
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = opts,
  }
}
