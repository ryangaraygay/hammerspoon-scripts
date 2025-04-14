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

local noticeRules = {
    {time="06:30", message="6:30 market open"},
    {time="06:45", message="6:45 opening range set"},
    {time="07:00", message="7:00 am"},
    {time="07:30", message="7:30 initial balance set"},
    {time="08:30", message="8:30 market towards break"},
    {time="12:00", message="12:00 one hour to close"},
    {time="12:30", message="12:30 market towards close"},
    {time="13:00", message="13:00 market closed"},
}

local screen = hs.screen.primaryScreen()
local screenFrame = screen:frame()
local width, height = 600, 100

local overlay = hs.canvas.new{
    x = screenFrame.x + screenFrame.w - width - 1,
    y = screenFrame.y + screenFrame.h - height - 1,
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

local function getNow()
    return os.date("*t")
end

local function getRule(dateTable)
    local currentMinutes = (dateTable.hour * 60) + dateTable.min
    for i, rule in ipairs(rules) do
        if currentMinutes >= timeToMinutes(rule.start) and currentMinutes < timeToMinutes(rule.stop) then
            return rule
        end
    end
    return nil
end

local function getNoticeRule(dateTable)
    local currentMinutes = (dateTable.hour * 60) + dateTable.min
    for i, rule in ipairs(noticeRules) do
        if currentMinutes == timeToMinutes(rule.time) then
            return rule
        end
    end
    return nil
end

local function updateOverlayWithRule(rule)
    overlay["bg"].fillColor = rule.color
    overlay["label"].text = rule.message
    overlay:show()
end

function updateOverlay(dateTable)
    local d = dateTable or getNow()
    local rule = getRule(d)
    if rule then
        updateOverlayWithRule(rule)
    else
        overlay:hide()
    end

    local noticeRule = getNoticeRule(d)
    if noticeRule then
        hs.alert.show(noticeRule.message, { fillColor = { red = 0.5, green = 0.6, blue = 0.6, alpha = 0.9 }}, 5)
    end
end

-- Manual tester
function showRule(index)
    local rule = rules[index]
    if rule then
        updateOverlayWithRule(rule)
    else
        hs.alert("No such rule index: " .. tostring(index))
    end
end

local updateTimer = nil

-- Sync to the next full minute
local function startOverlayTimer()
    if updateTimer and updateTimer:running() then return end

    -- How many seconds until the next full minute?
    local now = getNow()
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

local function isWeekday(dateTable)
    local day = (dateTable or getNow()).wday
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


-- console tests
-- to test display -> showRule(1)
-- to test schedule response -> updateOverlay(os.date("*t", os.time({year=2025,month=4,day=13,hour=6,min=30,sec=0})))
-- to test actual timers (cmd+alt+m, cmd+alt+n)