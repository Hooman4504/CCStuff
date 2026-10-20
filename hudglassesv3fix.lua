------------------------------------------------------------
-- Advanced Peripherals 0.8.2a
-- Smart Glasses coordinates & environment panels (3D HUD)
------------------------------------------------------------

local monitor = smartglasses.modules.overlay
local playerz = peripheral.find("player_detector")
local envDetector = peripheral.find("environment_detector")

local multidimspyallowed = false
local allowedwearerIsWearing = false

local allowedwearers = {
  "Hooman4504",
  "burger_destroyer"
}

-- 1. Get owner data (UUID workaround for bugged .name)
local wearer = smartglasses.getOwner()
local actualWearerName = nil

if wearer and wearer.uuid then
  local onlinePlayers = playerz.getOnlinePlayers()
  for _, plrName in ipairs(onlinePlayers) do
    local pData = playerz.getPlayer(plrName)
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
      allowedwearerIsWearing = true
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

-- Tables to keep track of active elements
local activeTexts = {}
local playerListBg = nil
local envBg = nil
local envTexts = {}

-- Main loop
while true do
  
  if allowedwearerIsWearing == false then
    print("invalid permissions. returning.")
    return
  end
  
  os.sleep(0.1)
  
  local list = playerz.getOnlinePlayers()
  local currentPlayers = {}
  local playerCount = #list

  -- 1. Manage scaling background rectangle for the player list (Left 3D Panel)
  local bgHeight = math.max(1.5, (playerCount * 0.4) + 0.6)
  if playerCount > 0 then
    if playerListBg then
      playerListBg.setSizeY(bgHeight)
    else
      playerListBg = monitor.createRectangle({
        gui = false,
        relativePosition = true,
        relativeRotation = true,
        rotY = 10,
        x = -3.5,
        y = 0,
        z = -3,
        sizeX = 4,
        sizeY = bgHeight,
        color = 0x000000,
        opacity = 0.5
      })
    end
  else
    if playerListBg and playerListBg.delete then
      playerListBg.delete()
      playerListBg = nil
    end
  end

  -- 2. Update player coordinate texts (Left 3D Panel)
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
        activeTexts[plr].setContent(contentText)
        activeTexts[plr].setX(-3.5)
        activeTexts[plr].setY(1.1 - ((i - 1) * 0.4))
        activeTexts[plr].setZ(-3)
      else
        activeTexts[plr] = monitor.createText({
          gui = false,
          relativePosition = true,
          relativeRotation = true,
          rotY = 10,
          center = true,
          x = -3.5,
          y = 1.1 - ((i - 1) * 0.4),
          z = -3,
          fontSize = 0.02,
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

  -- 3. Environment Detector Panel (Right 3D Side Panel)
  if envDetector then
    -- Gather environment data safely & fix time formatting
    local rawTime = envDetector.getTime and envDetector.getTime() or 0
    if type(rawTime) == "number" then
      rawTime = math.floor(rawTime % 24000)
    end
    local timeStr = (textutils and textutils.formatTime) and textutils.formatTime(rawTime, true) or tostring(rawTime)
    
    local weatherStr = "Clear"
    if envDetector.isThundering and envDetector.isThundering() then
      weatherStr = "Thunder"
    elseif envDetector.isRaining and envDetector.isRaining() then
      weatherStr = "Rain"
    end
    
    local biomeStr = envDetector.getBiome and envDetector.getBiome() or "Unknown"
    local dimStr = envDetector.getDimension and envDetector.getDimension() or "Unknown"

    -- Clean up prefix namespace for cleaner look
    biomeStr = tostring(biomeStr):gsub("minecraft:", "")
    dimStr = tostring(dimStr):gsub("minecraft:", "")

    local envData = {
      "--- ENVIRONMENT ---",
      "Time: " .. timeStr,
      "Weather: " .. weatherStr,
      "Biome: " .. biomeStr,
      "Dimension: " .. dimStr
    }

    -- Create background box for env panel if it doesn't exist
    if not envBg then
      envBg = monitor.createRectangle({
        gui = false,
        relativePosition = true,
        relativeRotation = true,
        rotY = -10,
        x = 3.5,
        y = 0,
        z = -3,
        sizeX = 4,
        sizeY = 3,
        color = 0x000000,
        opacity = 0.5
      })
    end

    -- Update or create text lines for the environment panel
    for idx, textLine in ipairs(envData) do
      if envTexts[idx] then
        envTexts[idx].setContent(textLine)
        envTexts[idx].setX(3.5)
        envTexts[idx].setY(1.7 - ((idx - 1) * 0.35))
        envTexts[idx].setZ(-3)
      else
        envTexts[idx] = monitor.createText({
          gui = false,
          relativePosition = true,
          relativeRotation = true,
          rotY = -10,
          center = true,
          x = 3.5,
          y = 1.7 - ((idx - 1) * 0.35),
          z = -3,
          fontSize = 0.02,
          content = textLine,
          shadow = true
        })
      end
    end
  end
end
