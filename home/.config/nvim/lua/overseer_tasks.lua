local overseer = require("overseer")
-- local ntk = require('ntk_utils')

---@type overseer.TemplateDefinition
local fixme = {
  name = "fixme",
  params = {},
  builder = function(_params)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    -- [1]=line, [2]=col
    -- get relative path for the current buffer
    local relative_path = vim.fn.expand("%:~:.")
    return {
      cmd = { "opencode", "run", "--attach", "http://localhost:4096", "-s", "--dir", vim.fn.getcwd(), "--command", "fix", relative_path, tostring(cursor_pos[1]) },
      name = "fixme",
    }
  end,
}

overseer.register_template(fixme)


vim.api.nvim_create_user_command("Make", function(params)
  -- Insert args at the '$*' in the makeprg
  local cmd, num_subs = vim.o.makeprg:gsub("%$%*", params.args)
  if num_subs == 0 then
    cmd = cmd .. " " .. params.args
  end
  local task = require("overseer").new_task({
    cmd = vim.fn.expandcmd(cmd),
    components = {
      { "nietaki/mute_group", group = 'make' },
      {
        "on_output_quickfix",
        open_on_exit = "failure",
        open_height = 24,
        errorformat = vim.o.errorformat,
      },
      "default",
    },
  })
  task:start()
end, {
  desc = "Run your makeprg as an Overseer task",
  nargs = "*",
  bang = true,
})

-- for the built-in make targets
overseer.add_template_hook({}, function(task_def, util)
  util.add_component(task_def, { "nietaki/mute_group", group = 'make' })
  util.add_component(task_def,
    { "on_output_quickfix", open_height = 24, open_on_exit = "failure", errorformat = vim.o.errorformat })
end)

-- print('overseer tasks registered')
