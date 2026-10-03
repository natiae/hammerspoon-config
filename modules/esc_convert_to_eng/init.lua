local obj = {
  inputEnglish = 'com.apple.keylayout.ABC',
  onChangeOfScreenOnly = false,
  currentWindowScreen = nil,
}

function obj:changeToEng()
  hs.keycodes.currentSourceID(self.inputEnglish)
end

function obj:convertToEngWithEsc()
  local input_source = hs.keycodes.currentSourceID()
  if not (input_source == self.inputEnglish) then
    hs.eventtap.keyStroke({}, 'right')
    self:changeToEng()
  end
  self.escBind:disable()
  hs.eventtap.keyStroke({}, 'escape')
  self.escBind:enable()
end

function obj:start()
  self.escBind = hs.hotkey
    .new({}, 'escape', function()
      obj:convertToEngWithEsc()
    end)
    :enable()
  self.windowFilter = hs.window.filter
    .new({ override = {
      visible = true,
    } })
    :setDefaultFilter({
      visible = true,
    })
  self.windowFilter:subscribe({
    hs.window.filter.windowFocused,
  }, function(window)
    if
      self.onChangeOfScreenOnly
      and self.currentWindowScreen
      and self.currentWindowScreen:id() == window:screen():id()
    then
      return
    end
    self.currentWindowScreen = window:screen()
    self:changeToEng()
  end)
end

function obj:stop()
  self.escBind:disable()
  self.escBind = nil
  self.windowFilter:unsubscribeAll()
  self.windowFilter = nil
end

return obj
