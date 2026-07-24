local environment = peripheral.find("environment_detector")
local detector = peripheral.find("player_detector")
local hudmodem = peripheral.find("hud_glasses")
local modemsussy = peripheral.wrap("left")

local activationdist = 9
local lerpFactor = 0.22 -- Adjust this to change smoothness (lower = smoother, higher = faster)
local lockOnThreshold = 5 -- How close to the center of the screen a dot must be to trigger target lock-on

modemsussy.open(4504)

local VIEWER = "Hooman4504"

hudmodem.clear()

local playerCache = {}
local smoothPlayerCache = {}
local doors = {}
local doorLogs = {} -- Stores recent door activity logs
local doorCooldowns = {} -- Prevents log spam while a player stays near a door

local currentFrame = {}
local lastFrame = {}

-- Define colors for different dimensions
local dimColors = {
    ["minecraft:overworld"] = colors.green,
    ["minecraft:the_nether"] = colors.red,
    ["minecraft:the_end"] = colors.purple,
}

local function getDimColor(dim)
    return dimColors[dim] or colors.white
end

local function addDoorLog(doorId)
    table.insert(doorLogs, {
        text = string.format("[LOG] Opened Door #%s", tostring(doorId)),
        time = os.clock()
    })
    -- Keep log history manageable
    if #doorLogs > 5 then
        table.remove(doorLogs, 1)
    end
end

local function distcalcT3(pos, plr)
    local center = pos
    local half = activationdist / 2
    local halfvector = vector.new(half, half, half)

    local minpos = center - halfvector
    local maxpos = center + halfvector
    return detector.isPlayerInCoords(minpos, maxpos, plr)
end

-- Writes characters into an in-memory buffer grid for diff rendering
local function bufferText(x, y, text, color, maxW)
    color = color or colors.white
    local len = #text
    if maxW and len > maxW then
        text = string.sub(text, 1, maxW)
        len = maxW
    end

    for i = 1, len do
        local posX = x + i - 1
        local ch = string.sub(text, i, i)
        local key = posY .. ":" .. posX
        currentFrame[key] = { char = ch, color = color, x = posX, y = y }
    end
end

-- Flushes only modified screen characters to the HUD glasses
local function renderDiff()
    -- Erase pixels that were present in lastFrame but not in currentFrame
    for key, oldPixel in pairs(lastFrame) do
        if not currentFrame[key] then
            hudmodem.setCursorPos(oldPixel.x, oldPixel.y)
            hudmodem.write(" ")
        end
    end

    -- Draw/update pixels that are new or changed in currentFrame
    for key, newPixel in pairs(currentFrame) do
        local oldPixel = lastFrame[key]
        if not oldPixel or oldPixel.char ~= newPixel.char or oldPixel.color ~= newPixel.color then
            hudmodem.setCursorPos(newPixel.x, newPixel.y)
            hudmodem.setTextColor(newPixel.color)
            hudmodem.write(newPixel.char)
        end
    end

    lastFrame = currentFrame
    currentFrame = {}
end

-- Smooths out wrapping angles (like looking past North)
local function lerpAngle(current, target, factor)
    local diff = (target - current + 180) % 360 - 180
    return current + diff * factor
end

-- Calculates where off-screen objects should be projected on the borders of your glasses
local function getScreenEdgeIntersection(w, h, dx, dy)
    if dx == 0 and dy == 0 then return math.floor(w / 2), math.floor(h / 2), ">" end
    
    local cx, cy = w / 2, h / 2
    local t = 1e9
    
    local marginX = 4 -- Margin inside vertical borders (x=2 and x=w-1)
    local marginY = 3
    
    if dx > 0 then
        t = math.min(t, (w - marginX - cx) / dx)
    elseif dx < 0 then
        t = math.min(t, (marginX - cx) / dx)
    end
    
    if dy > 0 then
        t = math.min(t, (h - marginY - cy) / dy)
    elseif dy < 0 then
        t = math.min(t, (marginY - cy) / dy)
    end
    
    local edgeX = math.floor(cx + t * dx)
    local edgeY = math.floor(cy + t * dy)
    
    -- Keep edge symbols safely inside the frame lines
    edgeX = math.max(3, math.min(w - 2, edgeX))
    edgeY = math.max(2, math.min(h - 1, edgeY))
    
    local angle = math.atan2(dy, dx)
    local deg = math.deg(angle)
    local symbol = "•"
    if deg > -45 and deg <= 45 then
        symbol = ">"
    elseif deg > 45 and deg <= 135 then
        symbol = "v"
    elseif deg > -135 and deg <= -45 then
        symbol = "^"
    else
        symbol = "<"
    end
    
    return edgeX, edgeY, symbol
end

local function worldToHud(viewer, target)
    local dx = target.x - viewer.x
    local dy = (target.y + 1.62) - viewer.y
    local dz = target.z - viewer.z

    local yaw = math.rad(viewer.yaw or 0)
    local pitch = math.rad(viewer.pitch or 0)

    -- Yaw rotation
    local sx = -dx * math.cos(yaw) - dz * math.sin(yaw)
    local sz = -dx * math.sin(yaw) + dz * math.cos(yaw)

    -- Pitch rotation
    local sy = dy * math.cos(pitch) + sz * math.sin(pitch)
    sz = -dy * math.sin(pitch) + sz * math.cos(pitch)

    local w, h = hudmodem.getSize()
    local fov = 24

    local isBehind = (sz <= 0.5)
    local testX = sx
    local testY = sy
    if isBehind then
        testX = -sx
        testY = -sy
    end

    local depth = math.max(0.1, math.abs(sz))
    local screenX = math.floor(w / 2 + (testX / depth) * fov)
    local screenY = math.floor(h / 2 - (testY / depth) * fov)

    local isOffScreen = isBehind or (screenX < 3 or screenX > w - 2 or screenY < 2 or screenY > h - 1)

    if isOffScreen then
        local rx = screenX - (w / 2)
        local ry = (h / 2) - screenY
        local edgeX, edgeY, symbol = getScreenEdgeIntersection(w, h, rx, -ry)
        return edgeX, edgeY, true, symbol
    else
        return screenX, screenY, false, "•"
    end
end

local function updateSmoothCache()
    for name, real in pairs(playerCache) do
        local smooth = smoothPlayerCache[name]
        if not smooth then
            smoothPlayerCache[name] = {
                x = real.x,
                y = real.y,
                z = real.z,
                yaw = real.yaw or 0,
                pitch = real.pitch or 0,
                dimension = real.dimension,
                name = real.name
            }
        else
            smooth.x = smooth.x + (real.x - smooth.x) * lerpFactor
            smooth.y = smooth.y + (real.y - smooth.y) * lerpFactor
            smooth.z = smooth.z + (real.z - smooth.z) * lerpFactor
            smooth.yaw = lerpAngle(smooth.yaw, real.yaw or 0, lerpFactor)
            smooth.pitch = lerpAngle(smooth.pitch, real.pitch or 0, lerpFactor)
            smooth.dimension = real.dimension
        end
    end

    for name in pairs(smoothPlayerCache) do
        if not playerCache[name] then
            smoothPlayerCache[name] = nil
        end
    end
end

-- Renders brackets on the edges of the HUD to frame the UI
local function drawHUDDecorations(w, h)
    local frameColor = colors.cyan

    -- Left border bracket line (column 2)
    for y = 2, h - 1 do
        bufferText(2, y, "|", frameColor)
    end

    -- Right border bracket line (column w - 1)
    for y = 2, h - 1 do
        bufferText(w - 1, y, "|", frameColor)
    end

    -- Blinking Active Indicator (top-left)
    local blink = math.floor(os.clock() * 1.5) % 2 == 0
    local activeColor = blink and colors.green or colors.gray
    local title = "HUD GLASSES: ACTIVE"
    bufferText(4, 2, title, activeColor, w - 5)
end

local function discoverDoors()
    while true do
        modemsussy.transmit(4504, 4505, "getpos")
        sleep(10)
    end
end

local function scanPlayers()
    while true do
        local players = detector.getOnlinePlayers()
        for _, name in ipairs(players) do
            local p = detector.getPlayer(name)
            if p then
                playerCache[name] = {
                    x = p.x,
                    y = p.y,
                    z = p.z,
                    dimension = p.dimension,
                    yaw = p.yaw,
                    pitch = p.pitch,
                    name = p.name,
                }
            end
        end
        sleep(0.05)
    end
end

local function updateComputers()
    while true do
        local now = os.clock()
        for name, p in pairs(playerCache) do
            for id, door in pairs(doors) do
                if distcalcT3(door.pos, p.name) then
                    modemsussy.transmit(4504, 4505, {type = "open", id = id})
                    
                    -- Only record a log entry if this door hasn't been triggered in the last 5 seconds
                    local lastTrigger = doorCooldowns[id] or 0
                    if now - lastTrigger > 5.0 then
                        addDoorLog(id)
                        doorCooldowns[id] = now
                    end
                end
            end
        end
        sleep(0.1)
    end
end

local function hudLoop()
    while true do
        updateSmoothCache()
        local viewer = smoothPlayerCache[VIEWER]
        if viewer then
            local w, h = hudmodem.getSize()
            
            -- Draw sleek border brackets and status banner
            drawHUDDecorations(w, h)
            
            local otherDimLine = 4 -- Start other dimension list below status banner
            local closestPlayer = nil
            local closestDist = 99999
            
            for name, p in pairs(smoothPlayerCache) do
                if name ~= VIEWER then
                    if p.dimension == viewer.dimension then
                        -- Draw on tracker display (same dimension)
                        local x, y, isOffScreen, symbol = worldToHud(viewer, p)
                        if x then
                            local playerColor = getDimColor(p.dimension)
                            bufferText(x, y, symbol, playerColor)

                            -- Draw the first letter of their username near the point (if on-screen)
                            if not isOffScreen then
                                local initial = string.sub(name, 1, 1):upper()
                                local initX = (x < w - 2) and (x + 1) or (x - 1)
                                if initX >= 3 and initX <= w - 2 then
                                    bufferText(initX, y, initial, colors.white)
                                end

                                -- Check distance to screen center (w/2, h/2) for lock-on
                                local cx, cy = w / 2, h / 2
                                local dist = math.sqrt((x - cx)^2 + (y - cy)^2)
                                if dist < lockOnThreshold and dist < closestDist then
                                    closestDist = dist
                                    closestPlayer = p
                                end
                            end
                        end
                    else
                        -- Draw as sidebar element (different dimension)
                        local shortDim = p.dimension:gsub("minecraft:", ""):gsub("the_", ""):gsub("^%l", string.upper)
                        local statusText = string.format("[%s] %s", shortDim, name)
                        local maxLen = (w - 2) - 4 + 1
                        bufferText(4, otherDimLine, statusText, getDimColor(p.dimension), maxLen)
                        otherDimLine = otherDimLine + 1
                    end
                end
            end

            -- Target Coordinate Overlay (bottom-left area inside borders)
            local logStartLine = h - 2
            if closestPlayer then
                local lockStr = ">> LOCK: " .. closestPlayer.name
                local maxLen = (w - 2) - 4 + 1

                bufferText(4, h - 5, lockStr, colors.yellow, maxLen)
                bufferText(4, h - 4, string.format("X: %.1f", closestPlayer.x), colors.yellow, maxLen)
                bufferText(4, h - 3, string.format("Y: %.1f", closestPlayer.y), colors.yellow, maxLen)
                bufferText(4, h - 2, string.format("Z: %.1f", closestPlayer.z), colors.yellow, maxLen)
                logStartLine = h - 6
            end

            -- Door Event Log (Bottom-Left)
            local now = os.clock()
            local activeLogs = {}
            for _, log in ipairs(doorLogs) do
                if now - log.time <= 3.0 then -- Display logs for 3 seconds
                    table.insert(activeLogs, log)
                end
            end
            for i, log in ipairs(activeLogs) do
                local text = log.text
                local maxLen = (w - 2) - 4 + 1
                local lineY = logStartLine - (#activeLogs - i)
                if lineY >= 3 then
                    bufferText(4, lineY, text, colors.orange, maxLen)
                end
            end

            -- Time & Weather Module (Bottom Right)
            if environment then
                local rawTime = environment.getTime and environment.getTime("ingame") or 0
                if type(rawTime) == "number" and rawTime > 24000 then
                    rawTime = rawTime % 24000
                end

                local timeStr = textutils.formatTime(rawTime, true)
                local weatherStr = "Clear"
                if environment.isThunder and environment.isThunder() then
                    weatherStr = "Thunder"
                elseif environment.isRaining and environment.isRaining() then
                    weatherStr = "Rain"
                end

                local infoLine1 = "TIME: " .. timeStr
                local infoLine2 = "WX: " .. weatherStr

                -- Dynamically right-align strictly inside frame border (column w - 2)
                local maxRightX = w - 2
                local x1 = maxRightX - #infoLine1 + 1
                local x2 = maxRightX - #infoLine2 + 1

                if x1 >= 3 then bufferText(x1, h - 3, infoLine1, colors.lightBlue) end
                if x2 >= 3 then bufferText(x2, h - 2, infoLine2, colors.lightBlue) end
            end

            -- Perform differential rendering directly on the HUD glasses
            renderDiff()
        end
        sleep(0.03)
    end
end

local function modemListener()
    while true do
        local _, _, channel, reply, message = os.pullEvent("modem_message")
        if type(message) == "table" and message.id then
            doors[message.id] = {
                pos = vector.new(message.x, message.y, message.z)
            }
        end
    end
end

parallel.waitForAll(
    discoverDoors,
    scanPlayers,
    updateComputers,
    hudLoop,
    modemListener
)
