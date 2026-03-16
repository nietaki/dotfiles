local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_text(0, line-1, 0, line-1, col, {})[1]:match("^%s*$") == nil
end


return {
  {
    'zbirenbaum/copilot.lua',
    tag = 'v2.*',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    }
  },
  {
    'zbirenbaum/copilot-cmp',
    tag = 'v2.*',
    -- TODO lspkind https://github.com/zbirenbaum/copilot-cmp?tab=readme-ov-file#highlighting--icon
    opts = {
      event = {
        'InsertEnter',
        'LspAttach',
      },
      fix_pairs = true
    },
    dependencies = {
      'zbirenbaum/copilot.lua'
    }
  },
}
