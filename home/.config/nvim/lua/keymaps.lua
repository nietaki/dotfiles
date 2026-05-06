local km = {}

local ntk = require('ntk_utils')

local function key_files_keymaps()
  ntk.map('n', '<Leader>fr', ':checktime<CR>')
  ntk.map('n', '<Leader>fh', ':e %:p:s,.hpp$,.X123X,:s,.cpp$,.hpp,:s,.X123X$,.cpp,<CR>')
  ntk.map('n', '<Leader>fR', ':e!<CR>', 'reload current file from disk')
  ntk.map('n', '<Leader>fed', ':e ~/.config/nvim/init.lua<CR>')
  ntk.map('n', '<Leader>feD', ':tabnew ~/.homesick/repos/dotfiles/README.md<CR>:tcd %:p:h<CR>',
    'open dotfiles in new tab')
  ntk.map('n', '<Leader>feP', ':tabnew ~/puter/README.md<CR>:tcd %:p:h<CR>', 'open puter in new tab')
  ntk.map('n', '<Leader>fev', ':e ~/.vimrc<CR>')
  ntk.map('n', '<Leader>fez', ':e ~/.zshrc<CR>')
  -- todo an implementatfon that actually works, this will only work on experimental stuff
  ntk.map('n', '<Leader>fer', ':so ~/.config/nvim/init.lua<CR>', 'reload vim config')
end

local function project()
  ntk.map('n', '<Leader>ps', ':wa<CR>', 'Save all')
  -- TODO change the keymap to something more intuitive
  ntk.map('n', '<Leader>ph', ':CloseHiddenBuffers<CR>', 'close hidden buffers')
  ntk.map('n', '<Leader>pr', ':pwd<CR>', 'show project root')
  ntk.map('n', '<Leader>pR', ':tcd %:p:h<CR>', 'SET project root')
end

local function toggle_tab()
  -- toggle
  ntk.map('n', '<Leader>tw', ':ToggleWorkspace<CR>')

  --tab
  ntk.map('n', '<Leader>tt', ':tabnew<CR>')
  ntk.map('n', '<Leader>te', ':tabedit')
  ntk.map('n', '<Leader>tl', ':tabnext<CR>')
  ntk.map('n', '<Leader>th', ':tabprevious<CR>')
  ntk.map('n', '<Leader>tp', ':tabprevious<CR>')
  ntk.map('n', '<Leader>tN', ':tabprevious<CR>')
  ntk.map('n', '<Leader>tn', ':tabnext<CR>')
  ntk.map('n', '<Leader>td', ':tabclose<CR>')
  ntk.map('n', '<Leader>tc', ':tabclose<CR>')
  ntk.map('n', '<Leader>t1', ':1tabnext<CR>')
  ntk.map('n', '<Leader>t2', ':2tabnext<CR>')
  ntk.map('n', '<Leader>t3', ':3tabnext<CR>')
  ntk.map('n', '<Leader>t4', ':4tabnext<CR>')
  ntk.map('n', '<Leader>t5', ':5tabnext<CR>')
  ntk.map('n', '<Leader>t6', ':6tabnext<CR>')
end

local function get_current_context()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  -- [1]=line, [2]=col
  -- get relative path for the current buffer
  local relative_path = vim.fn.expand("%:~:.")
  return relative_path, cursor_pos
end

local copy_to_clipboard = function(text)
  vim.fn.setreg('+', text)
end

local explain_line_command = function()
  local relative_path, cursor_pos = get_current_context()
  copy_to_clipboard("/explain_line " .. relative_path .. " " .. cursor_pos[1])
  vim.notify("Copied /explain_line command to clipboard")
end

local fix_command = function()
  local relative_path, cursor_pos = get_current_context()
  copy_to_clipboard("/fix " .. relative_path .. " " .. cursor_pos[1])
  vim.notify("Copied /fix command to clipboard")
end

local continue_command = function()
  local relative_path, cursor_pos = get_current_context()
  copy_to_clipboard("/continue " .. relative_path .. " " .. cursor_pos[1] .. " " .. cursor_pos[2])
  vim.notify("Copied /continue command to clipboard")
end

local function open_code_commands()
  ntk.map('n', '<Leader>oe', explain_line_command, 'copy /explain_line command')
  ntk.map('n', '<Leader>of', fix_command, 'copy /fix command')
  ntk.map('n', '<Leader>oc', continue_command, 'copy /continue command')
end

local function buffers_and_windows()
  vim.g.windowswap_map_keys = 0 -- prevent default bindings

  -- buffers
  ntk.map('n', '<Leader>bb', ':b#<CR>', 'switch to last buffer')
  ntk.map('n', '<Leader>bn', ':bn<CR>')
  ntk.map('n', '<Leader>bp', ':bp<CR>')
  ntk.map('n', '<Leader>bd', ':bp|:bd #<CR>', 'close currently open buffer')
  ntk.map('n', '<Leader>bh', ':CtrlPMRUFiles<CR>', 'FZF in recent buffers')
  ntk.map('n', '<Leader>b/', ':BLines<CR>', 'FZF in current Buffer')
  ntk.map('n', '<Leader><Tab>', ':b#<CR>', 'switch between last two buffers')

  -- windows
  ntk.map('n', '<Leader>wd', ':hide<CR>', 'quit current window')
  ntk.map('n', '<Leader>ws', ':call WindowSwap#EasyWindowSwap()<CR>', 'easy WindowSwap')
  ntk.map('n', '<Leader>wl', '<C-W><C-L>', 'go one window right')
  ntk.map('n', '<Leader>wj', '<C-W><C-J>', 'go one window down')
  ntk.map('n', '<Leader>wk', '<C-W><C-K>', 'go one window up')
  ntk.map('n', '<Leader>wh', '<C-W><C-H>', 'go one window left')
  ntk.map('n', '<Leader>wn', '<C-W><C-W>', 'go to Next window')
  ntk.map('n', '<Leader>wo', '<C-W><C-O>', 'make this the Only window')
  ntk.map('n', '<Leader>ww', '<C-W><C-P>', 'toggle to previous window')
  ntk.map('n', '<Leader>wL', '<C-W><C-B>', 'go to bottom-right window')
  ntk.map('n', '<Leader>wH', '<C-W><C-T>', 'go to top-left window')
  ntk.map('n', '<Leader>wm', [[<C-W>_<C-W>|]], 'Maximize!')
  ntk.map('n', '<Leader>w=', '<C-W>=', 'distribute windows equally')
  ntk.map('n', '<Leader>w>', ':vertical resize +10<CR>', 'make wider')
  ntk.map('n', '<Leader>w<', ':vertical resize -10<CR>', 'make narrower')
  ntk.map('n', '<Leader>w/', ':vsp<CR>')
  ntk.map('n', '<Leader>w-', ':sp<CR>')
  ntk.map('n', '<Leader>wf', '<C-w>F', 'open file:line under curson in new window')
end

local function strudel_keymaps()
  local strudel = require("strudel")
  vim.keymap.set("n", "<leader>dl", strudel.launch, { desc = "Launch Strudel" })
  vim.keymap.set("n", "<leader>dq", strudel.quit, { desc = "Quit Strudel" })
  vim.keymap.set("n", "<leader>dt", strudel.toggle, { desc = "Strudel Toggle Play/Stop" })
  vim.keymap.set("n", "<leader>du", strudel.update, { desc = "Strudel Update" })
  vim.keymap.set("n", "<leader>ds", strudel.stop, { desc = "Strudel Stop Playback" })
  vim.keymap.set("n", "<leader>db", strudel.set_buffer, { desc = "Strudel set current buffer" })
  vim.keymap.set("n", "<leader>dx", strudel.execute, { desc = "Strudel set current buffer and update" })
end

local function overseer_keymaps()
  -- 'm' as in 'make'
  ntk.map('n', '<Leader>mr', ':OverseerRun<CR>', 'run Overseer task')
  ntk.map('n', '<Leader>mf', ':w<CR>:OverseerRun fixme<CR>', 'opencode fix(me)')
  ntk.map('n', '<Leader>ml', ':OverseerToggle<CR>', 'toggle (executed) task list')
  ntk.map('n', '<Leader>mL', ':OverseerToggle!<CR>', 'toggle task list, don\'t move cursor')
end

local quickfix_keymaps = function()
  ntk.map('n', '<Leader>co', ':copen 24<CR>', 'quickifx open')
  ntk.map('n', '<Leader>cc', ':cclose<CR>', 'quickifx close')
  ntk.map('n', '<Leader>cd', ':cclose<CR>', 'quickifx close')
end

local copilot_lua_keymaps = function()
  -- local cp = require("copilot.panel")
  ntk.map('n', ',cs', ':Copilot status<CR>')
  ntk.map('n', ',ce', ':Copilot enable<CR>')
  ntk.map('n', ',cd', ':Copilot disable<CR>')
  -- ntk.map('n', ',cc', ':Copilot panel toggle<CR>')
end

local neotest_keymaps = function()
  ntk.map('n', ',tt', ':lua require("neotest").run.run()<CR>', 'run test under cursor')
  ntk.map('n', ',tl', ':lua require("neotest").run.run_last()<CR>', 'run last test')
  ntk.map('n', ',tf', ':lua require("neotest").run.run(vim.fn.expand("%"))<CR>', 'run all tests in current file')
  ntk.map('n', ',ta', ':lua require("neotest").run.run("./")<CR>', 'run all tests')
  ntk.map('n', ',ts', ':lua require("neotest").summary.toggle()<CR>', 'toggle test summary')
end

local others = function()
  ntk.map('n', '<Leader>qq', ':qa<CR>', 'Quit!')
end

-- note: the "categories" are set up in mini_setup.lua, in the miniclue config

function km.setup()
  ntk.map('n', 'S', '"_diwP', 'replace word with yanked text')
  key_files_keymaps()
  buffers_and_windows()
  project()
  toggle_tab()
  --open_code()
  strudel_keymaps()
  overseer_keymaps()
  quickfix_keymaps()
  copilot_lua_keymaps()
  neotest_keymaps()
  open_code_commands()
  others()
end

return km
