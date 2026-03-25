-- Enable IPC so the `hs` CLI can communicate with the running instance.
-- This is required for the activation reload hook to work.
require("hs.ipc")

-- Focus follows mouse
-- When the mouse hovers over a window for a brief moment, that window gains focus.
-- Works across multiple monitors.

local focusDelay = 0.2
local focusTimer = nil

local function pointInsideFrame(point, frame)
  return point.x >= frame.x and point.x <= frame.x + frame.w
     and point.y >= frame.y and point.y <= frame.y + frame.h
end

-- Use a window filter that tracks all visible windows across all screens.
local wf = hs.window.filter.new()
  :setDefaultFilter()
  :setOverrideFilter({ visible = true, fullscreen = false, currentSpace = true })

local mouseMoved = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
  if focusTimer then
    focusTimer:stop()
  end

  focusTimer = hs.timer.doAfter(focusDelay, function()
    local mousePoint = hs.mouse.absolutePosition()
    local focused = hs.window.focusedWindow()

    -- orderedWindows() returns all visible windows in z-order across all screens
    local wins = hs.window.orderedWindows()

    for _, w in ipairs(wins) do
      if w:isVisible() and w:isStandard() and pointInsideFrame(mousePoint, w:frame()) then
        if not focused or w:id() ~= focused:id() then
          w:focus()
        end
        return
      end
    end
  end)

  return false
end)

mouseMoved:start()
