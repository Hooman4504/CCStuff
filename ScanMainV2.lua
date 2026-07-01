local environment = peripheral.find("environment_detector")
local detector = peripheral.find("player_detector")
local hudmodem = peripheral.find("hud_glasses")
local modemsussy = peripheral.wrap("left")

local activationdist = 9

modemsussy.open(4504)

local VIEWER = "Hooman4504"

local doors = {}
local playerCache = {}
local active = {}

local function distcalcT3(pos,plr)
  --this is 100% nessescary
  --vec1 is plr
  local center = vec2
  local half = activationdist/2
  local halfvector = vector.new(half,half,half)

  local minpos = center - halfvector
  local maxpos = center + halfvector
  return detector.isPlayerInCoords(minpos,maxpos,plr)
end

local function worldToHud(viewer, target)
    local dx = target.x - viewer.x
    local dy = target.y - viewer.y
    local dz = target.z - viewer.z
    -- rotate around viewer yaw
    local yaw = math.rad(-(viewer.yaw or 0))
    local rx =
        dx * math.cos(yaw) -
        dz * math.sin(yaw)
    local rz =
        dx * math.sin(yaw) +
        dz * math.cos(yaw)
    if rz <= 0 then
        return nil -- behind player
    end
    local w,h = hudmodem.getSize()
    local scale = 20
    local screenX =
        math.floor(
            w/2 +
            (rx/rz)*scale
        )
    local screenY =
        math.floor(
            h/2 -
            (dy/rz)*scale
        )
    return screenX, screenY
end

local function discoverDoors()
    while true do
        modemsussy.transmit(
            4504,
            4505,
            "getpos"
        )
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
                    -- AP exposes additional info such as yaw/pitch
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
         local pos = vector.new(p.x,p.y,p.z)
            for id,door in pairs(doors) do
                if distcalcT3(door.pos,p.name) then
                    modemsussy.transmit(4504,4505,{type="open",id=id})
                end
            end
        end
        sleep(0.1)
    end
end

local function hudLoop()
    while true do
        hudmodem.clear()

        local y = 1
        for name,p in pairs(playerCache) do
            hudmodem.setCursorPos(1,y)
            hudmodem.write(
                string.format(
                    "%s %.0f %.0f %.0f",
                    name,
                    p.x,
                    p.y,
                    p.z
                )
            )
            y = y + 1
        end
        
        local viewer = detector.getPlayer(VIEWER)
        if viewer then
            for _,name in pairs(
                detector.getOnlinePlayers()
            ) do
                if name ~= VIEWER then
                    local p =
                        detector.getPlayer(name)
                    if p then
                        local x,y =
                            worldToHud(
                                viewer,
                                p
                            )
                        if x and y then
                            hudmodem.setCursorPos(
                                x,
                                y
                            )
                            hudmodem.write("•")
                            hudmodem.setCursorPos(
                                x+1,
                                y
                            )
                            hudmodem.write(
                                name
                            )
                        end
                    end
                end
            end
        end
        sleep(0.05)
    end
end

local function modemListener()
    while true do
        local _,_,channel,reply,message =
            os.pullEvent(
                "modem_message"
            )
        if type(message)=="table" and message.id then
            doors[message.id] = {
                pos = vector.new(
                    message.x,
                    message.y,
                    message.z
                )
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
