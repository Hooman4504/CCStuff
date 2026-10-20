------------------------------------------------------------
-- Advanced Peripherals 0.8.2a
-- Smart Glasses coordinates display (UUID Workaround & Fixed)
------------------------------------------------------------

local monitor = smartglasses.modules.overlay
local playerz = peripheral.find("player_detector")

local multidimspyallowed = false
local allowedwearerIsWearing = false

local allowedwearers = {
  "Hooman4504",
  "burger_destroyer"
}

-- 1. Get owner data (UUID is reliable even if .name is bugged as "minecraft:Player")
local wearer = smartglasses.getOwner()
local actualWearerName = nil

if wearer and wearer.uuid then
  local onlinePlayers = playerz.getOnlinePlayers()
  for _, plrName in ipairs(onlinePlayers) do
    local pData = playerz.getPlayer(plrName)
    -- Match the online player's UUID with the glasses owner's UUID
    if pData and pData.uuid == wearer.uuid then
      actualWearerName = plrName
      break
    end
  end
end

-- 2. Validate if the resolved true username is allowed
if actualWearerName then
  for _, v in pairs(allowedwearers) do
    if actualWearerName == v then
      allowedwearIsWearing = true
      break
    end
  end
end

-- 3. Check dimension permissions using the verified name
if actualWearerName then
  local wearplayer = playerz.getPlayer(actualWearerName)
  if wearplayer and wearplayer.dimension ~= nil then
    multidimspyallowed = true
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
    currentPlayers[plr] = true
    
    local player = playerz.getPlayer(plr)
    if player then
      local x = floor(player.x)
      local y = floor(player.y)
      local z = floor(player.z)
      
      local contentText = string.format("%s x: %d y: %d z: %d", plr, x, y, z)

      if multidimspyallowed == true then
        local playerdim = player.dimension
      end

      -- Check if text element already exists for this player
      if activeTexts[plr] then
        -- Update existing element content and use individual setter methods
        activeTexts[plr].setContent(contentText)
        activeTexts[plr].setX(30)
        activeTexts[plr].setY(i * 30)
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
