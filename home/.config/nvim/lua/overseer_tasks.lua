local overseer = require("overseer")
local ntk = require('ntk_utils')

---@type overseer.TemplateDefinition
local hello = {
  -- Required fields
  name = "say hello",
  builder = function(_params)
    -- This must return an overseer.TaskDefinition
    -- check the user's username
    local username = os.getenv("USER") or "world"
    -- check the curent wall clock time
    local time = os.date("%H:%M:%S")

    -- get cursor line
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    -- get cursor column
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    -- get relative path for the current buffer
    local relative_path = vim.fn.expand("%:~:.")

    print("project root dir" .. vim.fn.getcwd())
    print("path: " .. relative_path)
    print("Cursor position: " .. cursor_line .. ":" .. cursor_col)

    -- check the pwd
    local pwd = vim.fn.getcwd()
    return {
      -- cmd is the only required field. It can be a list or a string.
      cmd = { "echo", pwd, time, "hello", username },
      -- additional arguments for the cmd (usually only useful if cmd is a string)
      args = {},
      -- the name of the task (defaults to the cmd of the task)
      name = "Greet",
      -- set the working directory for the task
      -- cwd = "/tmp",
      -- additional environment variables
      env = {
        VAR = "FOO",
      },
      -- the list of components or component aliases to add to the task
      -- components = { "my_custom_component", "default" },
      -- arbitrary table of data for your own personal use
      metadata = {
        foo = "bar",
      },
    }
  end,
  -- Optional fields
  desc = "Optional description of task",
  -- Tags can be used in overseer.run_task()
  tags = { overseer.TAG.BUILD },
  params = {
    -- See :help overseer-params
  },
  -- Add requirements for this template. If they are not met, the template will not be visible.
  -- All fields are optional.
  -- condition = {
  --   -- A string or list of strings
  --   -- Only matches when current buffer is one of the listed filetypes
  --   -- filetype = { "c", "cpp", "lua" },
  --   -- A string or list of strings
  --   -- Only matches when cwd is inside one of the listed dirs
  --   -- dir = "/home/user/my_project",
  -- },
}

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

---@type overseer.TemplateDefinition
local make = {
  name = "make...",
  params = function()
    local targets = ntk.parse_makefile()
    -- ntk.debug(targets)
    if #targets == 0 then
      targets = { "all", "clean" }
    end
    -- ntk.debug(targets)
    return {
      target = {
        type = "enum",
        choices = targets,
        name = "Make Target",
        required = true,
      },
    }
  end,
  builder = function(params)
    return {
      cmd = { "make", params.target },
    }
  end,
  desc = "Run make with a specific target",
}


overseer.register_template(hello)
overseer.register_template(fixme)
overseer.register_template(make)

vim.api.nvim_create_user_command("Make", function(params)
  -- Insert args at the '$*' in the makeprg
  local cmd, num_subs = vim.o.makeprg:gsub("%$%*", params.args)
  if num_subs == 0 then
    cmd = cmd .. " " .. params.args
  end
  local task = require("overseer").new_task({
    cmd = vim.fn.expandcmd(cmd),
    components = {
      {
        "on_output_quickfix",
        open = not params.bang,
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

print('overseer tasks registered')
