-- Kept independent of the theme so configuration/theme errors can still be shown.
local M = {}

function M.show(message, failed)
  if M.timer then
    M.timer:stop()
  end
  if M.canvas then
    M.canvas:delete()
  end
  local screen = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  local frame = screen:frame()
  local width, height = math.min(380, frame.w - 40), 72
  local accent = failed and { red = 0.95, green = 0.4, blue = 0.35 }
    or { red = 0.65, green = 0.8, blue = 0.88 }
  M.canvas = hs.canvas
    .new({ x = frame.x + 20, y = frame.y + frame.h - height - 20, w = width, h = height })
    :level(hs.canvas.windowLevels.overlay)
    :behaviorAsLabels({ 'canJoinAllSpaces', 'stationary' })
  M.canvas
    :replaceElements({
      type = 'rectangle',
      action = 'strokeAndFill',
      fillColor = { red = 24 / 255, green = 33 / 255, blue = 40 / 255, alpha = 0.97 },
      strokeColor = accent,
      strokeWidth = 1,
      roundedRectRadii = { xRadius = 10, yRadius = 10 },
      frame = { x = 1, y = 1, w = width - 2, h = height - 2 },
    }, {
      type = 'text',
      text = message,
      textSize = 17,
      textColor = accent,
      frame = { x = 16, y = 12, w = width - 32, h = 26 },
    }, {
      type = 'text',
      text = failed and '자세한 오류는 Hammerspoon Console에서 확인'
        or '설정을 사용할 준비가 되었습니다',
      textSize = 12,
      textColor = { white = 0.8 },
      frame = { x = 16, y = 42, w = width - 32, h = 20 },
    })
    :show()
  M.timer = hs.timer.doAfter(failed and 6 or 1.5, function()
    if M.canvas then
      M.canvas:delete()
      M.canvas = nil
    end
    M.timer = nil
  end)
end

return M
