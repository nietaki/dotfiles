---@type overseer.ComponentFileDefinition
local overseer = require("overseer")
local ntk = require("ntk_utils")

-- overseer.Task                                                      *overseer.Task*

--     Fields:
--       {id}            `integer` Unique ID for this task
--       {result}        `nil|table<string, any>` For successful tasks, arbitrary
--                       key-value mapping of data produced by components
--       {metadata}      `table<string, any>` Arbitrary key-value mapping passed by
--                       the user during construction
--       {status}        `overseer.Status` Current task status
--       {cmd}           `string|string[]` Command to run. If it's a string it is
--                       run in the shell
--       {cwd}           `string` Working directory the task is run in
--       {env}           `nil|table<string, string>` Additional environment
--                       variables for the task
--       {name}          `string` Name of the task
--       {ephemeral}     `boolean` Indicates that this task was generated
--                       indirectly (e.g. with run_after)
--       {source}        `nil|overseer.Caller` If this task was created by wrapping
--                       jobstart/vim.system, this contains information about the
--                       callsite
--       {exit_code}     `nil|integer` Exit code of the task process
--       {parent_id}     `nil|integer` ID of parent task. Used only to visually
--                       group tasks in the task list
--       {time_start}    `nil|integer` Timestamp when the task was started
--                       (os.time())
--       {time_end}      `nil|integer` Timestamp when the task ended (os.time())
return {
  desc = "task result extractor component",
  -- Define parameters that can be passed in to the component
  params = {
    -- (string[]) -> map-like table
    lines_mapper = {
      type = "opaque",
      required = true,
    },

    -- (overseer.Status, result) -> any
    complete_handler = {
      type = "opaque",
      required = true,
    }
    -- See :help overseer-params
  },
  -- Optional, default true. Set to false to disallow editing this component in the task editor
  editable = false,
  -- Optional, default true. When false, don't serialize this component when saving a task to disk
  serializable = false,
  -- The params passed in will match the params defined above
  constructor = function(params)
    -- You may optionally define any of the methods below
    return {
      lines_mapper = params.lines_mapper,
      complete_handler = params.complete_handler,
      _lines = {},
      ---@return table
      on_pre_result = function(self, task)
        return self.lines_mapper(self._lines)
      end,

      ---@param status overseer.Status Can be CANCELED, FAILURE, or SUCCESS
      ---@param result table A result table.
      on_complete = function(self, task, status, result)
        if type(self.complete_handler) == "function" then
          self.complete_handler(status, result)
        end
      end,

      ---@param lines string[] Completed lines of output, with ansi codes removed.
      on_output_lines = function(self, task, lines)
        self._lines = vim.list_extend(self._lines, lines)
      end,
    }
  end,
}
