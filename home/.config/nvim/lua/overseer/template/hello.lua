---@type overseer.TemplateFileDefinition
return {
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

    -- print("project root dir" .. vim.fn.getcwd())
    -- print("path: " .. relative_path)
    -- print("Cursor position: " .. cursor_line .. ":" .. cursor_col)

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
      components = {
        -- { "nietaki/hello_component", foo = 'bar' },
        "nietaki/mute_group",
        -- "nietaki/hello_component",
        -- this is important!
        "default"
      },
      -- arbitrary table of data for your own personal use
      metadata = {
        mute_group = "hello"
      },
    }
  end,
  -- Optional fields
  desc = "Optional description of task",
  -- Tags can be used in overseer.run_task()
  -- tags = { overseer.TAG.BUILD },
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
