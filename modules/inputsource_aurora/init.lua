local windowGeometry = require('modules.utils.mac_window_geometry')
local M = { boxes = {} }

function M:clear()
  for _, box in ipairs(self.boxes) do
    box:delete()
  end
  self.boxes = {}
end

function M:refresh()
  self:clear()
  if hs.keycodes.currentSourceID() == 'com.apple.keylayout.ABC' then
    return
  end
  for _, screen in ipairs(hs.screen.allScreens()) do
    for _, edge in ipairs(windowGeometry.get(screen, self.border).borders) do
      if edge.w > 0 and edge.h > 0 then
        local box = hs.drawing.rectangle(hs.geometry.rect(0, 0, 0, 0))
        box
          :setFillColor(self.color)
          :setFill(true)
          :setAlpha(self.alpha)
          :setLevel(hs.drawing.windowLevels.overlay)
          :setStroke(false)
          :setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
        box:setSize(hs.geometry.size(edge.w, edge.h)):show()
        box:setTopLeft(hs.geometry.point(edge.x, edge.y))
        table.insert(self.boxes, box)
      end
    end
  end
end

function M:configure(options)
  assert(type(options) == 'table', 'Aurora requires color, alpha and border options')
  local color = options.color
  assert(type(color) == 'table' and #color == 3, 'color must be {red, green, blue} in 0..255')
  for _, value in ipairs(color) do
    assert(
      type(value) == 'number' and value >= 0 and value <= 255,
      'color channels must be in 0..255'
    )
  end
  local alpha = options.alpha
  assert(type(alpha) == 'number' and alpha >= 0 and alpha <= 1, 'alpha must be in 0..1')
  local border = windowGeometry.normalizeMargins(options.border)
  self.color = { red = color[1] / 255, green = color[2] / 255, blue = color[3] / 255 }
  self.alpha, self.border = alpha, border
  if self.started then
    self:refresh()
  end
  return self
end

function M:start(options)
  if options then
    self:configure(options)
  end
  if self.started then
    return self
  end
  assert(self.color, 'configure Aurora before starting')
  self.unsubscribeGeometry = windowGeometry.subscribe(function(phase)
    if phase == 'changing' then
      self:clear()
    else
      self:refresh()
    end
  end)
  hs.keycodes.inputSourceChanged(function()
    self:refresh()
  end)
  self.started = true
  self:refresh()
  return self
end

function M:stop()
  if self.unsubscribeGeometry then
    self.unsubscribeGeometry()
    self.unsubscribeGeometry = nil
  end
  if self.started then
    hs.keycodes.inputSourceChanged(nil)
  end
  self.started = false
  self:clear()
  return self
end

return M
