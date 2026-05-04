return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- "stevearc/overseer.nvim",
      -- adapters
      "jfpedroza/neotest-elixir",
      "nvim-neotest/neotest-go",
    },
    config = function()
      -- get neotest namespace (api call creates or returns namespace)
      local neotest_ns = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        -- virtual_text = {
        --   format = function(diagnostic)
        --     local message =
        --         diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
        --     return message
        --   end,
        -- },
        virtual_text = true,
        signs = true,
        float = true,
        underline = true
      }, neotest_ns)
      local opts = {
        consumers = {},
        log_level = 1,
        diagnostic = {
          enabled = true,
          severity = vim.diagnostic.severity.ERROR,
        },
        status = {
          virtual_text = true,
          signs = true
        },
        -- consumers = {
        --   overseer = require("neotest.consumers.overseer"),
        -- },
        -- overseer = {
        --   enabled = true,
        --   -- When this is true (the default), it will replace all neotest.run.* commands
        --   force_default = false,
        -- },
        adapters = {
          require("neotest-elixir"),
          require("neotest-go"),
        }
      }
      require("neotest").setup(opts)
    end
  }
}
