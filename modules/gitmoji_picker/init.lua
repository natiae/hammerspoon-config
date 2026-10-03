local theme = require('modules.utils.window_theme')
local M = {}
local directory = debug.getinfo(1, 'S').source:sub(2):match('(.*/)')
local columns, pageSize = 8, 40

function M:hide()
  self.active = false
  if self.tap then
    self.tap:stop()
  end
  if self.canvas then
    self.canvas:hide()
  end
end

function M:restoreClipboard()
  if self.clipboardTimer then
    self.clipboardTimer:stop()
    self.clipboardTimer = nil
  end
  if self.savedClipboard and hs.pasteboard.changeCount() == self.clipboardCount then
    hs.pasteboard.writeAllData(self.savedClipboard)
  end
  self.savedClipboard = nil
  self.clipboardCount = nil
end

function M:select(index)
  local item = self.filtered[index or self.selected]
  if not self.active or not item then
    return
  end
  local target = self.target
  self:hide()
  -- The canvas never takes keyboard focus; do not insert into a different window.
  local focused = hs.window.focusedWindow()
  if target and focused and target:id() == focused:id() then
    self:restoreClipboard()
    -- readAllData only preserves one pasteboard item; never discard a multi-item copy.
    if #hs.pasteboard.allContentTypes() > 1 then
      hs.alert.show(
        '클립보드에 여러 항목이 있습니다. 단일 항목을 복사한 뒤 다시 선택해주세요'
      )
      return
    end
    self.savedClipboard = hs.pasteboard.readAllData()
    if
      not hs.pasteboard.setContents((self.output == 'code' and item.code or item.emoji) .. ' ')
    then
      self.savedClipboard = nil
      hs.alert.show('클립보드에 이모지를 복사하지 못했습니다')
      return
    end
    self.clipboardCount = hs.pasteboard.changeCount()
    -- Defer until the selection key event has returned to the application.
    self.pasteTimer = hs.timer.doAfter(0.05, function()
      self.pasteTimer = nil
      local current = hs.window.focusedWindow()
      if current and current:id() == target:id() then
        hs.eventtap.keyStroke({ 'cmd' }, 'v', 0)
        self.clipboardTimer = hs.timer.doAfter(1, function()
          self:restoreClipboard()
        end)
      else
        self:restoreClipboard()
      end
    end)
  else
    hs.alert.show('입력할 창이 바뀌었습니다')
  end
end

function M:position()
  local point = hs.mouse.absolutePosition()
  local ok, bounds = pcall(function()
    local element = hs.axuielement.systemWideElement():attributeValue('AXFocusedUIElement')
    local range = element:attributeValue('AXSelectedTextRange')
    return element:parameterizedAttributeValue('AXBoundsForRange', range)
  end)
  if ok and bounds and bounds.x and bounds.y and (bounds.h or 0) > 0 then
    point = { x = bounds.x, y = bounds.y + bounds.h }
  end
  local screen = hs.screen.find(hs.geometry.point(point)) or hs.mouse.getCurrentScreen()
  local frame = screen:frame()
  local width, height = math.min(520, frame.w - 20), math.min(430, frame.h - 20)
  local y = point.y + 8
  if y + height > frame.y + frame.h then
    y = point.y - height - 8
  end
  return {
    x = math.max(frame.x + 10, math.min(point.x, frame.x + frame.w - width - 10)),
    y = math.max(frame.y + 10, math.min(y, frame.y + frame.h - height - 10)),
    w = width,
    h = height,
  }
end

function M:filter()
  self.filtered = {}
  for _, item in ipairs(self.items) do
    local text = (item.name .. ' ' .. item.code .. ' ' .. item.description):lower()
    local matches = true
    for term in self.query:lower():gmatch('%S+') do
      if not text:find(term, 1, true) then
        matches = false
        break
      end
    end
    if matches then
      table.insert(self.filtered, item)
    end
  end
  self.selected = 1
end

function M:render()
  local width, height = self.frame.w, self.frame.h
  local elements = {}
  local function rect(id, x, y, w, h, color, clickable)
    table.insert(elements, {
      id = id,
      type = 'rectangle',
      action = 'fill',
      fillColor = color,
      roundedRectRadii = { xRadius = 8, yRadius = 8 },
      trackMouseUp = clickable or false,
      frame = { x = x, y = y, w = w, h = h },
    })
  end
  local function text(value, x, y, w, h, size, color)
    table.insert(elements, {
      type = 'text',
      text = value,
      textFont = theme.font,
      textSize = size,
      textColor = color or theme.text,
      textLineBreak = 'truncateTail',
      frame = { x = x, y = y, w = w, h = h },
    })
  end
  rect('background', 0, 0, width, height, theme.background)
  rect('search', 12, 12, width - 24, 38, theme.surface)
  text(
    self.query == '' and 'Gitmoji 검색 · bug, feature, docs…' or self.query .. ' ▏',
    24,
    21,
    width - 48,
    26,
    15,
    self.query == '' and theme.muted or theme.text
  )
  local page = math.floor((self.selected - 1) / pageSize)
  local cellWidth, cellHeight = (width - 24) / columns, (height - 144) / 5
  for slot = 1, pageSize do
    local index = page * pageSize + slot
    local item = self.filtered[index]
    if item then
      local x, y =
        12 + ((slot - 1) % columns) * cellWidth, 62 + math.floor((slot - 1) / columns) * cellHeight
      rect(
        'item' .. index,
        x,
        y,
        cellWidth - 4,
        cellHeight - 4,
        index == self.selected and theme.selected or theme.emptySurface,
        true
      )
      text(item.emoji, x + 10, y + 5, cellWidth - 12, cellHeight - 6, 28)
    end
  end
  local item = self.filtered[self.selected]
  text(
    item and (item.emoji .. ' ' .. item.code) or '검색 결과 없음',
    16,
    height - 76,
    width - 32,
    24,
    15
  )
  text(item and item.description or '', 16, height - 51, width - 32, 22, 12, theme.muted)
  text(
    '방향키 이동 · Enter 삽입 · Esc 닫기',
    16,
    height - 26,
    width - 110,
    20,
    11,
    theme.muted
  )
  text(
    (page + 1) .. '/' .. math.max(1, math.ceil(#self.filtered / pageSize)),
    width - 65,
    height - 26,
    50,
    20,
    11,
    theme.muted
  )
  self.canvas:replaceElements(table.unpack(elements)):show()
end

function M:show()
  if self.pasteTimer then
    return
  end
  if self.active then
    self:hide()
    return
  end
  if hs.eventtap.isSecureInputEnabled() then
    hs.alert.show('보안 입력 중에는 검색할 수 없습니다')
    return
  end
  self.target = hs.window.focusedWindow()
  if not self.target then
    return
  end
  self.frame = self:position()
  self.canvas:frame(self.frame)
  self.query = ''
  self:filter()
  self.active = true
  self:render()
  self.tap:start()
end

function M:stop()
  if self.pasteTimer then
    self.pasteTimer:stop()
    self.pasteTimer = nil
  end
  self:restoreClipboard()
  self:hide()
  if self.hotkey then
    self.hotkey:delete()
    self.hotkey = nil
  end
  if self.canvas then
    self.canvas:delete()
    self.canvas = nil
  end
  self.tap = nil
  return self
end

function M:start(options)
  options = options or {}
  local spec = options.hotkey
  assert(
    type(spec) == 'table'
      and type(spec[1]) == 'table'
      and type(spec[2]) == 'string'
      and hs.keycodes.map[spec[2]:lower()],
    'gitmoji_picker requires hotkey = {{modifiers}, key}'
  )
  assert(
    options.output == nil or options.output == 'emoji' or options.output == 'code',
    'output must be emoji or code'
  )
  self:stop()
  self.output = options.output or 'emoji'
  local file = assert(io.open(directory .. 'gitmojis.json', 'r'))
  local data = file:read('*a')
  file:close()
  self.items = hs.json.decode(data).gitmojis
  self.canvas = hs.canvas
    .new({ x = 0, y = 0, w = 520, h = 430 })
    :level(hs.canvas.windowLevels.overlay)
    :behaviorAsLabels({ 'canJoinAllSpaces', 'stationary' })
    :mouseCallback(function(_, event, id)
      if event == 'mouseUp' and type(id) == 'string' then
        local index = tonumber(id:match('^item(%d+)$'))
        if index then
          self:select(index)
        end
      end
    end)
  self.tap = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.rightMouseDown,
  }, function(event)
    if not self.active then
      return false
    end
    if event:getType() ~= hs.eventtap.event.types.keyDown then
      local p, f = event:location(), self.frame
      if p.x < f.x or p.x > f.x + f.w or p.y < f.y or p.y > f.y + f.h then
        self:hide()
      end
      return false
    end
    local code, flags = event:getKeyCode(), event:getFlags()
    local map = hs.keycodes.map
    if code == map.escape then
      self:hide()
      return true
    end
    if code == map['return'] or code == map.padenter then
      self:select()
      return true
    end
    local steps = {
      [map.left] = -1,
      [map.right] = 1,
      [map.up] = -columns,
      [map.down] = columns,
      [map.pageup] = -pageSize,
      [map.pagedown] = pageSize,
    }
    if steps[code] then
      self.selected = math.max(1, math.min(#self.filtered, self.selected + steps[code]))
    elseif code == map.delete then
      self.query = flags.cmd and '' or self.query:sub(1, -2)
      self:filter()
    elseif flags.cmd or flags.ctrl or flags.alt then
      self:hide()
      return false
    else
      -- Physical US key names keep Gitmoji search usable under a Korean input source.
      local char = map[code]
      if char == 'space' then
        char = ' '
      end
      if char and #char == 1 and char:match('[%w%s%p]') then
        self.query = self.query .. char
        self:filter()
      end
    end
    self:render()
    return true
  end)
  self.hotkey = hs.hotkey.bindSpec(spec, function()
    self:show()
  end)
  return self
end

return M
