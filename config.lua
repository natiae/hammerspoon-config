------------------------------
-- start SpoonInstall CONFIG
------------------------------
hs.loadSpoon('SpoonInstall')

------------------------------
-- start AppLauncher CONFIG
------------------------------
spoon.SpoonInstall:andUse('AppLauncher', {
  config = {
    modifiers = { 'ctrl', 'option', 'shift' },
  },
  hotkeys = {
    d = 'Discord',
    t = 'Telegram',
    z = 'Zen',
    s = 'Slack',
    m = 'Mail',
    k = 'Kitty',
    v = 'VSCodium',
  },
})

------------------------------
-- start MouseFollowsFocus CONFIG
------------------------------
spoon.SpoonInstall:andUse('MouseFollowsFocus', {
  start = true,
})

------------------------------
-- start custom modules
------------------------------

-- Standalone two-depth window grid; independent of SpoonInstall.
require('modules.window_grid'):start({
  keys = {
    { 'q', 'w', 'e' },
    { 'a', 's', 'd' },
    { 'z', 'x', 'c' },
  },
  hotkey = { { 'ctrl', 'option', 'shift' }, 'g' },
  margins = { top = 'auto', left = 6, right = 6, bottom = 6 },
})
require('modules.inputsource_aurora'):start({
  color = { 12, 79, 135 },
  alpha = 0.4,
  border = { top = 'auto', left = 6, right = 6, bottom = 6 },
})
require('modules.esc_convert_to_eng'):start()

require('modules.window_picker'):start({
  hotkey = { { 'cmd', 'ctrl' }, 'up' },
})
