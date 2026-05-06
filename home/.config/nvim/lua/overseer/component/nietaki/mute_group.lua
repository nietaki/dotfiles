-- local ntk = require("ntk_utils")

---@type overseer.ComponentFileDefinition
return {
  desc = "disposes of old tasks in the same group when a new task is started",
  params = {},
  -- Define parameters that can be passed in to the component
  -- Optional, default true. Set to false to disallow editing this component in the task editor
  editable = false,
  -- Optional, default true. When false, don't serialize this component when saving a task to disk
  serializable = true,
  -- The params passed in will match the params defined above
  constructor = function(_)
    -- You may optionally define any of the methods below
    return {
      ---@return nil|boolean
      on_pre_start = function(_, task)
        local group_name = task.metadata['mute_group']

        if group_name == nil then
          return true
        end

        local overseer = require("overseer")
        local conflicting_tasks = overseer.list_tasks({
          filter = function(t)
            return t.metadata['mute_group'] == group_name and t.status ~= "PENDING"
          end
        })

        for _, t in ipairs(conflicting_tasks) do
          -- print('disposing of task ' .. t.name .. ' in group ' .. group_name)
          if t:is_running() then
            t:stop()
          end
          t:dispose()
        end
        return true
      end,
      on_dispose = function(self, task)
      end,
    }
  end,
}
