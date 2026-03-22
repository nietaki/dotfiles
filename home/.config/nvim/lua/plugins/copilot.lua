local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
end


-- TODO move to ye olde tpope plugin

return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    main = 'copilot',
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        txt = false,
        sh = function()
          if string.match(vim.api.nvim_buf_get_name(0), '%.env') then
            return false
          end
          return true
        end,
        yaml = function()
          local path = vim.api.nvim_buf_get_name(0)
          if string.match(path, '%.ansible') then
            return false
          end
          return true
        end,
      }
      -- suggestion = { enabled = true },
      -- panel = { enabled = true },
    }
  },
}
