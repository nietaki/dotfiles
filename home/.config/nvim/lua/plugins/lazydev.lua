return {
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
      },
      enabled = function(root_dir)
        if string.match(root_dir, 'dotfiles') or string.match(root_dir, 'single') then
           return true
        end
        return false
      end,
    },
  }
}
