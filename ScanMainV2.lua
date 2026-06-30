local detector = peripheral.find("player_detector")
local hudmodem = peripheral.find("hud_glasses")
local modemsussy = peripheral.find("left")

local playerCache = {}
local active = {}

local arrows = {
    N="↑",
    E="→",
    S="↓",
    W="←"
}

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
            for _, target in ipairs(acquiredpcpos) do

                local inside =
                    detector.isPlayerInCoords(
                        target - vector.new(5,5,5),
                        target + vector.new(5,5,5),
                        name
                    )

                local id =
                    target.x.."|"..
                    target.y.."|"..
                    target.z

                if inside and not active[name..id] then
                    active[name..id] = true
                    modemsussy.transmit(
                        4504,
                        4505,
                        textutils.serialize({
                            type="entered",
                            player=name
                        })
                    )
                elseif not inside then
                    active[name..id] = nil
                end
            end
        end
        sleep(0.1)
    end
end

local function yawToDir(yaw)
    yaw = yaw % 360

    if yaw < 45 then return arrows.S
    elseif yaw < 135 then return arrows.W
    elseif yaw < 225 then return arrows.N
    elseif yaw < 315 then return arrows.E
    end

    return arrows.S
end

local function hudLoop()
    while true do
        hudmodem.clear()
        local y = 1
        for name,p in pairs(playerCache) do
            hudmodem.setCursorPos(1,y)
            hudmodem.write(
                string.format(
                    "%s %s %.0f %.0f %.0f",
                    yawToDir(p.yaw or 0),
                    name,
                    p.x,
                    p.y,
                    p.z
                )
            )
            y = y + 1
        end
        sleep(0.05)
    end
end

local function modemListener()
    while true do
        local _,_,channel,reply,msg =
            os.pullEvent("modem_message")
        if channel == 4504 then
            handleMessage(msg)
        end
    end
end

parallel.waitForAll(
    scanPlayers,
    updateComputers,
    hudLoop,
    modemListener
)
