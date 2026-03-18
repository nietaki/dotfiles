local ntk = {}

ntk.to_table = function(sth)
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
ntk.table_merge = function(...)
  return vim.tbl_deep_extend('force', ...)
end

ntk.map = function(modes, lhs, rhs, description, opts)
  if description == nil then
    if type(rhs) == "string" then
      description = rhs
    end
    if type(rhs) == "function" then
      local info =  debug.getinfo(rhs, 'fnS')
      if info.name then
        description = info.name
      else
        -- split short_src by '/' and take the last part to avoid long paths in description
        local filename = vim.fn.fnamemodify(info.short_src, ':t')
        description = filename .. ":" .. info.linedefined
      end
    end
  end

  local default_opts = {noremap = true, silent = true}
  if description then
    default_opts.desc = description
  end

  modes = ntk.to_table(modes)

  opts = opts or {}
  opts = ntk.table_merge(default_opts, opts)

  -- safely wrap modes in a table if it's not already
  return vim.keymap.set(modes, lhs, rhs, opts)
end

ntk.map_leader = function(modes, suffix, rhs, description, opts)
  return ntk.map(modes, '<Leader>' .. suffix, rhs, description, opts)
end

return ntk
