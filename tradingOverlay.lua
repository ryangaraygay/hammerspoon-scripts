-- Define time rules
local rules = {
    {start="06:30", stop="06:45", message="Trade - Small, opportunistic", color={red=0, green=0, blue=1, alpha=0.5}}, -- Blue
    {start="06:45", stop="07:05", message="Trade - Exit only", color={red=1, green=0, blue=0, alpha=0.5}},             -- Red
    {start="07:05", stop="07:55", message="Trade - Full Size and Engage", color={red=0, green=1, blue=0, alpha=0.5}},   -- Green
    {start="07:55", stop="08:20", message="Trade - Small, opportunistic", color={red=0, green=0, blue=1, alpha=0.5}},   -- Blue
    {start="08:20", stop="10:05", message="Trade - Exit only, Break", color={red=1, green=0, blue=0, alpha=0.5}},       -- Red
    {start="10:05", stop="11:55", message="Trade - Small, opportunistic on high volatility only and break required", color={red=0, green=0, blue=1, alpha=0.5}}, -- Blue
    {start="11:55", stop="13:00", message="Trade - Exit runners only", color={red=1, green=0, blue=0, alpha=0.5}},      -- Red
}

local screen = hs.screen.primaryScreen()
local screenFrame = screen:frame()
local width, height = 384, 96

local overlay = hs.canvas.new{
    x = screenFrame.x + screenFrame.w - width - 20,
    y = screenFrame.y + screenFrame.h - height - 20,
    w = width,
    h = height
}:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = {alpha=0}, -- will be set dynamically
    roundedRectRadii = {xRadius = 10, yRadius = 10},
    withShadow = true,
    id = "bg"
}, {
    type = "text",
    text = "",
    textSize = 30,
    textColor = {white = 1},
    textAlignment = "center",
    frame = {x = 0, y = height / 2 - 10, w = width, h = 100},
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
    hs.alert(timeToMinutes(rule.start))
    hs.alert(timeToMinutes(rule.stop))
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
local function startSynchronizedTimer()
    if updateTimer and updateTimer:running() then updateTimer:stop() end

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

-- For hotkey use too
startSynchronizedTimer()

-- START hotkey (Cmd + Alt + M)
hs.hotkey.bind({"cmd", "alt"}, "M", function()
    startSynchronizedTimer()
    hs.alert("Trade - Overlay Started")
end)

-- STOP hotkey (Cmd + Alt + N)
hs.hotkey.bind({"cmd", "alt"}, "N", function()
    if updateTimer and updateTimer:running() then
        updateTimer:stop()
    end
    overlay:hide()
    hs.alert("Trade - Overlay Stopped")
end)
