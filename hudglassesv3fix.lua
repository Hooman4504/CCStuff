------------------------------------------------------------
-- Advanced Peripherals 0.8.2a
-- Smart Glasses 3D HUD: Coordinates, Environment & Stats
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

-- Stats panel variables
local statsBg = nil
local statsTexts = {}
local selectedPlayerIndex = 1

-- Main HUD loop combined with parallel key listener or non-blocking event handling
-- Using parallel to handle key presses cleanly alongside the update loop
local function mainLoop()
  while true do
    if allowedwearerIsWearing == false then
      print("invalid permissions. returning.")
      return
    end
    
    os.sleep(0.1)
    
    local list = playerz.getOnlinePlayers()
    local currentPlayers = {}
    local playerCount = #list

    -- Keep selection index in bounds
    if playerCount > 0 then
      selectedPlayerIndex = math.max(1, math.min(selectedPlayerIndex, playerCount))
    else
      selectedPlayerIndex = 1
    end

    -- 1. Manage scaling background rectangle for the player list (Left 3D Panel, moved down by 1.5)
    -- Added 1 extra line height for the title header
    local totalLines = playerCount + 1
    local bgHeight = math.max(1.5, (totalLines * 0.4) + 0.4)
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
          y = -1.5,
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

    -- Draw Title Header for Player Panel
    if not activeTexts["__title__"] then
      activeTexts["__title__"] = monitor.createText({
        gui = false,
        relativePosition = true,
        relativeRotation = true,
        rotY = 10,
        center = true,
        x = -3.5,
        y = -0.4, -- shifted down by 1.5
        z = -3,
        fontSize = 0.02,
        content = "--- PLAYERS ---",
        shadow = true
      })
    else
      activeTexts["__title__"].setX(-3.5)
      activeTexts["__title__"].setY(-0.4)
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
        
        -- Highlight selected player with arrows
        local prefix = (i == selectedPlayerIndex) and "> " or "  "
        local contentText = string.format("%s%s x:%d y:%d z:%d", prefix, plr, x, y, z)

        local yPos = -0.8 - ((i - 1) * 0.4) -- shifted down by 1.5

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
          element.delete()
        end
        activeTexts[plr] = nil
      end
    end

    -- 3. Selected Player Statistics Panel (Center/Bottom 3D Panel)
    if playerCount > 0 and list[selectedPlayerIndex] then
      local selectedName = list[selectedPlayerIndex]
      local targetData = playerz.getPlayer(selectedName)
      
      if targetData then
        local statDim = tostring(targetData.dimension or "Unknown"):gsub("minecraft:", "")
        local statStats = {
          "--- PLAYER STATS ---",
          "Name: " .. selectedName,
          string.format("Pos: %d, %d, %d", floor(targetData.x), floor(targetData.y), floor(targetData.z)),
          "Dim: " .. statDim,
          string.format("Pitch/Yaw: %.1f / %.1f", targetData.pitch or 0, targetData.yaw or 0)
        }

        if not statsBg then
          statsBg = monitor.createRectangle({
            gui = false,
            relativePosition = true,
            relativeRotation = true,
            rotY = 0,
            x = 0,
            y = -1.8,
            z = -3,
            sizeX = 4,
            sizeY = 2.5,
            color = 0x000000,
            opacity = 0.5
          })
        end

        for idx, line in ipairs(statStats) do
          local sY = -1.0 - ((idx - 1) * 0.35)
          if statsTexts[idx] then
            statsTexts[idx].setContent(line)
            statsTexts[idx].setX(0)
            statsTexts[idx].setY(sY)
            statsTexts[idx].setZ(-3)
          else
            statsTexts[idx] = monitor.createText({
              gui = false,
              relativePosition = true,
              relativeRotation = true,
              rotY = 0,
              center = true,
              x = 0,
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
      -- Remove stats panel if no players online
      if statsBg and statsBg.delete then
        statsBg.delete()
        statsBg = nil
      end
      for _, st in pairs(statsTexts) do
        if st.delete then st.delete() end
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
        weatherStr5 = "Rain"
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
  end
end

-- Key listener function to handle Up/Down arrow selection
local function keyListener()
  while true do
    local event, key = os.pullEvent("key")
    -- Arrow Up (keys.up) or W / Up mapping
    if key == keys.up or key == keys.w then
      selectedPlayerIndex = selectedPlayerIndex - 1
    -- Arrow Down (keys.down) or S / Down mapping
    elseif key == keys.down or key == keys.s then
      selectedPlayerIndex = selectedPlayerIndex + 1
    end
  end
end

-- Run both loops concurrently using parallel API
parallel.waitForAll(mainLoop, keyListener)
