local km = {}

local ntk = require('ntk_utils')

function km.setup()
  ntk.map('n', 'S', '"_diwP', 'replace word with yanked text')
end

return km
