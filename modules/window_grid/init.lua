-- Each corner is selected with two keys from a configurable rectangular matrix.
local windowGeometry = require('modules.utils.mac_window_geometry')
local theme = require('modules.utils.window_theme')
local M = { canvases = {} }

function M:configure(options)
  assert(type(options) == 'table', 'window_grid requires keys and hotkey options')
  local matrix = options.keys
  assert(type(matrix) == 'table' and #matrix > 0, 'keys must be a non-empty matrix')
  assert(type(matrix[1]) == 'table' and #matrix[1] > 0, 'keys must contain non-empty rows')
  local columns, keys, seen = #matrix[1], {}, {}
  local reserved = {}
  for _, key in ipairs({ 'escape', 'delete', 'left', 'right', 'up', 'down' }) do
    reserved[hs.keycodes.map[key]] = true
  end
  for _, row in ipairs(matrix) do
    assert(type(row) == 'table' and #row == columns, 'key rows must have equal lengths')
    for _, key in ipairs(row) do
      assert(type(key) == 'string' and key ~= '', 'each key must be a key name')
      key = key:lower()
      local code = hs.keycodes.map[key]
      assert(type(code) == 'number', 'unknown key: ' .. key)
      assert(not reserved[code], 'reserved navigation key: ' .. key)
      assert(not seen[code], 'duplicate key: ' .. key)
      seen[code] = true
      table.insert(keys, key)
    end
  end
  local hotkey = options.hotkey
  assert(
    type(hotkey) == 'table'
      and type(hotkey[1]) == 'table'
      and type(hotkey[2]) == 'string'
      and hs.keycodes.map[hotkey[2]:lower()],
    'hotkey must be {{modifiers}, key}'
  )
  local validMods = {
    cmd = true,
    command = true,
    ctrl = true,
    control = true,
    alt = true,
    option = true,
    shift = true,
  }
  local modifiers = {}
  for _, modifier in ipairs(hotkey[1]) do
    assert(validMods[modifier], 'invalid hotkey modifier: ' .. tostring(modifier))
    table.insert(modifiers, modifier)
  end
  assert(
    #modifiers > 0 or not seen[hs.keycodes.map[hotkey[2]:lower()]],
    'unmodified hotkey conflicts with a grid key'
  )
  local margins = windowGeometry.normalizeMargins(options.margins)
  -- Validate everything before replacing an active configuration.
  if self.modal then
    self:stop()
  end
  self.margins = margins
  self.keys, self.rows, self.columns = keys, #matrix, columns
  self.hotkeySpec = { modifiers, hotkey[2]:lower() }
  return self
end

function M:cell(index)
  return (index - 1) % self.columns, math.floor((index - 1) / self.columns)
end

function M:corner(outer, inner)
  local x, y = self:cell(outer)
  local sx, sy = self:cell(inner)
  return x * self.columns + sx, y * self.rows + sy
end

function M:selection(frame, input)
  local x1, y1 = self:corner(input[1], input[2])
  local x2, y2 = self:corner(input[3], input[4])
  return {
    x = frame.x + math.min(x1, x2) * frame.w / self.columns ^ 2,
    y = frame.y + math.min(y1, y2) * frame.h / self.rows ^ 2,
    w = (math.abs(x2 - x1) + 1) * frame.w / self.columns ^ 2,
    h = (math.abs(y2 - y1) + 1) * frame.h / self.rows ^ 2,
  }
end

function M:hide()
  for _, canvas in pairs(self.canvases) do
    canvas:hide()
  end
  self.active = false
  if self.highlight then
    self.highlight:hide()
  end
  self.targetLabel = nil
  if self.modal then
    self.modal:exit()
  end
  self.window = nil
end

function M:draw(screen, input)
  local canvas = self.canvases[screen:id()]
  if not canvas then
    return
  end
  local frame = windowGeometry.get(screen, self.margins).placementFrame
  canvas:frame(frame)
  local elements = {
    {
      type = 'rectangle',
      action = 'fill',
      fillColor = theme.overlay,
      frame = { x = 0, y = 0, w = frame.w, h = frame.h },
    },
  }
  local outer = (#input == 1 and input[1]) or (#input == 3 and input[3])
  local bx, by, width, height = 0, 0, frame.w, frame.h
  if #input >= 2 then
    local x, y = self:corner(input[1], input[2])
    table.insert(elements, {
      type = 'rectangle',
      action = 'fill',
      fillColor = theme.selected,
      frame = {
        x = x * frame.w / self.columns ^ 2,
        y = y * frame.h / self.rows ^ 2,
        w = frame.w / self.columns ^ 2,
        h = frame.h / self.rows ^ 2,
      },
    })
  end
  if outer then
    local x, y = self:cell(outer)
    width, height = frame.w / self.columns, frame.h / self.rows
    bx, by = x * width, y * height
  end
  for i, key in ipairs(self.keys) do
    local x, y = self:cell(i)
    local f = {
      x = bx + x * width / self.columns,
      y = by + y * height / self.rows,
      w = width / self.columns,
      h = height / self.rows,
    }
    table.insert(elements, {
      type = 'rectangle',
      action = 'stroke',
      strokeColor = theme.gridLine,
      strokeWidth = 1,
      frame = f,
    })
    local size = math.min(64, f.h / 2.3, f.w / math.max(2, #key))
    table.insert(elements, {
      type = 'text',
      textFont = theme.font,
      text = key:upper(),
      textSize = size,
      textAlignment = 'center',
      textColor = theme.accent,
      frame = {
        x = f.x,
        y = f.y + (f.h - size * 1.3) / 2,
        w = f.w,
        h = size * 1.5,
      },
    })
  end
  if self.targetLabel then
    local bannerWidth = math.min(760, frame.w - 32)
    table.insert(elements, {
      type = 'rectangle',
      action = 'fill',
      fillColor = theme.background,
      roundedRectRadii = { xRadius = theme.radius, yRadius = theme.radius },
      frame = { x = (frame.w - bannerWidth) / 2, y = 36, w = bannerWidth, h = 40 },
    })
    table.insert(elements, {
      type = 'text',
      textFont = theme.font,
      text = self.targetLabel,
      textSize = 19,
      textAlignment = 'center',
      textLineBreak = 'truncateTail',
      textColor = theme.target,
      frame = { x = (frame.w - bannerWidth) / 2 + 12, y = 43, w = bannerWidth - 24, h = 28 },
    })
  end
  local labels = { 'Start: region', 'Start: cell', 'End: region', 'End: cell' }
  table.insert(elements, {
    type = 'text',
    textFont = theme.font,
    text = labels[#input + 1] .. '   |   Esc: cancel   Delete: back   Arrows: screen',
    textSize = 14,
    textAlignment = 'center',
    textColor = theme.muted,
    frame = { x = 0, y = 8, w = frame.w, h = 26 },
  })
  canvas:replaceElements(table.unpack(elements))
end

function M:rebuild()
  self:hide()
  for _, canvas in pairs(self.canvases) do
    canvas:delete()
  end
  self.canvases = {}
  for _, screen in ipairs(hs.screen.allScreens()) do
    self.canvases[screen:id()] = hs.canvas
      .new(windowGeometry.get(screen, self.margins).placementFrame)
      :level(hs.canvas.windowLevels.overlay)
      :behaviorAsLabels({ 'canJoinAllSpaces', 'stationary' })
    self:draw(screen, {})
  end
  self.dirty = false
end

function M:show()
  if self.active then
    self:hide()
    return
  end
  if self.dirty then
    self:rebuild()
  end
  local window = hs.window.focusedWindow()
  if not window or not window:isStandard() then
    return
  end
  if window:isFullScreen() then
    hs.alert.show('Exit full screen before using the grid')
    return
  end
  self.window, self.screen, self.input = window, window:screen(), {}
  if not self.screen or not self.canvases[self.screen:id()] then
    return
  end
  local app = window:application()
  self.targetLabel = '배치할 창: ' .. (app and app:name() or '') .. ' — ' .. window:title()
  local targetFrame = window:frame()
  if not self.highlight then
    self.highlight = hs.canvas
      .new(targetFrame)
      :level(hs.canvas.windowLevels.overlay - 1)
      :behaviorAsLabels({ 'canJoinAllSpaces', 'stationary' })
  else
    self.highlight:frame(targetFrame)
  end
  self.highlight
    :replaceElements({
      type = 'rectangle',
      action = 'strokeAndFill',
      fillColor = theme.targetFill,
      strokeColor = theme.target,
      strokeWidth = 8,
      frame = {
        x = 4,
        y = 4,
        w = math.max(0, targetFrame.w - 8),
        h = math.max(0, targetFrame.h - 8),
      },
    })
    :show()
  self:draw(self.screen, self.input)
  self.active = true
  self.canvases[self.screen:id()]:show()
  self.modal:enter()
end

function M:press(index)
  if not self.active then
    return
  end
  table.insert(self.input, index)
  if #self.input == 4 then
    local window = self.window
    local frame =
      self:selection(windowGeometry.get(self.screen, self.margins).placementFrame, self.input)
    self:hide()
    window:setFrame(frame, 0)
  else
    self:draw(self.screen, self.input)
  end
end

function M:stop()
  self:hide()
  if self.unsubscribeGeometry then
    self.unsubscribeGeometry()
    self.unsubscribeGeometry = nil
  end
  if self.spacesWatcher then
    self.spacesWatcher:stop()
    self.spacesWatcher = nil
  end
  if self.hotkey then
    self.hotkey:delete()
    self.hotkey = nil
  end
  if self.modal then
    self.modal:delete()
    self.modal = nil
  end
  if self.highlight then
    self.highlight:delete()
    self.highlight = nil
  end
  for _, canvas in pairs(self.canvases) do
    canvas:delete()
  end
  self.canvases = {}
  return self
end

function M:start(options)
  if options then
    self:configure(options)
  end
  if self.modal then
    return self
  end
  assert(self.keys and self.hotkeySpec, 'configure window_grid before starting')
  self.modal = hs.hotkey.modal.new()
  for index, key in ipairs(self.keys) do
    local selected = index
    self.modal:bind({}, key, function()
      self:press(selected)
    end)
  end
  self.modal:bind({}, 'escape', function()
    self:hide()
  end)
  self.modal:bind({}, 'delete', function()
    table.remove(self.input)
    self:draw(self.screen, self.input)
  end)
  for key, method in pairs({ left = 'toWest', right = 'toEast', up = 'toNorth', down = 'toSouth' }) do
    local direction = method
    self.modal:bind({}, key, function()
      local nextScreen = self.screen[direction](self.screen)
      if nextScreen and self.canvases[nextScreen:id()] then
        self.canvases[self.screen:id()]:hide()
        self.screen, self.input = nextScreen, {}
        self:draw(self.screen, self.input)
        self.canvases[self.screen:id()]:show()
      end
    end)
  end
  self.hotkey = hs.hotkey.bindSpec(self.hotkeySpec, function()
    self:show()
  end)
  self.unsubscribeGeometry = windowGeometry.subscribe(function(phase)
    if phase == 'changing' then
      self.dirty = true
      self:hide()
    else
      self:rebuild()
    end
  end)
  self.spacesWatcher = hs.spaces.watcher
    .new(function()
      self:hide()
    end)
    :start()
  self:rebuild()
  return self
end

return M
