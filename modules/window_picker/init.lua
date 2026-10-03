-- Searchable window switching, including windows minimized to the Dock.
local theme = require('modules.utils.window_theme')
local M = {}

function M:choices(minimizedOnly)
  local choices = {}
  self.windows = {}
  for _, window in ipairs(hs.window.allWindows()) do
    local ok, item = pcall(function()
      if not window:isStandard() then
        return nil
      end
      local minimized = window:isMinimized()
      if minimizedOnly and not minimized then
        return nil
      end
      local app = window:application()
      local id = window:id()
      if not app or not id then
        return nil
      end
      self.windows[id] = window
      local state = minimized and '최소화' or (app:isHidden() and '앱 숨김' or '열림')
      return {
        text = window:title() ~= '' and window:title() or '(제목 없는 창)',
        subText = app:name() .. ' · ' .. state,
        image = hs.image.imageFromAppBundle(app:bundleID()),
        windowID = id,
        minimized = minimized,
        appName = app:name(),
      }
    end)
    if ok and item then
      table.insert(choices, item)
    end
  end
  table.sort(choices, function(a, b)
    if a.minimized ~= b.minimized then
      return not a.minimized
    end
    if a.appName ~= b.appName then
      return a.appName < b.appName
    end
    if a.text ~= b.text then
      return a.text < b.text
    end
    return a.windowID < b.windowID
  end)
  return choices
end

function M:select(item)
  if not item then
    return
  end
  local window = self.windows[item.windowID]
  if not window then
    return
  end
  -- Let the overlay finish closing before activating the target.
  if self.focusTimer then
    self.focusTimer:stop()
  end
  self.focusTimer = hs.timer.doAfter(0.1, function()
    local ok = pcall(function()
      local app = window:application()
      if not app then
        return
      end
      if app:isHidden() then
        app:unhide()
      end
      if window:isMinimized() then
        window:unminimize()
      end
      window:focus()
    end)
    if not ok then
      hs.alert.show('창이 닫혔거나 선택할 수 없습니다')
    end
  end)
end

local normalKeys = { 'q', 'w', 'e', 'r', 'a', 's', 'd', 'f', 'z', 'x', 'c', 'v' }
local minimizedKeys = { 'u', 'i', 'o', 'j', 'k', 'l', 'n', ',', '.' }

function M:hide()
  self.active = false
  self.searching = false
  if self.searchTap then
    self.searchTap:stop()
  end
  if self.modal then
    self.modal:exit()
  end
  if self.canvas then
    self.canvas:hide()
  end
end

function M:pageCount()
  return math.max(1, math.ceil(#self.normal / 12), math.ceil(#self.minimized / 9))
end

function M:pick(minimized, index)
  local list = minimized and self.minimized or self.normal
  local limit = minimized and 9 or 12
  local item = list[(self.page - 1) * limit + index]
  if item then
    self:hide()
    self:select(item)
  end
end

function M:render()
  local screen = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  local work = screen:frame()
  local width, height = math.min(1400, work.w - 40), math.min(850, work.h - 40)
  local frame =
    { x = work.x + (work.w - width) / 2, y = work.y + (work.h - height) / 2, w = width, h = height }
  if not self.canvas then
    self.canvas = hs.canvas
      .new(frame)
      :level(hs.canvas.windowLevels.overlay)
      :behaviorAsLabels({ 'canJoinAllSpaces', 'stationary' })
  else
    self.canvas:frame(frame)
  end
  local elements = {}
  local function rect(x, y, w, h, color)
    table.insert(elements, {
      type = 'rectangle',
      action = 'fill',
      fillColor = color,
      roundedRectRadii = { xRadius = theme.radius, yRadius = theme.radius },
      frame = { x = x, y = y, w = w, h = h },
    })
  end
  local function text(value, x, y, w, h, size, color)
    table.insert(elements, {
      type = 'text',
      textFont = theme.font,
      text = value,
      textSize = size,
      textColor = color or theme.text,
      textLineBreak = 'truncateTail',
      frame = { x = x, y = y, w = w, h = h },
    })
  end
  rect(0, 0, width, height, theme.background)
  local pad, gap = 24, 12
  local rightWidth = math.max(230, width * 0.27)
  local leftWidth = width - pad * 3 - rightWidth
  local rightX = pad * 2 + leftWidth
  text('창  ·  ' .. #self.normal, pad, 20, leftWidth, 30, 22)
  text('최소화  ·  ' .. #self.minimized, rightX, 20, rightWidth, 30, 22)
  local query = self.query or ''
  rect(pad, 57, width - pad * 2, 36, theme.surface)
  text(
    (self.searching and '검색 입력: ' or '필터: ')
      .. (query ~= '' and query or '전체 창')
      .. (self.searching and ' ▏' or ''),
    pad + 12,
    64,
    width - pad * 2 - 24,
    24,
    15,
    self.searching and theme.accent or theme.muted
  )
  local contentY, contentHeight = 107, height - 162
  local cellWidth, cellHeight = (leftWidth - gap * 3) / 4, (contentHeight - gap * 2) / 3
  for i, key in ipairs(normalKeys) do
    local item = self.normal[(self.page - 1) * 12 + i]
    local x = pad + ((i - 1) % 4) * (cellWidth + gap)
    local y = contentY + math.floor((i - 1) / 4) * (cellHeight + gap)
    rect(x, y, cellWidth, cellHeight, item and theme.surface or theme.emptySurface)
    text(key:upper(), x + 14, y + 10, 40, 32, 25, item and theme.accent or theme.disabled)
    if item then
      if item.image then
        table.insert(elements, {
          type = 'image',
          image = item.image,
          frame = { x = x + cellWidth - 48, y = y + 12, w = 32, h = 32 },
        })
      end
      text(item.appName, x + 14, y + 52, cellWidth - 28, 26, 17)
      text(
        item.text,
        x + 14,
        y + 84,
        cellWidth - 28,
        math.max(30, cellHeight - 98),
        14,
        theme.muted
      )
    end
  end
  local rowHeight = (contentHeight - gap * 8) / 9
  for i, key in ipairs(minimizedKeys) do
    local item = self.minimized[(self.page - 1) * 9 + i]
    local y = contentY + (i - 1) * (rowHeight + gap)
    rect(rightX, y, rightWidth, rowHeight, item and theme.surface or theme.emptySurface)
    text(
      key:upper(),
      rightX + 12,
      y + math.max(0, (rowHeight - 28) / 2),
      28,
      28,
      22,
      item and theme.accent or theme.disabled
    )
    if item then
      text(
        item.appName .. ' · ' .. item.text,
        rightX + 48,
        y + math.max(0, (rowHeight - 24) / 2),
        rightWidth - 60,
        24,
        14
      )
    end
  end
  text(
    self.searching and '검색어 입력    Enter: 선택 모드    Esc: 검색 취소'
      or '/ 검색    ← → 페이지    Esc 닫기',
    pad,
    height - 38,
    width - 220,
    25,
    14,
    theme.muted
  )
  text(self.page .. ' / ' .. self:pageCount(), width - 120, height - 38, 96, 25, 14, theme.muted)
  self.canvas:replaceElements(table.unpack(elements)):show()
end

function M:filter()
  self.normal, self.minimized = {}, {}
  local query = (self.query or ''):lower()
  for _, item in ipairs(self.items) do
    local haystack = (item.appName .. ' ' .. item.text):lower()
    if haystack:find(query, 1, true) then
      table.insert(item.minimized and self.minimized or self.normal, item)
    end
  end
  self.page = 1
end

function M:finishSearch(cancel)
  if cancel then
    self.query = self.previousQuery
  end
  self.searching = false
  self.searchTap:stop()
  self:filter()
  self:render()
  self.modal:enter()
end

function M:search()
  self.previousQuery = self.query
  self.searching = true
  self.modal:exit()
  self.searchTap:start()
  self:render()
end

function M:show()
  if self.active then
    self:hide()
    return
  end
  self.items = self:choices(false)
  self.query, self.searching = '', false
  self:filter()
  self.active = true
  self:render()
  self.modal:enter()
end

function M:stop()
  self.searching = false
  self:hide()
  if self.canvas then
    self.canvas:delete()
    self.canvas = nil
  end
  if self.modal then
    self.modal:delete()
    self.modal = nil
  end
  if self.allHotkey then
    self.allHotkey:delete()
    self.allHotkey = nil
  end
  if self.focusTimer then
    self.focusTimer:stop()
    self.focusTimer = nil
  end
  self.searchTap = nil
  return self
end

function M:start(options)
  if options then
    assert(type(options) == 'table', 'window_picker options must be a table')
    local spec = options.hotkey
    assert(
      type(spec) == 'table'
        and type(spec[1]) == 'table'
        and type(spec[2]) == 'string'
        and hs.keycodes.map[spec[2]:lower()],
      'hotkey must be {{modifiers}, key}'
    )
    local modifiers = {}
    local valid = {
      cmd = true,
      command = true,
      ctrl = true,
      control = true,
      alt = true,
      option = true,
      shift = true,
    }
    for _, modifier in ipairs(spec[1]) do
      assert(valid[modifier], 'invalid hotkey modifier: ' .. tostring(modifier))
      table.insert(modifiers, modifier)
    end
    local key = spec[2]:lower()
    if #modifiers == 0 then
      local reserved = { 'escape', '/', 'left', 'right' }
      for _, k in ipairs(normalKeys) do
        table.insert(reserved, k)
      end
      for _, k in ipairs(minimizedKeys) do
        table.insert(reserved, k)
      end
      for _, k in ipairs(reserved) do
        assert(hs.keycodes.map[key] ~= hs.keycodes.map[k], 'hotkey conflicts with a picker key')
      end
    end
    if self.modal then
      self:stop()
    end
    self.hotkeySpec = { modifiers, key }
  end
  assert(self.hotkeySpec, 'window_picker.start requires a hotkey option')
  if self.modal then
    return self
  end
  self.searchTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    if not self.searching then
      return false
    end
    local code, flags = event:getKeyCode(), event:getFlags()
    if code == hs.keycodes.map.escape then
      self:finishSearch(true)
      return true
    end
    if code == hs.keycodes.map['return'] or code == hs.keycodes.map.padenter then
      self:finishSearch(false)
      return true
    end
    if code == hs.keycodes.map.delete then
      if flags.cmd then
        self.query = ''
      else
        self.query = self.query:gsub('[%z\1-\127\194-\244][\128-\191]*$', '')
      end
    elseif not flags.cmd and not flags.ctrl and not flags.alt then
      local chars = event:getCharacters()
      if
        chars
        and chars ~= ''
        and not chars:find('[%z\1-\31\127]')
        and code ~= hs.keycodes.map.left
        and code ~= hs.keycodes.map.right
        and code ~= hs.keycodes.map.up
        and code ~= hs.keycodes.map.down
      then
        self.query = self.query .. chars
      end
    end
    self:filter()
    self:render()
    return true
  end)
  self.modal = hs.hotkey.modal.new()
  for i, key in ipairs(normalKeys) do
    local index = i
    self.modal:bind({}, key, function()
      self:pick(false, index)
    end)
  end
  for i, key in ipairs(minimizedKeys) do
    local index = i
    self.modal:bind({}, key, function()
      self:pick(true, index)
    end)
  end
  self.modal:bind({}, 'escape', function()
    self:hide()
  end)
  self.modal:bind({}, '/', function()
    self:search()
  end)
  for key, delta in pairs({ left = -1, right = 1 }) do
    local step = delta
    self.modal:bind({}, key, function()
      self.page = ((self.page - 1 + step) % self:pageCount()) + 1
      self:render()
    end)
  end
  self.allHotkey = hs.hotkey.bindSpec(self.hotkeySpec, function()
    self:show()
  end)
  return self
end

return M
