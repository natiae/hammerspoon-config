-- Shared screen geometry. System work area and custom margins stay distinct.
local M = {}

-- Every caller owns its margins; this module keeps no shared styling state.
function M.normalizeMargins(options)
  options = options or {}
  assert(type(options) == 'table', 'margins must be a table')
  local result = {}
  for _, key in ipairs({ 'top', 'left', 'right', 'bottom', 'autoTopFallback' }) do
    local value = options[key]
    if value == nil then
      value = key == 'autoTopFallback' and 28 or 0
    end
    assert(
      (key == 'top' and value == 'auto')
        or (type(value) == 'number' and value >= 0 and value < math.huge),
      'invalid margin: ' .. key
    )
    result[key] = value
  end
  return result
end

local function copy(frame)
  return { x = frame.x, y = frame.y, w = frame.w, h = frame.h }
end

-- Pass an hs.screen object. Values are recalculated so display/Dock changes
-- are reflected without retaining stale screen coordinates.
function M.get(screen, options)
  assert(screen, 'mac_window_geometry.get requires a screen')
  local full, work = copy(screen:fullFrame()), copy(screen:frame())
  local menuHeight = math.max(0, work.y - full.y)
  local margins = M.normalizeMargins(options)
  local top = margins.top
  if top == 'auto' then
    top = menuHeight > 0 and menuHeight or margins.autoTopFallback
  end
  local left, right, bottom = margins.left, margins.right, margins.bottom
  local x = math.max(work.x, full.x + left)
  local y = math.max(work.y, full.y + top)
  local endX = math.min(work.x + work.w, full.x + full.w - right)
  local endY = math.min(work.y + work.h, full.y + full.h - bottom)
  return {
    fullFrame = full,
    workFrame = work,
    menuBarHeight = menuHeight,
    insets = { top = top, left = left, right = right, bottom = bottom },
    placementFrame = { x = x, y = y, w = math.max(0, endX - x), h = math.max(0, endY - y) },
    -- Non-overlapping border rectangles in global screen coordinates.
    borders = {
      { x = full.x, y = full.y, w = full.w, h = top },
      { x = full.x, y = full.y + top, w = left, h = math.max(0, full.h - top - bottom) },
      {
        x = full.x + full.w - right,
        y = full.y + top,
        w = right,
        h = math.max(0, full.h - top - bottom),
      },
      { x = full.x, y = full.y + full.h - bottom, w = full.w, h = bottom },
    },
  }
end

-- Map screen IDs to geometry for all currently connected displays.
function M.all(options)
  local screens = {}
  for _, screen in ipairs(hs.screen.allScreens()) do
    screens[screen:id()] = M.get(screen, options)
  end
  return screens
end

local listeners = {}
local watcher, timer

local function notify(phase)
  -- One failing consumer must not prevent the others from updating.
  local snapshot = {}
  for token, callback in pairs(listeners) do
    snapshot[token] = callback
  end
  for token, callback in pairs(snapshot) do
    if listeners[token] then
      local ok, err = xpcall(function()
        callback(phase)
      end, debug.traceback)
      if not ok then
        hs.printf('mac_window_geometry subscriber error: %s', err)
      end
    end
  end
end

-- "changing" immediately invalidates overlays; "settled" follows the last
-- screen event by one second. All consumers share this watcher and timer.
-- Returns an unsubscribe function; the last unsubscribe stops monitoring.
function M.subscribe(callback)
  assert(type(callback) == 'function', 'subscribe requires a callback')
  local token = {}
  listeners[token] = callback
  if not watcher then
    timer = hs.timer.delayed.new(1, function()
      notify('settled')
    end)
    watcher = hs.screen.watcher
      .new(function()
        timer:start()
        notify('changing')
      end)
      :start()
  end
  return function()
    listeners[token] = nil
    if not next(listeners) and watcher then
      watcher:stop()
      timer:stop()
      watcher, timer = nil, nil
    end
  end
end

return M
