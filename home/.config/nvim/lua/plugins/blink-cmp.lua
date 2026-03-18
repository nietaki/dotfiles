return {
  {
    'saghen/blink.cmp',
    -- optional: provides snippets for the snippet source
    dependencies = {
      'rafamadriz/friendly-snippets',
      'fang2hou/blink-copilot'
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
    opts = {
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
      keymap = { preset = 'super-tab' },

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
          auto_show = false,
          auto_show_delay_ms = 1000,
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 0,
        },
        ghost_text = {
          enabled = true,
          show_with_selection = true,
          show_without_selection = true,
          show_with_menu = false,
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
        sources = { 'cmdline' }
      },
      sources = {
        default = { 'lazydev', 'codecompanion', 'copilot', 'lsp', 'path', 'snippets' },
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
        }
      },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = { implementation = "prefer_rust_with_warning" },
      enabled = function()
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
    },
    opts_extend = { "sources.default" }
  }
}
