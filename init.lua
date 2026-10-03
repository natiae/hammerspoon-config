-- Small bootstrap: keep user configuration in config.lua so syntax errors there
-- can be caught before reporting completion.
require('hs.ipc')
hs.hotkey.bind({ 'ctrl', 'option', 'shift' }, 'R', hs.reload)

local status = require('modules.utils.status_overlay')
local loadFailed = false
local loading = true
local defaultShowError = hs.showError
hs.showError = function(err)
  loadFailed = true
  print('*** ERROR: ' .. tostring(err))
  local ok = pcall(
    status.show,
    loading and 'Hammerspoon 설정 로드 오류' or 'Hammerspoon 실행 오류',
    true
  )
  if not ok then
    defaultShowError(err)
  end
end

local ok, err = xpcall(function()
  local config, syntaxError = loadfile(hs.configdir .. '/config.lua')
  assert(config, syntaxError)
  config()
end, debug.traceback)
if not ok then
  hs.showError(err)
end
loading = false
if not loadFailed then
  status.show('Hammerspoon 설정 로드 완료', false)
end
