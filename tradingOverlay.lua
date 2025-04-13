local Colors = {
    Blue  = {red=0, green=0, blue=0.8, alpha=0.4},
    Red   = {red=0.8, green=0, blue=0, alpha=0.4},
    Green = {red=0, green=0.8, blue=0, alpha=0.4},
}

-- Define time rules
local rules = {
    {start="06:00", stop="06:30", message="Premarket", color=Colors.Blue},
    {start="06:30", stop="06:45", message="Small, opportunistic", color=Colors.Blue},
    {start="06:45", stop="07:05", message="Exit only", color=Colors.Red},
    {start="07:05", stop="07:55", message="Full Size and Engage", color=Colors.Green},
    {start="07:55", stop="08:20", message="Small, opportunistic", color=Colors.Blue},
    {start="08:20", stop="10:05", message="Exit only, Break", color=Colors.Red},
    {start="10:05", stop="11:55", message="Small, opportunistic, high volatility only\nbreak required", color=Colors.Blue},
    {start="11:55", stop="13:00", message="Exit runners only", color=Colors.Red},
    {start="13:00", stop="14:00", message="No trades\nMarket Runoff", color=Colors.Red},
}

local screen = hs.screen.primaryScreen()
local screenFrame = screen:frame()
local width, height = 600, 100

local overlay = hs.canvas.new{
    x = screenFrame.x + screenFrame.w - width - 20,
    y = screenFrame.y + screenFrame.h - height - 20,
    w = width,
    h = height
}:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = {alpha=0}, -- will be set dynamically
    roundedRectRadii = {xRadius = 20, yRadius = 20},
    withShadow = true,
    id = "bg"
}, {
    type = "text",
    text = "",
    textSize = 30,
    textColor = {white = 1},
    textAlignment = "center",
    frame = {x = 0, y = (height / 2) - 30, w = width, h = 120},
    id = "label"
})

overlay:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces + hs.canvas.windowBehaviors.stationary)
overlay:level(hs.canvas.windowLevels.screenSaver)
overlay:clickActivating(false)

local function timeToMinutes(timeStr)
    local h, m = timeStr:match("(%d+):(%d+)")
    return tonumber(h) * 60 + tonumber(m)
end

local function getCurrentRule()
    local now = os.date("*t")
    local currentMinutes = now.hour * 60 + now.min
    for i, rule in ipairs(rules) do
        if currentMinutes >= timeToMinutes(rule.start) and currentMinutes < timeToMinutes(rule.stop) then
            return rule
        end
    end
    return nil
end

function updateOverlay()
    local rule = getCurrentRule()
    if rule then
        overlay["bg"].fillColor = rule.color
        overlay["label"].text = rule.message
        overlay:show()
    else
        overlay:hide()
    end
end

-- Manual tester
function showRule(index)
    local rule = rules[index]
    if rule then
        overlay["bg"].fillColor = rule.color
        overlay["label"].text = rule.message
        overlay:show()
    else
        hs.alert("No such rule index: " .. tostring(index))
    end
end

local updateTimer = nil

-- Sync to the next full minute
local function startOverlayTimer()
    if updateTimer and updateTimer:running() then return end

    -- How many seconds until the next full minute?
    local now = os.date("*t")
    local delay = 60 - now.sec

    hs.timer.doAfter(delay, function()
        updateOverlay() -- immediate update at exact minute
        updateTimer = hs.timer.doEvery(60, updateOverlay)
    end)

    -- Optional: show an immediate update when enabling, even before sync
    updateOverlay()
end

local function stopOverlayTimer()
    if updateTimer and updateTimer:running() then
        updateTimer:stop()
        updateTimer = nil
    end
    overlay:hide()
end

local function isWeekday()
    local day = os.date("*t").wday
    return day >= 2 and day <= 6  -- Monday=2 ... Friday=6
end

-- Boot-time check
if isWeekday() then
    local hour = tonumber(os.date("%H"))
    if hour >= 6 and hour < 14 then
        startOverlayTimer()
    end
end

-- Start every weekday at 06:00
hs.timer.doAt("06:00", "1d", function()
    if isWeekday() then startOverlayTimer() end
end)

-- Stop every weekday at 14:00
hs.timer.doAt("14:00", "1d", function()
    if isWeekday() then stopOverlayTimer() end
end)

-- START hotkey (Cmd + Alt + M)
hs.hotkey.bind({"cmd", "alt"}, "M", function()
    startOverlayTimer()
    hs.alert("Overlay Started (Manual)")
end)

-- STOP hotkey (Cmd + Alt + N)
hs.hotkey.bind({"cmd", "alt"}, "N", function()
    stopOverlayTimer()
    hs.alert("Overlay Stopped (Manual)")
end)
