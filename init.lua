-- hs.fnutils.each(hs.application.runningApplications(), function(app) print(app:title()) end)

-- CONFIG
local appName = "MotiveWave"  -- Change this to the app you want to block
local blockDuration = 180 -- Time in seconds
local cyclesCompletedMessage = "breathe, read reset plan, you got this"
local defaultBreathCycles = 5

-- STATE
local clickBlocker = nil
local shade = nil
local countdownTimer = nil
local breathTimer = nil
local remainingTime = blockDuration
local cycleCount = 0
local stepIndex = 1
local breathCycles = defaultBreathCycles
local breathSteps = {}

-- Breathing Pattern Definitions
local breathingPatterns = {
    ["4-4-6"] = {
        { text = "Breathe In", duration = 4 },
        { text = "Hold", duration = 4 },
        { text = "Breathe Out", duration = 6 }
    },
    ["4-4-4-4"] = {
        { text = "Breathe In", duration = 4 },
        { text = "Hold", duration = 4 },
        { text = "Breathe Out", duration = 4 },
        { text = "Hold", duration = 4 },
    },
}

-- Set active breathing pattern
function setBreathingPattern(patternName)
    if breathingPatterns[patternName] then
        breathSteps = breathingPatterns[patternName]
    else
        hs.alert("Unknown breathing pattern: " .. patternName)
    end
end

-- Breath Step Advance
function nextBreathStep()
    if cycleCount >= breathCycles then
        if shade and shade[3] then
            shade[3].text = cyclesCompletedMessage
            shade:show()
        end
        if breathTimer then breathTimer:stop() end
        return
    end

    local step = breathSteps[stepIndex]
    if not step then return end

    if shade and shade[3] then
        shade[3].text = step.label or step.text  -- depending on your breathSteps definition
        shade:show()
    end

    stepIndex = stepIndex + 1
    if stepIndex > #breathSteps then
        stepIndex = 1
        cycleCount = cycleCount + 1
    end

    if breathTimer then breathTimer:stop() end
    breathTimer = hs.timer.doAfter(step.duration, nextBreathStep)
end

-- Start the breathing cycle
function startBreathingTimer(numCycles)
    if numCycles then
        breathCycles = numCycles
    else
        cycleCount = 0 -- Reset cycle count if starting again without specifying cycles
    end
    stepIndex = 1 -- Reset step index
    nextBreathStep()
end

local function createShade(frame)
    return hs.canvas.new(frame):appendElements({
        {
            type = "rectangle",
            action = "fill",
            fillColor = { red = 0, green = 0, blue = 0, alpha = 0.4 } -- Dark overlay
        },
        {
            type = "text",
            text = "",
            textSize = 60,
            textColor = { red = 0.6, green = 0.8, blue = 1, alpha = 1 },
            frame = { x = "20%", y = "40%", w = "60%", h = "20%" }, -- Centered text
            textAlignment = "center"
        },
        {
            type = "text",
            text = "",
            textSize = 50,
            textColor = { red = 0.6, green = 0.75, blue = 0.6, alpha = 1 },
            frame = { x = "20%", y = "50%", w = "60%", h = "20%" }, -- Positioned below the countdown
            textAlignment = "center"
        }
    })
end

-- App click blocker with countdown + breathing overlay
function blockAppClicks()
    local app = hs.application.find(appName)
    if not app then
        hs.alert("App not found: " .. appName)
        return
    end

    local win = app:mainWindow()
    if not win then
        hs.alert("No active window for " .. appName)
        return
    end

    local f = win:frame()
    shade = createShade(f)
    shade:show()

    -- Block mouse clicks **only inside the app window**
    clickBlocker = hs.eventtap.new({hs.eventtap.event.types.leftMouseDown, hs.eventtap.event.types.rightMouseDown}, function(event)
        local mousePos = hs.mouse.absolutePosition()
        local winFrame = win:frame() -- Get the updated window position

        if mousePos.x >= winFrame.x and mousePos.x <= (winFrame.x + winFrame.w) and
           mousePos.y >= winFrame.y and mousePos.y <= (winFrame.y + winFrame.h) then
            hs.alert("Blocked! " .. appName .. " is disabled!")
            return true -- Block the click
        end
        return false -- Allow clicks outside the window
    end)
    clickBlocker:start()

    -- Start countdown timer
    remainingTime = blockDuration
    countdownTimer = hs.timer.doEvery(1, function()
        remainingTime = remainingTime - 1
        if shade and shade[2] then
            shade[2].text = string.format("%d:%02d", remainingTime // 60, remainingTime % 60)
            shade:show()
        end
        if remainingTime <= 0 then
            removeBlock()
        end
    end)

    setBreathingPattern("4-4-6")
    startBreathingTimer()
end

-- Desktop-wide breathing overlay (click-through)
function startDesktopBreathingOverlay(patternName, numCycles)
    setBreathingPattern(patternName or "4-4-4-4")
    breathCycles = numCycles or 10
    cycleCount = 0
    stepIndex = 1

    remainingTime = 0
    for _, step in ipairs(breathSteps) do
        remainingTime = remainingTime + step.duration
    end
    remainingTime = remainingTime * breathCycles

    local screenFrame = hs.screen.mainScreen():frame()
    shade = createShade(screenFrame)
    shade:show()

    if countdownTimer then countdownTimer:stop() end
    countdownTimer = hs.timer.doEvery(1, function()
        remainingTime = remainingTime - 1
        if shade and shade[2] then
            shade[2].text = string.format("%d:%02d", remainingTime // 60, remainingTime % 60)
            shade:show()
        end
        if remainingTime <= 0 then
            removeBlock()
        end
    end)

    nextBreathStep()
end

function removeBlock()
    if clickBlocker then clickBlocker:stop(); clickBlocker = nil end
    if shade then shade:delete(); shade = nil end
    if countdownTimer then countdownTimer:stop(); countdownTimer = nil end
    if breathTimer then breathTimer:stop(); breathTimer = nil end
end

function runTradingStatsTracker()
    local task = hs.task.new("/Users/ryangaraygay/.pyenv/shims/python", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            print("Trading Stats Tracker output:")
            print(stdOut)
        else
            print("Trading Stats Tracker exited with errors:")
            print(stdErr)
        end
    end, {"/Users/ryangaraygay/Desktop/Github/trading-stats-tracker/app.py"})
    task:start()
end

function parse_key_value_string(input_string)
    local result = {}
    for key, value in string.gmatch(input_string, "([^&=]+)=([^&=]*)") do
        result[key] = value
    end
    return result
end

-- Hotkeys
hs.hotkey.bind({"cmd", "alt"}, "right", blockAppClicks)                  -- Block app
hs.hotkey.bind({"cmd", "alt", "shift"}, "B", removeBlock)               -- Remove overlay
hs.hotkey.bind({"cmd", "alt"}, "left", function() startDesktopBreathingOverlay("4-4-4-4", 4) end) -- Desktop overlay
hs.hotkey.bind({"cmd", "alt"}, "T", runTradingStatsTracker)             -- Run stats tracker
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function() hs.reload() end) -- Reload

require("hs.ipc")

-- URL event for remote triggering
hs.urlevent.bind("block-app", function(eventName, params, senderPID, fullURL)
    local p = params["p"]
    local key_value_pairs = parse_key_value_string(p)
    for key, value in pairs(key_value_pairs) do
        if key == "app_name" then appName = value
        elseif key == "duration" then blockDuration = tonumber(value) end
    end
    blockAppClicks()
end)

-- Function to display an alert
local function showAlert(message)
    hs.alert.show(message, { fillColor = { red = 0.5, green = 0.6, blue = 0.6, alpha = 0.9 }}, 10)
end
  
-- Function to check if a given date table represents a weekday (Monday to Friday)
local function isWeekday(dateTable)
    local weekday = dateTable.wday -- Sunday is 1, Monday is 2, ..., Saturday is 7
    return weekday >= 2 and weekday <= 6
end
  
-- Function to schedule a weekday alert for a specific hour and minute
local function scheduleWeekdayAlert(hour, minute, message)
    local function scheduleNext()
        local now = os.date("*t")
        local targetTime = { year = now.year, month = now.month, day = now.day, hour = hour, min = minute, sec = 0 }
        local targetDateEpoch = os.time(targetTime)
        local nowEpoch = os.time(now)
        local secondsUntilTarget = targetDateEpoch - nowEpoch

        -- If the target time is in the past today, schedule for tomorrow
        if secondsUntilTarget <= 0 then
            secondsUntilTarget = secondsUntilTarget + (24 * 60 * 60)
        end

        hs.timer.doAfter(secondsUntilTarget, function()
            local currentDate = os.date("*t")
            if isWeekday(currentDate) then
                showAlert(message)
            end
            scheduleNext() -- Schedule for the next day
        end)
    end

    scheduleNext() -- Initial scheduling
end

scheduleWeekdayAlert(6, 30, "6:30 market open")
scheduleWeekdayAlert(6, 45, "6:45 opening range set")
scheduleWeekdayAlert(7, 0, "7:00 am")
scheduleWeekdayAlert(7, 30, "7:30 initial balance set")
scheduleWeekdayAlert(8, 30, "8:30 market towards break")
scheduleWeekdayAlert(12, 00, "12:00 one hour to close")
scheduleWeekdayAlert(12, 30, "12:30 market towards close")
scheduleWeekdayAlert(13, 0, "13:00 market closed")

-- hs.hotkey.bind({"cmd", "alt"}, "P", function() showAlert("10:30 market might be back from lunch") end)

hs.alert("CMD+ALT+→ = block app\nCMD+ALT+← = desktop breathing guide\nCMD+ALT+SHIFT+B = remove block\nCTRL+ALT+T = trading stats tracker\nCTRL+ALT+R = reload config", 5)

require("tradingOverlay")