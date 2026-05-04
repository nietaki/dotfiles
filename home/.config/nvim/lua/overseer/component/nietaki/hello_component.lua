---@type overseer.ComponentFileDefinition
local overseer = require("overseer")
local ntk = require("ntk_utils")
return {
  desc = "test component, please ignore",
  -- Define parameters that can be passed in to the component
  params = {
    foo = {
      type = "string",
      default = "default_val"
    }
    -- See :help overseer-params
  },
  -- Optional, default true. Set to false to disallow editing this component in the task editor
  editable = false,
  -- Optional, default true. When false, don't serialize this component when saving a task to disk
  serializable = true,
  -- The params passed in will match the params defined above
  constructor = function(params)
    -- You may optionally define any of the methods below
    ntk.debug(params)
    return {
      on_init = function(self, task)
        -- Called when the task is created
        -- This is a good place to initialize resources, if needed
      end,
      ---@return nil|boolean
      on_pre_start = function(self, task)
        -- Return false to prevent task from starting
        -- print('on pre start')
        -- ntk.debug(self)
        -- ntk.debug(task)
        return true
      end,
      on_start = function(self, task)
        -- Called when the task is started
      end,
      on_reset = function(self, task)
        -- Called when the task is reset to run again
      end,
      ---@return table
      on_pre_result = function(self, task)
        -- Called when the task is finalizing.
        -- Return a map-like table value here to merge it into the task result.
        return { foo = { "bar", "baz" } }
      end,
      ---@param result table A result table.
      on_preprocess_result = function(self, task, result)
        -- Called right before on_result. Intended for logic that needs to preprocess the result table and update it in-place.
      end,
      ---@param result table A result table.
      on_result = function(self, task, result)
        -- Called when a component has results to set. Usually this is after the command has completed, but certain types of tasks may wish to set a result while still running.
      end,
      ---@param status overseer.Status Can be CANCELED, FAILURE, or SUCCESS
      ---@param result table A result table.
      on_complete = function(self, task, status, result)
        -- Called when the task has reached a completed state.
      end,
      ---@param status overseer.Status
      on_status = function(self, task, status)
        -- Called when the task status changes
      end,
      ---@param data string[] Output of process. See :help channel-lines
      on_output = function(self, task, data)
        -- Called when there is output from the task
      end,
      ---@param lines string[] Completed lines of output, with ansi codes removed.
      on_output_lines = function(self, task, lines)
        -- Called when there is output from the task
        -- Usually easier to deal with than using on_output directly.
      end,
      ---@param code number The process exit code
      on_exit = function(self, task, code)
        -- Called when the task command has completed
      end,
      on_dispose = function(self, task)
        -- Called when the task is disposed
        -- Will be called IFF on_init was called, and will be called exactly once.
        -- This is a good place to free resources (e.g. timers, files, etc)
      end,
    }
  end,
}
