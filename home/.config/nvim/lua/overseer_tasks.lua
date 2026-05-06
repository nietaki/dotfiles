local overseer = require("overseer")
-- local ntk = require('ntk_utils')

local quickfix_session_id = nil

local session_id_lines_mapper = function(lines)
  local session_id = lines[1] or nil
  return { session_id = session_id }
end

local session_id_complete_handler = function(status, result)
  if status == overseer.Status.SUCCESS and type(result.session_id) == "string" then
    quickfix_session_id = result.session_id
  else
    print("Failed to find session id")
  end
end

local opencode_session_id_finder = {
  cmd = { "~/bin/opencode_quickfix_session_id" },
  name = "opencode_session_id_finder",
  components = {
    {
      "nietaki/result_extractor",
      lines_mapper = session_id_lines_mapper,
      complete_handler = session_id_complete_handler,
    },
  },
}

-----@type overseer.TemplateDefinition
--local fixme = {
--  name = "fixme",
--  params = {},
--  builder = function(_params)
--    local cursor_pos = vim.api.nvim_win_get_cursor(0)
--    -- [1]=line, [2]=col
--    -- get relative path for the current buffer
--    local relative_path = vim.fn.expand("%:~:.")
--    return {
--      cmd = { "opencode", "run", "--attach", "http://localhost:4096", "-s", quickfix_session_id, "--dir", vim.fn.getcwd(), "--command", "fix", relative_path, tostring(cursor_pos[1]) },
--      -- cmd = { "ls", "-alh" },
--      -- cmd = { "env" },
--      -- env = {
--      --   -- get the env var
--      --   OPENCODE_SERVER_PASSWORD = os.getenv("OPENCODE_SERVER_PASSWORD"),
--      -- },
--      name = "fixme",
--      components = {
--        {
--          "dependencies",
--          tasks = {
--            opencode_session_id_finder,
--          },
--          sequential = true,
--        }
--      }
--    }
--  end,
--}

-- overseer.register_template(fixme)

overseer.register_template({
  name = "homeshick link",
  desc = "run homeshick link",
  params = {},
  builder = function()
    return {
      name = "homeshick link",
      cmd = { vim.uv.os_homedir() .. "/.homesick/repos/homeshick/bin/homeshick", "link" },
    }
  end,
})

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

-- -- for the built-in make targets
-- overseer.add_template_hook({}, function(task_def, util)
--   util.add_component(task_def,
--     { "on_output_quickfix", open_height = 24, open_on_exit = "failure", errorformat = vim.o.errorformat })
-- end)

-- print('overseer tasks registered')
