local environment = peripheral.find("environment_detector")
local detector = peripheral.find("player_detector")
local hudmodem = peripheral.find("hud_glasses")
local modemsussy = peripheral.wrap("left")

local activationdist = 9

modemsussy.open(4504)

local VIEWER = "Hooman4504"

local playerCache = {}
local previous = {}
local active = {}
local doors = {}

local function distcalcT3(pos,plr)
  --this is 100% nessescary
  local center = pos
  local half = activationdist/2
  local halfvector = vector.new(half,half,half)

  local minpos = center - halfvector
  local maxpos = center + halfvector
  return detector.isPlayerInCoords(minpos,maxpos,plr)
end

local function clearPrevious()
    for _,v in pairs(previous) do
        hudmodem.setCursorPos(
            v.x,
            v.y
        )
        hudmodem.write(
            string.rep(
                " ",
                v.len
            )
        )
    end
    previous = {}
end

local function worldToHud(viewer,target)
    local dx = target.x - viewer.x
    local dy = target.y - viewer.y
    local dz = target.z - viewer.z
    local yaw =
        math.rad(
            viewer.yaw or 0
        )
    local pitch =
        math.rad(
            viewer.pitch or 0
        )
    -- yaw
    local cx =
        dx*math.cos(yaw)
        -
        dz*math.sin(yaw)
    local cz =
        dx*math.sin(yaw)
        +
        dz*math.cos(yaw)
    -- pitch
    local cy =
        dy*math.cos(pitch)
        -
        cz*math.sin(pitch)
    cz =
        dy*math.sin(pitch)
        +
        cz*math.cos(pitch)

    if cz <= 0 then
        return nil
    end
    local w,h =
        hudmodem.getSize()
    local fov = 28
    local x =
        math.floor(
            w/2 +
            (cx/cz)*fov
        )
    local y =
        math.floor(
            h/2 -
            (cy/cz)*fov
        )
    if x < 1 or x > w
    or y < 1 or y > h then
        return nil
    end
  target.y = target.y + 1.6
    return x,y
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

clearPrevious()

local viewer =
detector.getPlayer(
VIEWER
)

if viewer then

for name,p in pairs(playerCache) do
  if name ~= VIEWER then
          local x,y = worldToHud(viewer,p)
          if x then
            local txt ="• "..name
            hudmodem.setCursorPos(x,y)
            hudmodem.write(txt)
            previous[name] = {
              x=x,
              y=y,
              len=#txt
            }
          end
          end
        end
      end
      sleep(0.02)
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
