-- Run from the repository root with lua or luajit.
package.path = './?.lua;./?/init.lua;' .. package.path
local map = { escape = 100, delete = 101, left = 102, right = 103, up = 104, down = 105 }
for i = 1, 26 do
  map[string.char(96 + i)] = i
end
hs = { keycodes = { map = map } }
local grid = require('modules.window_grid')
local hotkey = { { 'ctrl', 'shift' }, 'g' }
local function configure(keys)
  grid:configure({ keys = keys, hotkey = hotkey })
end
for _, keys in ipairs({
  { { 'q', 'w', 'e' }, { 'a', 's', 'd' } },
  { { 'q', 'w' }, { 'a', 's' }, { 'z', 'x' } },
  { { 'q' } },
  { { 'q', 'w', 'e' }, { 'a', 's', 'd' }, { 'z', 'x', 'c' } },
}) do
  configure(keys)
  local count = #grid.keys
  local columns, rows = grid.columns ^ 2, grid.rows ^ 2
  local seen = {}
  for a = 1, count do
    for b = 1, count do
      local x, y = grid:corner(a, b)
      assert(x >= 0 and x < columns and y >= 0 and y < rows)
      assert(not seen[x .. ',' .. y])
      seen[x .. ',' .. y] = true
      for c = 1, count do
        for d = 1, count do
          local f = grid:selection(
            { x = -100, y = 50, w = columns * 100, h = rows * 100 },
            { a, b, c, d }
          )
          assert(f.x >= -100 and f.y >= 50 and f.w >= 100 and f.h >= 100)
          assert(f.x + f.w <= -100 + columns * 100 and f.y + f.h <= 50 + rows * 100)
        end
      end
    end
  end
end
local f = grid:selection({ x = 0, y = 0, w = 900, h = 900 }, { 1, 1, 8, 8 })
assert(f.x == 0 and f.y == 0 and f.w == 500 and f.h == 900)
for _, bad in ipairs({
  {},
  { { 'q' }, { 'w', 'e' } },
  { { 'q', 'Q' } },
  { { 'escape' } },
  {
    { 'not-a-key' },
  },
}) do
  assert(not pcall(configure, bad))
  assert(grid.rows == 3 and grid.columns == 3) -- invalid configs leave existing state intact
end
assert(not pcall(function()
  grid:configure({ keys = { { 'q' } }, hotkey = { { 'invalid' }, 'g' } })
end))
print(
  'Passed: rectangular and square matrices, all corner pairs, reversed selections, validation, legacy qqxx'
)
