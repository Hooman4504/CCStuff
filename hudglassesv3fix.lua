------------------------------------------------------------
-- Advanced Peripherals 0.8.2a
-- Smart Glasses 3D HUD: Coordinates, Environment & Stats
------------------------------------------------------------

local monitor = smartglasses.modules.overlay
local playerz = peripheral.find("player_detector")
local envDetector = peripheral.find("environment_detector")
local keyboard = smartglasses.modules.keyboard

local multidimspyallowed = false
local allowedwearerIsWearing = false
local hudVisible = true -- Toggle state
local lastHudVisible = true

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

-- Generate a visual health bar string
local function getHealthBar(current, maxHealth, barLength)
  barLength = barLength or 10
  current = math.max(0, math.min(current or 0, maxHealth or 20))
  maxHealth = math.max(1, maxHealth or 20)
  
  local filledLength = math.floor((current / maxHealth) * barLength + 0.5)
  local emptyLength = barLength - filledLength
  
  local bar = "["
  for i = 1, filledLength do bar = bar .. "█" end
  for i = 1, emptyLength do bar = bar .. "░" end
  bar = bar .. "]"
  return bar
end

-- Tables to keep track of active elements
local activeTexts = {}
local playerListBg = nil
local envBg = nil
local envTexts = {}

-- Stats panel variables
local statsBg = nil
local statsTexts = {}
local selectedPlayerIndex = 1
local statusTextObj = nil

-- Helper to completely clear out UI elements and canvas when toggled off
local function clearUIElements()
  if playerListBg and playerListBg.delete then pcall(function() playerListBg.delete() end) playerListBg = nil end
  if envBg and envBg.delete then pcall(function() envBg.delete() end) envBg = nil end
  if statsBg and statsBg.delete then pcall(function() statsBg.delete() end) statsBg = nil end
  
  for _, el in pairs(activeTexts) do if el.delete then pcall(function() el.delete() end) end end
  activeTexts = {}
  
  for _, el in pairs(envTexts) do if el.delete then pcall(function() el.delete() end) end end
  envTexts = {}
  
  for _, el in pairs(statsTexts) do if el.delete then pcall(function() el.delete() end) end end
  statsTexts = {}

  -- Force clear the canvas overlay completely once
  monitor.clear()
end

monitor.clear()

local function mainLoop()
  while true do
    if allowedwearerIsWearing == false then
      print("invalid permissions. returning.")
      return
    end
    
    os.sleep(0.1)

    -- Detect toggle state changes so we only clear ONCE when turning off
    if hudVisible ~= lastHudVisible then
      lastHudVisible = hudVisible
      if not hudVisible then
        clearUIElements()
      end
    end

    -- Fetch fresh wearer coordinates every tick for accurate distance calculation
    local wearerData = nil
    if actualWearerName then
      wearerData = playerz.getPlayer(actualWearerName)
    end

    -- Update Top-Right Status Indicator (Always visible regardless of HUD toggle)
    local statusStr = hudVisible and "HUD: ENABLED" or "HUD: DISABLED"
    if not statusTextObj then
      statusTextObj = monitor.createText({
        gui = false,
        relativePosition = true,
        relativeRotation = true,
        rotY = -10,
        center = true,
        x = 4.2,
        y = 2.2,
        z = -3,
        fontSize = 0.02,
        content = statusStr,
        shadow = true
      })
    else
      statusTextObj.setContent(statusStr)
      statusTextObj.setX(4.2)
      statusTextObj.setY(2.2)
      statusTextObj.setZ(-3)
    end

    -- If HUD is disabled, skip rendering the rest of the UI
    if not hudVisible then
      goto continue
    end
    
    local list = playerz.getOnlinePlayers()
    local currentPlayers = {}
    local playerCount = #list

    -- Keep selection index in bounds
    if playerCount > 0 then
      selectedPlayerIndex = math.max(1, math.min(selectedPlayerIndex, playerCount))
    else
      selectedPlayerIndex = 1
    end

    -- 1. Manage scaling background rectangle for the player list (Left 3D Panel at Y = -1.35)
    local totalLines = playerCount + 1
    local bgHeight = math.max(1.5, (totalLines * 0.4) + 0.4)
    if playerCount > 0 then
      if playerListBg then
        playerListBg.setSizeY(bgHeight)
        playerListBg.setY(-1.35)
      else
        playerListBg = monitor.createRectangle({
          gui = false,
          relativePosition = true,
          relativeRotation = true,
          rotY = 10,
          x = -3.5,
          y = -1.35,
          z = -3,
          sizeX = 4,
          sizeY = bgHeight,
          color = 0x000000,
          opacity = 0.5
        })
      end
    else
      if playerListBg and playerListBg.delete then
        pcall(function() playerListBg.delete() end)
        playerListBg = nil
      end
    end

    -- Draw Title Header for Player Panel
    if not activeTexts["__title__"] then
      activeTexts["__title__"] = monitor.createText({
        gui = false,
        relativePosition = true,
        relativeRotation = true,
        rotY = 10,
        center = true,
        x = -3.5,
        y = -0.25,
        z = -3,
        fontSize = 0.02,
        content = "--- PLAYERS ---",
        shadow = true
      })
    else
      activeTexts["__title__"].setX(-3.5)
      activeTexts["__title__"].setY(-0.25)
      activeTexts["__title__"].setZ(-3)
    end

    -- 2. Update player coordinate texts (Left 3D Panel)
    for i, plr in ipairs(list) do
      currentPlayers[plr] = true
      
      local player = playerz.getPlayer(plr)
      if player then
        local x = floor(player.x)
        local y = floor(player.y)
        local z = floor(player.z)
        
        local prefix = (i == selectedPlayerIndex) and "> " or "  "
        local contentText = string.format("%s%s x:%d y:%d z:%d", prefix, plr, x, y, z)

        local yPos = -0.65 - ((i - 1) * 0.4)

        if activeTexts[plr] then
          activeTexts[plr].setContent(contentText)
          activeTexts[plr].setX(-3.5)
          activeTexts[plr].setY(yPos)
          activeTexts[plr].setZ(-3)
        else
          activeTexts[plr] = monitor.createText({
            gui = false,
            relativePosition = true,
            relativeRotation = true,
            rotY = 10,
            center = true,
            x = -3.5,
            y = yPos,
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
      if plr ~= "__title__" and not currentPlayers[plr] then
        if element.delete then
          pcall(function() element.delete() end)
        end
        activeTexts[plr] = nil
      end
    end

    -- 3. Selected Player Statistics Panel (Stat text starting at Y = 2.4)
    if playerCount > 0 and list[selectedPlayerIndex] then
      local selectedName = list[selectedPlayerIndex]
      local targetData = playerz.getPlayer(selectedName)
      
      if targetData then
        local statDim = tostring(targetData.dimension or "Unknown"):gsub("minecraft:", "")
        
        -- Calculate distance from wearer
        local distStr = "N/A"
        if wearerData and wearerData.x and targetData.x then
          local dx = targetData.x - wearerData.x
          local dy = targetData.y - wearerData.y
          local dz = targetData.z - wearerData.z
          distStr = string.format("%.1f blocks", math.sqrt(dx*dx + dy*dy + dz*dz))
        end

        local currentHealth = targetData.health or 20
        local maxHealth = targetData.maxHealth or 20
        local healthBar = getHealthBar(currentHealth, maxHealth, 10)

        local statStats = {
          "--- PLAYER STATS ---",
          "Name: " .. selectedName,
          string.format("HP: %s (%d/%d)", healthBar, floor(currentHealth), floor(maxHealth)),
          string.format("Dist: %s", distStr),
          string.format("Pos: %d, %d, %d", floor(targetData.x), floor(targetData.y), floor(targetData.z)),
          "Dim: " .. statDim
        }

        local statsBgHeight = (#statStats * 0.35) + 0.3

        if not statsBg then
          statsBg = monitor.createRectangle({
            gui = false,
            relativePosition = true,
            relativeRotation = true,
            rotY = 10,
            x = -3.5,
            y = 2.0,
            z = -3,
            sizeX = 4,
            sizeY = statsBgHeight,
            color = 0x000000,
            opacity = 0.5
          })
        else
          statsBg.setSizeY(statsBgHeight)
          statsBg.setY(2.0)
        end

        for idx, line in ipairs(statStats) do
          local sY = 2.4 - ((idx - 1) * 0.35)
          if statsTexts[idx] then
            statsTexts[idx].setContent(line)
            statsTexts[idx].setX(-3.5)
            statsTexts[idx].setY(sY)
            statsTexts[idx].setZ(-3)
          else
            statsTexts[idx] = monitor.createText({
              gui = false,
              relativePosition = true,
              relativeRotation = true,
              rotY = 10,
              center = true,
              x = -3.5,
              y = sY,
              z = -3,
              fontSize = 0.02,
              content = line,
              shadow = true
            })
          end
        end
      end
    else
      if statsBg and statsBg.delete then
        pcall(function() statsBg.delete() end)
        statsBg = nil
      end
      for _, st in pairs(statsTexts) do
        if st.delete then pcall(function() st.delete() end) end
      end
      statsTexts = {}
    end

    -- 4. Environment Detector Panel (Right 3D Side Panel)
    if envDetector then
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

      biomeStr = tostring(biomeStr):gsub("minecraft:", "")
      dimStr = tostring(dimStr):gsub("minecraft:", "")

      local envData = {
        "--- ENVIRONMENT ---",
        "Time: " .. timeStr,
        "Weather: " .. weatherStr,
        "Biome: " .. biomeStr,
        "Dimension: " .. dimStr
      }

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

    ::continue::
  end
end

-- Key listener function to handle Up/Down arrow selection and toggle
local function keyListener()
  while true do
    local event, key = os.pullEvent("key")
    if key == keys.up or key == keys.w then
      selectedPlayerIndex = selectedPlayerIndex - 1
    elseif key == keys.down or key == keys.s then
      selectedPlayerIndex = selectedPlayerIndex + 1
    elseif key == keys.h or key == keys.v then
      hudVisible = not hudVisible
    end
  end
end

-- Run both loops concurrently using parallel API
parallel.waitForAll(mainLoop, keyListener)
