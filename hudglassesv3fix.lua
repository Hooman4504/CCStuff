------------------------------------------------------------
-- Advanced Peripherals 0.8.2a
-- Smart Glasses but better (Optimized & Fixed)
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

-- Safe check for wearer data
local wearplayer = wearer and playerz.getPlayer(wearer.uuid or wearer.name)
local ownerdim = wearplayer and wearplayer.dimension
if ownerdim ~= nil then
  multidimspyallowed = true
else
  multidimspyallowed = false
end

if wearplayer then
  for i, v in pairs(allowedwearers) do
    if wearplayer.name == v then
      allowedwearIsWearing = true
    end
  end
end

-- Floor function
local function floor(value)
  return math.floor(value)
end

-- Table to keep track of active text elements per player
local activeTexts = {}

-- Main loop
while true do
  
  if allowedwearerIsWearing == false then
    print("invalid permissions. returning.")
    return
  end
  
  os.sleep(1)
  
  local list = playerz.getOnlinePlayers()
  local currentPlayers = {}

  for i, plr in ipairs(list) do
    -- 'plr' from getOnlinePlayers() is already the clean string username, 
    -- bypassing any weird formatting from player.name
    currentPlayers[plr] = true
    
    local player = playerz.getPlayer(plr)
    if player then
      local x = floor(player.x)
      local y = floor(player.y)
      local z = floor(player.z)
      
      local contentText = string.wpformat and string.format("%s x: %d y: %d z: %d", plr, x, y, z) or (plr.." x: "..x.." y: "..y.." z: "..z)

      if multidimspyallowed == true then
        local playerdim = player.dimension
      end

      -- Check if text element already exists for this player
      if activeTexts[plr] then
        -- Update existing element using setContent instead of recreating it
        activeTexts[plr].setContent(contentText)
        activeTexts[plr].setPos(30, i * 30)
      else
        -- Create a new text element if it doesn't exist
        activeTexts[plr] = monitor.createText({
          gui = true,
          x = 30,
          y = i * 30,
          content = contentText,
          shadow = true
        })
      end
    end
  end

  -- Clean up elements for players who logged off
  for plr, element in pairs(activeTexts) do
    if not currentPlayers[plr] then
      if element.delete then
        element.delete()
      end
      activeTexts[plr] = nil
    end
  end
end
