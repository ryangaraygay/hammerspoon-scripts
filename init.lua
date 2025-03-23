-- hs.fnutils.each(hs.application.runningApplications(), function(app) print(app:title()) end)

local appName = "MotiveWave"  -- Change this to the app you want to block
local blockDuration = 120 -- Time in seconds (5 minutes)
local breathCycles = 4    -- Number of breath cycles before final message

local clickBlocker = nil
local shade = nil
local countdownTimer = nil
local breathTimer = nil
local remainingTime = blockDuration
local breathSteps = { "breathe IN", "hold", "breathe OUT", "hold" }
local breathIndex = 1
local cycleCount = 0

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

    local f = win:frame() -- Get window size and position

    -- Create a semi-transparent overlay with countdown and breath text
    shade = hs.canvas.new(f):appendElements({
        { 
            type = "rectangle", 
            action = "fill", 
            fillColor = { red = 0, green = 0, blue = 0, alpha = 0.4 } -- Dark overlay
        },
        {
            type = "text",
            text = (remainingTime // 60) .. ":" .. string.format("%02d", remainingTime % 60), -- Only the time
            textSize = 60,
            textColor = { red = 0.6, green = 0.8, blue = 1, alpha = 1 },
            frame = { x = "20%", y = "35%", w = "60%", h = "20%" }, -- Centered text
            textAlignment = "center"
        },
        {
            type = "text",
            text = breathSteps[breathIndex],  -- Initial breath cycle text
            textSize = 50,
            textColor = { red = 0.6, green = 0.75, blue = 0.6, alpha = 1 },
            frame = { x = "20%", y = "50%", w = "60%", h = "20%" }, -- Positioned below the countdown
            textAlignment = "center"
        }
    })
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
        if shade then
            shade[2].text = (remainingTime // 60) .. ":" .. string.format("%02d", remainingTime % 60) -- Only time
            shade:show()
        end
        if remainingTime <= 0 then
            removeBlock()
        end
    end)

    -- Start breathing cycle
    breathIndex = 1
    cycleCount = 0
    breathTimer = hs.timer.doEvery(4, function()
        if cycleCount >= breathCycles then
            shade[3].text = "breathe, draw, wait for next best trade & trust yourself"
            breathTimer:stop() -- Stop after final message
        else
            shade[3].text = breathSteps[breathIndex]
            breathIndex = (breathIndex % #breathSteps) + 1
            if breathIndex == 1 then
                cycleCount = cycleCount + 1
            end
        end
        shade:show()
    end)

    hs.alert(appName .. " is disabled for " .. (blockDuration / 60) .. " minutes!")
end

function removeBlock()
    if clickBlocker then 
        clickBlocker:stop() 
        clickBlocker = nil
    end
    if shade then 
        shade:delete() 
        shade = nil
    end
    if countdownTimer then
        countdownTimer:stop()
        countdownTimer = nil
    end
    if breathTimer then
        breathTimer:stop()
        breathTimer = nil
    end
    hs.alert(appName .. " is now enabled!")
end

-- Hotkeys
hs.hotkey.bind({"cmd", "alt"}, "D", blockAppClicks)  -- Start blocking
hs.hotkey.bind({"cmd", "alt", "shift"}, "R", removeBlock)  -- Force remove

hs.alert("Press CMD+ALT+D to disable " .. appName .. " temporarily")
hs.alert("Press CMD+ALT+SHIFT+R to force remove the block")
