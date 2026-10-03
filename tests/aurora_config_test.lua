package.path = './?.lua;./?/init.lua;' .. package.path
local geometry = require('modules.utils.mac_window_geometry')
local aurora = require('modules.inputsource_aurora')
local screen = {
  fullFrame = function()
    return { x = 0, y = 0, w = 1000, h = 800 }
  end,
  frame = function()
    return { x = 0, y = 24, w = 1000, h = 776 }
  end,
}
local gridMargins = { top = 'auto', left = 6, right = 6, bottom = 6 }
local before = geometry.get(screen, gridMargins).placementFrame
local options = {
  color = { 12, 79, 135 },
  alpha = 0.4,
  border = {
    top = 'auto',
    left = 12,
    right = 12,
    bottom = 8,
  },
}
aurora:configure(options)
assert(geometry.get(screen, aurora.border).insets.top == 24)
options.border.left = 99
options.color[1] = 255
assert(aurora.border.left == 12 and aurora.color.red == 12 / 255)
aurora:configure({ color = { 1, 2, 3 }, alpha = 0, border = { top = 10, left = 20 } })
local after = geometry.get(screen, gridMargins).placementFrame
for k, v in pairs(before) do
  assert(after[k] == v)
end
assert(geometry.get(screen, aurora.border).insets.top == 10)
assert(geometry.get(screen).placementFrame.x == 0)
local hidden = { fullFrame = screen.fullFrame, frame = screen.fullFrame }
assert(geometry.get(hidden, { top = 'auto' }).insets.top == 28)
assert(geometry.get(hidden, { top = 'auto', autoTopFallback = 0 }).insets.top == 0)
assert(not pcall(function()
  aurora:configure({ color = { 256, 0, 0 }, alpha = 0.4 })
end))
assert(not pcall(function()
  aurora:configure({ color = { 1, 2, 3 }, alpha = 2 })
end))
assert(not pcall(function()
  geometry.normalizeMargins({ left = 'auto' })
end))
for _, n in ipairs({ 'inputsource_aurora', 'mac_window_geometry', 'window_grid' }) do
  local path = n == 'mac_window_geometry' and 'modules/utils/' .. n .. '.lua'
    or 'modules/' .. n .. '/init.lua'
  assert(loadfile(path))
end
assert(loadfile('init.lua'))
print(
  'Passed: independent margins, auto/fixed top, fallback, defensive copies, input validation, syntax'
)
