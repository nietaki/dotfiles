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
      local info = debug.getinfo(rhs, 'fnS')
      if info.name then
        description = info.name
      else
        -- split short_src by '/' and take the last part to avoid long paths in description
        local filename = vim.fn.fnamemodify(info.short_src, ':t')
        description = filename .. ":" .. info.linedefined
      end
    end
  end

  local default_opts = { noremap = true, silent = true }
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

-- https://github.com/cacarico/make.nvim/blob/main/lua/make/utils.lua
ntk.parse_makefile = function()
  local fn = vim.fn
  local log = vim.log.levels
  local cwd = vim.loop.cwd() or fn.getcwd()
  local path = cwd .. "/Makefile"
  if fn.filereadable(path) == 0 and fn.has("nvim-0.9") == 1 then
    --- Attempt to find Makefile upward
    local found = vim.fs.find("Makefile", { path = cwd, upward = true })
    path = (found and found[1]) or ""
  end
  if path == "" or fn.filereadable(path) == 0 then
    vim.notify("No Makefile found", log.ERROR)
    return {}
  end

  local lines = fn.readfile(path)
  local seen = {}
  local out = {}

  for _, line in ipairs(lines) do
    local name, _desc = line:match("^([%w%-%_]+)%s*:%s*.-##%s*(.+)$")
    if name and not seen[name] then
      table.insert(out, name)
      seen[name] = true
    elseif not name then
      name = line:match("^([%w%-%_]+)%s*:")
      if name and not seen[name] then
        table.insert(out, name)
        seen[name] = true
      end
    end
  end

  return out
end

ntk.debug = function(sth)
  print(vim.inspect(sth))
end

return ntk
