------------------------------------------------------------
-- Advanced Peripherals 0.8.2a
-- Smart Glasses 2D HUD: Coordinates, Environment & Stats
------------------------------------------------------------

local monitor = smartglasses.modules.overlay
local playerz = peripheral.find("player_detector")
local envDetector = peripheral.find("environment_detector")

local multidimspyallowed = false
local allowedwearerIsWearing = false
local hudVisible = true

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

-- 2. Validate allowed wearers
if actualWearerName then
  for _, v in pairs(allowedwearers) do
    if actualWearerName == v then
      allowedwearerIsWearing = true
      break
    end
  end
end

-- 3. Check dimension permissions
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

-- Health bar generator
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

-- Persistent UI Element References
local activeTexts = {}
local playerListBg = nil
local envBg = nil
local envTexts = {}
local statsBg = nil
local statsTexts = {}
local selectedPlayerIndex = 1
local statusTextObj = nil

monitor.clear()

-- Create static UI objects once upon startup
local function initUI()
  -- Status Indicator (Top Right)
  statusTextObj = monitor.createText({
    gui = true,
    x = 300,
    y = 10,
    content = "HUD: ENABLED",
    shadow = true
  })

  -- Environment Background (Top Right Area)
  envBg = monitor.createRectangle({
    gui = true,
    x = 280,
    y = 30,
    width = 140,
    height = 95,
    color = 0x000000,
    opacity = 0.5
  })

  for i = 1, 5 do
    envTexts[i] = monitor.createText({
      gui = true,
      x = 290,
      y = 35 + ((i - 1) * 16),
      content = "",
      shadow = true
    })
  end
end

initUI()

-- Helper to set visibility of all elements when toggling HUD
local function setHudElementsVisible(visible)
  local alpha = visible and 0.5 or 0
  local textAlpha = visible and colors.white or 0x00000000

  if playerListBg then playerListBg.setOpacity(alpha) end
  if envBg then envBg.setOpacity(alpha) end
  if statsBg then statsBg.setOpacity(alpha) end

  if activeTexts["__title__"] then activeTexts["__title__"].setVisible(visible) end
  for _, el in pairs(activeTexts) do if el.setVisible then el.setVisible(visible) end end
  for _, el in pairs(envTexts) do if el.setVisible then el.setVisible(visible) end end
  for _, el in pairs(statsTexts) do if el.setVisible then el.setVisible(visible) end end
end

local function mainLoop()
  while true do
    if allowedwearerIsWearing == false then
      print("invalid permissions. returning.")
      return
    end
    
    os.sleep(0.1)

    -- Update Top-Right Status Indicator
    if statusTextObj then
      statusTextObj.setContent(hudVisible and "HUD: ENABLED" or "HUD: DISABLED")
    end

    setHudElementsVisible(hudVisible)
    if not hudVisible then
      goto continue
    end

    -- Fetch wearer position for distance calculation
    local wearerData = nil
    if actualWearerName then
      wearerData = playerz.getPlayer(actualWearerName)
    end
    
    local list = playerz.getOnlinePlayers()
    local currentPlayers = {}
    local playerCount = #list

    if playerCount > 0 then
      selectedPlayerIndex = math.max(1, math.min(selectedPlayerIndex, playerCount))
    else
      selectedPlayerIndex = 1
    end

    -- 1. Player List Background (Left Side, Screen Space)
    local bgHeight = math.max(40, ((playerCount + 1) * 20) + 10)
    if playerCount > 0 then
      if playerListBg then
        playerListBg.setHeight(bgHeight)
        playerListBg.setOpacity(0.5)
      else
        playerListBg = monitor.createRectangle({
          gui = true,
          x = 10,
          y = 120,
          width = 160,
          height = bgHeight,
          color = 0x000000,
          opacity = 0.5
        })
      end
    else
      if playerListBg then playerListBg.setOpacity(0) end
    end

    -- Player List Title Header
    if not activeTexts["__title__"] then
      activeTexts["__title__"] = monitor.createText({
        gui = true,
        x = 20,
        y = 130,
        content = "--- PLAYERS ---",
        shadow = true
      })
    else
      activeTexts["__title__"].setVisible(true)
      activeTexts["__title__"].setContent("--- PLAYERS ---")
    end

    -- 2. Player Coordinates Text Elements
    for i, plr in ipairs(list) do
      currentPlayers[plr] = true
      local player = playerz.getPlayer(plr)
      if player then
        local x = floor(player.x)
        local y = floor(player.y)
        local z = floor(player.z)
        
        local prefix = (i == selectedPlayerIndex) and "> " or "  "
        local contentText = string.format("%s%s %d,%d,%d", prefix, plr, x, y, z)
        local yPos = 130 + (i * 20)

        if activeTexts[plr] then
          activeTexts[plr].setVisible(true)
          activeTexts[plr].setContent(contentText)
          activeTexts[plr].setY(yPos)
        else
          activeTexts[plr] = monitor.createText({
            gui = true,
            x = 20,
            y = yPos,
            content = contentText,
            shadow = true
          })
        end
      end
    end

    -- Hide offline players' text
    for plr, element in pairs(activeTexts) do
      if plr ~= "__title__" and not currentPlayers[plr] then
        if element.setVisible then element.setVisible(false) end
      end
    end

    -- 3. Selected Player Statistics Panel (Above Player List)
    if playerCount > 0 and list[selectedPlayerIndex] then
      local selectedName = list[selectedPlayerIndex]
      local targetData = playerz.getPlayer(selectedName)
      
      if targetData then
        local statDim = tostring(targetData.dimension or "Unknown"):gsub("minecraft:", "")
        local distStr = "N/A"
        if wearerData and wearerData.x and targetData.x then
          local dx = targetData.x - wearerData.x
          local dy = targetData.y - wearerData.y
          local dz = targetData.z - wearerData.z
          distStr = string.format("%.1f blk", math.sqrt(dx*dx + dy*dy + dz*dz))
        end

        local currentHealth = targetData.health or 20
        local maxHealth = targetData.maxHealth or 20
        local healthBar = getHealthBar(currentHealth, maxHealth, 8)

        local statStats = {
          "--- STATS ---",
          "Name: " .. selectedName,
          string.format("HP: %s", healthBar),
          string.format("Dist: %s", distStr),
          string.format("Dim: %s", statDim)
        }

        if not statsBg then
          statsBg = monitor.createRectangle({
            gui = true,
            x = 10,
            y = 10,
            width = 160,
            height = 105,
            color = 0x000000,
            opacity = 0.5
          })
        else
          statsBg.setOpacity(0.5)
        end

        for idx, line in ipairs(statStats) do
          local sY = 18 + ((idx - 1) * 16)
          if statsTexts[idx] then
            statsTexts[idx].setVisible(true)
            statsTexts[idx].setContent(line)
          else
            statsTexts[idx] = monitor.createText({
              gui = true,
              x = 20,
              y = sY,
              content = line,
              shadow = true
            })
          end
        end
      end
    else
      if statsBg then statsBg.setOpacity(0) end
      for _, st in pairs(statsTexts) do
        if st.setVisible then st.setVisible(false) end
      end
    end

    -- 4. Environment Detector Panel
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
      
      local biomeStr = tostring(envDetector.getBiome and envDetector.getBiome() or "Unknown"):gsub("minecraft:", "")
      local dimStr = tostring(envDetector.getDimension and envDetector.getDimension() or "Unknown"):gsub("minecraft:", "")

      local envData = {
        "--- ENVIRONMENT ---",
        "Time: " .. timeStr,
        "Weather: " .. weatherStr,
        "Biome: " .. biomeStr,
        "Dim: " .. dimStr
      }

      for idx, textLine in ipairs(envData) do
        if envTexts[idx] then
          envTexts[idx].setContent(textLine)
        end
      end
    end

    ::continue::
  end
end

-- Key listener function
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

parallel.waitForAll(mainLoop, keyListener)
