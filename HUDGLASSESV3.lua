------------------------------------------------------------
-- Advanced Peripherals 0.8.2a
-- Smart Glasses but better
--
-- Required:
--   Smart Glasses (obviously)
--   Overlay Module
--   Player Detector
------------------------------------------------------------

local monitor = smartglasses.modules.overlay
local playerz = peripheral.find("player_detector")

local multidimspyallowed = nil
local allowedwearerIsWearing = false

local allowedwearers = {
  "Hooman4504",
  "burger_destroyer"
}

local wearer = smartglasses.getOwner()
--^ this is a player/table, not a name

--upon testing, get Owner() and get Player() give different data tables

--testing for multidimspy/wearer blacklist
local wearplayer = playerz.getPlayer(wearer.uuid)
local ownerdim = wearplayer.dimension
if ownerdim ~= nil then
  multidimspyallowed = true
else
  multidimspyallowed = false
end

for i,v in pairs(allowedwearers) do
  if wearplayer.name == v then
    allowedwearIsWearing = true
  end
end

--floor func i guess
local function floor(value)
  local flooredval = math.floor(value)
  return flooredval
end

--self explanitory
local function poscalc(x,y,z)
  local plrx = floor(x)
  local plry = floor(y)
  local plrz = floor(z)
  return plrx,plry,plrz
end

--main loop
while true do
  
  if allowedwearerIsWearing == false then
    print("invalid permissions. returning.")
    return
  end
  
  os.sleep(1)
  monitor.clear()
  local list = playerz.getOnlinePlayers()
  for i, plr in pairs(list) do
    local player = playerz.getPlayer(plr)
    local x,y,z = poscalc(player.x,player.y,player.z)
    
    if multidimspyallowed == true then
      local playerdim = player.dimension
    end

    monitor.createText({
      gui = true,
      x = 30,
      y = i * 30,
      content = (plr.." x: "..x.." y: "..y.." z: "..z),
      shadow = true
    })
  end
end
