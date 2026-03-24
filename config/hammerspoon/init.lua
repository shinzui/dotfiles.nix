-- Enable IPC so the `hs` CLI can communicate with the running instance.
-- This is required for the activation reload hook to work.
require("hs.ipc")

-- Focus follows mouse
-- When the mouse hovers over a window for a brief moment, that window gains focus.

local focusDelay = 0.3
local focusTimer = nil

local function pointInsideFrame(point, frame)
  return point.x >= frame.x and point.x <= frame.x + frame.w
     and point.y >= frame.y and point.y <= frame.y + frame.h
end

local mouseMoved = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
  if focusTimer then
    focusTimer:stop()
  end

  focusTimer = hs.timer.doAfter(focusDelay, function()
    local mousePoint = hs.mouse.absolutePosition()
    local wins = hs.window.orderedWindows()

    for _, w in ipairs(wins) do
      if pointInsideFrame(mousePoint, w:frame()) then
        local focused = hs.window.focusedWindow()
        if focused and w:id() ~= focused:id() then
          w:focus()
        end
        break
      end
    end
  end)

  return false
end)

mouseMoved:start()
