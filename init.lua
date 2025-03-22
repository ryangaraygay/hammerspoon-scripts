local appName = "MotiveWave"  -- Change this to the app you want to block
local blockDuration = 120 -- Time in seconds (5 minutes)

local clickBlocker = nil
local shade = nil
local countdownTimer = nil
local remainingTime = blockDuration

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

    -- Create a semi-transparent overlay with countdown text
    shade = hs.canvas.new(f):appendElements({
        { 
            type = "rectangle", 
            action = "fill", 
            fillColor = { red = 0, green = 0, blue = 0, alpha = 0.4 } -- Dark overlay
        },
        {
            type = "text",
            text = (remainingTime // 60) .. ":" .. string.format("%02d", remainingTime % 60),
            textSize = 40,
            textColor = { red = 1, green = 1, blue = 1, alpha = 1 },
            frame = { x = "20%", y = "40%", w = "60%", h = "20%" }, -- Centered text
            textAlignment = "center"
        },
        {
            type = "text",
            text = "breathe, draw & trust yourself",
            textSize = 40,
            textColor = { red = 1, green = 1, blue = 1, alpha = 1 },
            frame = { x = "20%", y = "55%", w = "60%", h = "20%" }, -- Centered text
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
            shade[2].text = (remainingTime // 60) .. ":" .. string.format("%02d", remainingTime % 60)
            shade:show()
        end
        if remainingTime <= 0 then
            removeBlock()
        end
    end)

    -- hs.alert(appName .. " is disabled for " .. (blockDuration / 60) .. " minutes!")
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
    -- hs.alert(appName .. " is now enabled!")
end

-- Hotkeys
hs.hotkey.bind({"cmd", "alt"}, "D", blockAppClicks)  -- Start blocking
hs.hotkey.bind({"cmd", "alt", "shift"}, "R", removeBlock)  -- Force remove

hs.alert("Press CMD+ALT+D to disable " .. appName .. " temporarily")
hs.alert("Press CMD+SHFT+ALT+R to force remove the block")
