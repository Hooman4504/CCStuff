local environment = peripheral.find("environment_detector")
local detector = peripheral.find("player_detector")
local hudmodem = peripheral.find("hud_glasses")
local modemsussy = peripheral.wrap("left")

local activationdist = 9

modemsussy.open(4504)

local VIEWER = "Hooman4504"

hudmodem.clear()

local playerCache = {}
local drawn = {}
local doors = {}

local function distcalcT3(pos, plr)
    -- This is 100% necessary
    local center = pos
    local half = activationdist / 2
    local halfvector = vector.new(half, half, half)

    local minpos = center - halfvector
    local maxpos = center + halfvector
    return detector.isPlayerInCoords(minpos, maxpos, plr)
end

local function drawText(x, y, text)
    local key = x .. ":" .. y
    if drawn[key] == text then
        return
    end
    drawn[key] = text
    hudmodem.setCursorPos(x, y)
    hudmodem.write(text)
end

local function worldToHud(viewer, target)
    -- World offset
    local dx = target.x - viewer.x
    local dy = (target.y + 1.6) - viewer.y
    local dz = target.z - viewer.z

    -- INVERSE camera rotation
    local yaw = math.rad(-(viewer.yaw or 0))
    local pitch = math.rad(-(viewer.pitch or 0))

    -- yaw (Negated sx to correct the flipped X-axis alignment)
    local sx = -(dx * math.cos(yaw) + dz * math.sin(yaw))
    local sz = -dx * math.sin(yaw) + dz * math.cos(yaw)

    -- pitch
    local sy = dy * math.cos(pitch) + sz * math.sin(pitch)
    sz = -dy * math.sin(pitch) + sz * math.cos(pitch)

    if sz <= 0.5 then
        return nil
    end

    local w, h = hudmodem.getSize()
    local fov = 24
    local screenX = math.floor(w / 2 + (sx / sz) * fov)
    local screenY = math.floor(h / 2 + (sy / sz) * fov)

    if screenX < 1 or screenX > w or screenY < 1 or screenY > h then
        return nil
    end

    return screenX, screenY
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
        local viewer = playerCache[VIEWER]
        if viewer then
            -- Clear the HUD screen once at the beginning of the frame update
            hudmodem.clear()
            drawn = {}
            for name, p in pairs(playerCache) do
                if name ~= VIEWER then
                    local x, y = worldToHud(viewer, p)
                    if x then
                        drawText(x, y, "•")
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
