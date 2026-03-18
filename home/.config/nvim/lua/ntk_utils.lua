local to_table = function(sth)
  if type(sth) == 'table' then
    return sth
  end
  if sth == nil then
    return {}
  else
    return { sth }
  end
end

--- Merges multiple tables into one, with later tables overriding earlier ones.
local table_merge = function(...)
  return vim.tbl_deep_extend('force', ...)
end


local map = function(modes, lhs, rhs, description, opts)
  modes = to_table(modes)
  local default_opts = {desc = description, noremap = true, silent = true}
  opts = opts or {}
  opts = table_merge(default_opts, opts)

  -- safely wrap modes in a table if it's not already
  return vim.keymap.set(modes, lhs, rhs, opts)
end

local map_leader = function(modes, suffix, rhs, description, opts)
  return map(modes, '<Leader>' .. suffix, rhs, description, opts)
end

return {
  map = map,
  map_leader = map_leader,
  table_merge = table_merge,
  to_table = to_table,
}
