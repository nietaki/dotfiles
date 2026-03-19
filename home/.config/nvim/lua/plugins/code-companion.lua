return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  enabled = false,
  opts = {
    -- NOTE: The log_level is in `opts.opts`
    opts = {
      log_level = "DEBUG", -- or "TRACE"
    },
    interactions = {
      --NOTE: Change the adapter as required
      chat = { adapter = "copilot" },
      inline = { adapter = "copilot" },
    },
  },
}
