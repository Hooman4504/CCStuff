local environment = peripheral.find("environment_detector")
local detector = peripheral.find("player_detector")
local hudmodem = peripheral.find("hud_glasses")
local modemsussy = peripheral.wrap("left")

local activationdist = 9
local lerpFactor = 0.22 -- Adjust this to change smoothness (lower = smoother, higher = faster)

modemsussy.open(4504)

local VIEWER = "Hooman4504"

hudmodem.clear()

local playerCache = {}
local smoothPlayerCache = {}
local doors = {}

-- Define colors for different dimensions
local dimColors = {
    ["minecraft:overworld"] = colors.green,
    ["minecraft:the_nether"] = colors.red,
    ["minecraft:the_end"] = colors.purple,
}

local function getDimColor(dim)
    return dimColors[dim] or colors.white
end

local function distcalcT3(pos, plr)
    local center = pos
    local half = activationdist / 2
    local halfvector = vector.new(half, half, half)

    local minpos = center - halfvector
    local maxpos = center + halfvector
    return detector.isPlayerInCoords(minpos, maxpos, plr)
end

local function drawText(x, y, text, color)
    hudmodem.setCursorPos(x, y)
    hudmodem.setTextColor(color or colors.white)
    hudmodem.write(text)
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
    
    local marginX = 2
    local marginY = 1
    
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
    
    edgeX = math.max(1, math.min(w, edgeX))
    edgeY = math.max(1, math.min(h, edgeY))
    
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

    local isOffScreen = isBehind or (screenX < 1 or screenX > w or screenY < 1 or screenY > h)

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
        for name, p in pairs(playerCache) do
            for id, door in pairs(doors) do
                if distcalcT3(door.pos, p.name) then
                    modemsussy.transmit(4504, 4505, {type = "open", id = id})
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
            hudmodem.clear()
            
            local otherDimLine = 1
            
            for name, p in pairs(smoothPlayerCache) do
                if name ~= VIEWER then
                    if p.dimension == viewer.dimension then
                        -- Draw on tracker display (same dimension)
                        local x, y, isOffScreen, symbol = worldToHud(viewer, p)
                        if x then
                            local playerColor = getDimColor(p.dimension)
                            drawText(x, y, symbol, playerColor)
                        end
                    else
                        -- Draw as sidebar element (different dimension)
                        local shortDim = p.dimension:gsub("minecraft:", ""):gsub("the_", ""):gsub("^%l", string.upper)
                        local statusText = string.format("[%s] %s", shortDim, name)
                        drawText(1, otherDimLine, statusText, getDimColor(p.dimension))
                        otherDimLine = otherDimLine + 1
                    end
                end
            end
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
