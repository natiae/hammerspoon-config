-- Shared appearance for the placement grid and window picker.
local function rgb(r, g, b, a)
  return { red = r / 255, green = g / 255, blue = b / 255, alpha = a or 1 }
end
return {
  font = 'Helvetica Neue',
  radius = 10,
  background = rgb(24, 33, 40, 0.97),
  overlay = rgb(24, 33, 40, 0.42),
  surface = rgb(49, 65, 77),
  emptySurface = rgb(32, 43, 52),
  text = rgb(239, 240, 236),
  muted = rgb(170, 185, 194),
  disabled = rgb(88, 105, 118),
  accent = rgb(166, 202, 225),
  gridLine = rgb(166, 202, 225, 0.55),
  selected = rgb(74, 98, 117, 0.7),
  target = rgb(228, 208, 145),
  targetFill = rgb(228, 208, 145, 0.18),
}
