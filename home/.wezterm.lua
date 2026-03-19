local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.font_size = 14
config.color_scheme = 'Srcery (Gogh)'
config.font = wezterm.font(
  'Hack Nerd Font Mono',
  {weight = 'Regular', stretch = 'SemiExpanded'}
)
config.bold_brightens_ansi_colors = true

config.initial_cols = 180
config.initial_rows = 60
config.freetype_load_target = 'Light'
config.freetype_render_target = 'HorizontalLcd'
config.line_height = 1.2

return config
