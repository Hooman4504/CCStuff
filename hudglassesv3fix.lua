------------------------------------------------------------
-- Advanced Peripherals 0.8.2a
-- Smart Glasses 3D HUD: Coordinates, Environment & Stats
--
-- Controls:
--   UP / W     Previous player
--   DOWN / S   Next player
--   H / V      Toggle HUD visibility
--
-- Layout note:
--   Edit the LAYOUT table below to adjust panel positions,
--   frame sizes, text positions, and rotations.
--   Positions are glasses-relative because relativePosition
--   is enabled. Rotations are in degrees.
------------------------------------------------------------

-----------------------------
-- CONFIGURATION
-----------------------------

local CONFIG = {
  updateInterval = 0.1,
  healthBarLength = 10,

  allowedWearers = {
    "Hooman4504",
    "burger_destroyer"
  }
}

-- Keep layout values together so they are easy to find/tweak.
-- Every panel has separate position and rotation tables.
local LAYOUT = {
  status = {
    position = { x = 4.2, y = 2.2, z = -3 },
    rotation = { x = 0, y = 350, z = 0 }, -- 350 degrees = -10 degrees
    gui = false,
    relativePosition = true,
    relativeRotation = true,
    center = true,
    fontSize = 0.02,
    color = 0xFFFFFF,
    shadow = true
  },

  players = {
    background = {
      position = { x = -3.5, y = -1.35, z = -3 },
      rotation = { x = 0, y = 10, z = 0 },
      gui = false,
      relativePosition = true,
      relativeRotation = true,
      sizeX = 4,
      minHeight = 1.5,
      heightPerLine = 0.4,
      heightPadding = 0.4,
      color = 0x000000,
      opacity = 0.5
    },

    title = {
      position = { x = -3.5, y = -0.25, z = -3 },
      rotation = { x = 0, y = 10, z = 0 },
      gui = false,
      relativePosition = true,
      relativeRotation = true,
      center = true,
      fontSize = 0.02,
      color = 0xFFFFFF,
      shadow = true
    },

    entries = {
      position = { x = -3.5, y = -0.65, z = -3 },
      rotation = { x = 0, y = 10, z = 0 },
      spacingY = -0.4,
      gui = false,
      relativePosition = true,
      relativeRotation = true,
      center = true,
      fontSize = 0.02,
      color = 0xFFFFFF,
      shadow = true
    }
  },

  stats = {
    background = {
      position = { x = -3.5, y = 2.0, z = -3 },
      rotation = { x = 0, y = 10, z = 0 },
      gui = false,
      relativePosition = true,
      relativeRotation = true,
      sizeX = 4,
      heightPerLine = 0.35,
      heightPadding = 0.3,
      color = 0x000000,
      opacity = 0.5
    },

    lines = {
      position = { x = -3.5, y = 2.4, z = -3 },
      rotation = { x = 0, y = 10, z = 0 },
      spacingY = -0.35,
      gui = false,
      relativePosition = true,
      relativeRotation = true,
      center = true,
      fontSize = 0.02,
      color = 0xFFFFFF,
      shadow = true
    }
  },

  environment = {
    background = {
      position = { x = 3.5, y = 0, z = -3 },
      rotation = { x = 0, y = 350, z = 0 }, -- 350 degrees = -10 degrees
      gui = false,
      relativePosition = true,
      relativeRotation = true,
      sizeX = 4,
      sizeY = 3,
      color = 0x000000,
      opacity = 0.5
    },

    lines = {
      position = { x = 3.5, y = 1.7, z = -3 },
      rotation = { x = 0, y = 350, z = 0 },
      spacingY = -0.35,
      gui = false,
      relativePosition = true,
      relativeRotation = true,
      center = true,
      fontSize = 0.02,
      color = 0xFFFFFF,
      shadow = true
    }
  }
}

-----------------------------
-- PERIPHERALS
-----------------------------

if not smartglasses then
  error("Smart Glasses module context was not found.")
end

local monitor = smartglasses.modules and smartglasses.modules.overlay
if not monitor then
  error("Overlay module not found on Smart Glasses.")
end

local playerz = peripheral.find("player_detector")
if not playerz then
  error("Player Detector peripheral not found.")
end

local envDetector = peripheral.find("environment_detector")

-----------------------------
-- SMALL HELPERS
-----------------------------

local function floor(value)
  return math.floor(value or 0)
end

local function safeCall(fn, ...)
  if type(fn) ~= "function" then
    return nil
  end

  local ok, result = pcall(fn, ...)
  if ok then
    return result
  end

  return nil
end

local function getHealthBar(current, maxHealth, barLength)
  barLength = barLength or CONFIG.healthBarLength
  current = math.max(0, math.min(current or 0, maxHealth or 20))
  maxHealth = math.max(1, maxHealth or 20)

  local filledLength = math.floor((current / maxHealth) * barLength + 0.5)
  local emptyLength = barLength - filledLength
  return "[" .. string.rep("█", filledLength) .. string.rep("░", emptyLength) .. "]"
end

local function stripMinecraftPrefix(value)
  return tostring(value or "Unknown"):gsub("minecraft:", "")
end

local function getPosition(layout, yOverride)
  return {
    x = layout.position.x,
    y = (yOverride ~= nil) and yOverride or layout.position.y,
    z = layout.position.z
  }
end

-- All positional/rotational adjustments go through this helper.
-- The rotX/rotY/rotZ fields are editable in the LAYOUT table.
local function applyTransform(object, layout, yOverride)
  local position = getPosition(layout, yOverride)
  local rotation = layout.rotation or {}

  object.setX(position.x)
  object.setY(position.y)
  object.setZ(position.z)

  object.setRotX(rotation.x or 0)
  object.setRotY(rotation.y or 0)
  object.setRotZ(rotation.z or 0)
end

-----------------------------
-- OBJECT VISIBILITY MANAGEMENT
-----------------------------

local hudVisible = true
local lastHudVisible = hudVisible

-- Every overlay object is registered here. Objects are not deleted when
-- hidden; setEnabled(false) hides them and lets the script reuse them later.
local objectRegistry = {}
local objectStates = {}

local function refreshObjectVisibility(state)
  local shouldEnable = state.wantedVisible and (hudVisible or state.alwaysVisible)

  if state.appliedEnabled ~= shouldEnable then
    state.object.setEnabled(shouldEnable)
    state.appliedEnabled = shouldEnable
  end
end

local function registerObject(object, alwaysVisible)
  local state = {
    object = object,
    wantedVisible = false,
    alwaysVisible = (alwaysVisible == true),
    appliedEnabled = nil
  }

  objectStates[object] = state
  objectRegistry[#objectRegistry + 1] = state

  -- Start hidden; visibility is always managed through setEnabled().
  object.setEnabled(false)
  state.appliedEnabled = false

  return object
end

local function setObjectVisible(object, visible)
  if not object then
    return
  end

  local state = objectStates[object]
  if not state then
    return
  end

  state.wantedVisible = (visible == true)
  refreshObjectVisibility(state)
end

local function refreshAllObjectVisibility()
  for _, state in pairs(objectRegistry) do
    refreshObjectVisibility(state)
  end
end

local function createText(layout, content, alwaysVisible)
  local position = getPosition(layout)
  local rotation = layout.rotation or {}

  local object = monitor.createText({
    enabled = false,
    gui = layout.gui,
    relativePosition = layout.relativePosition,
    relativeRotation = layout.relativeRotation,
    x = position.x,
    y = position.y,
    z = position.z,
    rotX = rotation.x or 0,
    rotY = rotation.y or 0,
    rotZ = rotation.z or 0,
    center = layout.center,
    fontSize = layout.fontSize,
    color = layout.color,
    content = content or "",
    shadow = layout.shadow
  })

  registerObject(object, alwaysVisible)
  applyTransform(object, layout)
  return object
end

local function createRectangle(layout, sizeY)
  local position = getPosition(layout)
  local rotation = layout.rotation or {}

  local object = monitor.createRectangle({
    enabled = false,
    gui = layout.gui,
    relativePosition = layout.relativePosition,
    relativeRotation = layout.relativeRotation,
    x = position.x,
    y = position.y,
    z = position.z,
    rotX = rotation.x or 0,
    rotY = rotation.y or 0,
    rotZ = rotation.z or 0,
    sizeX = layout.sizeX,
    sizeY = sizeY or layout.sizeY,
    color = layout.color,
    opacity = layout.opacity
  })

  registerObject(object, false)
  applyTransform(object, layout)
  return object
end

-----------------------------
-- RESOLVE AND CHECK WEARER
-----------------------------

local wearer = safeCall(smartglasses.getOwner)
local actualWearerName = nil

if wearer and wearer.uuid then
  local onlinePlayers = safeCall(playerz.getOnlinePlayers) or {}

  for _, playerName in pairs(onlinePlayers) do
    local playerData = safeCall(playerz.getPlayer, playerName)
    if playerData and playerData.uuid == wearer.uuid then
      actualWearerName = playerName
      break
    end
  end
end

local wearerAllowed = false
if actualWearerName then
  for _, allowedName in pairs(CONFIG.allowedWearers) do
    if actualWearerName == allowedName then
      wearerAllowed = true
      break
    end
  end
end

if not wearerAllowed then
  print("Invalid permissions. HUD stopped.")
  return
end

-----------------------------
-- OBJECT REFERENCES / CACHES
-----------------------------

local statusTextObj = createText(LAYOUT.status, "HUD: ENABLED", true)
setObjectVisible(statusTextObj, true)

local playerListBg = nil
local playerTitleText = nil
local activePlayerTexts = {} -- keyed by username; kept and disabled after logout

local statsBg = nil
local statsTexts = {} -- indexed by stats line number; kept and disabled if unused

local envBg = nil
local envTexts = {} -- indexed by environment line number

local selectedPlayerIndex = 1

-----------------------------
-- PLAYER LIST PANEL
-----------------------------

local function updatePlayerList(list)
  local layout = LAYOUT.players
  local backgroundLayout = layout.background
  local titleLayout = layout.title
  local entryLayout = layout.entries

  local playerCount = #list
  local currentRows = {}

  if playerCount > 0 then
    local backgroundHeight = math.max(
      backgroundLayout.minHeight,
      ((playerCount + 1) * backgroundLayout.heightPerLine) + backgroundLayout.heightPadding
    )

    if not playerListBg then
      playerListBg = createRectangle(backgroundLayout, backgroundHeight)
    end

    playerListBg.setSizes(backgroundLayout.sizeX, backgroundHeight)
    applyTransform(playerListBg, backgroundLayout)
    setObjectVisible(playerListBg, true)
  elseif playerListBg then
    setObjectVisible(playerListBg, false)
  end

  if not playerTitleText then
    playerTitleText = createText(titleLayout, "--- PLAYERS ---", false)
  end
  playerTitleText.setContent("--- PLAYERS ---")
  applyTransform(playerTitleText, titleLayout)
  setObjectVisible(playerTitleText, true)

  if playerCount > 0 then
    selectedPlayerIndex = math.max(1, math.min(selectedPlayerIndex, playerCount))
  else
    selectedPlayerIndex = 1
  end

  for index, playerName in ipairs(list) do
    local playerData = safeCall(playerz.getPlayer, playerName)

    if playerData then
      currentRows[playerName] = true

      local prefix = (index == selectedPlayerIndex) and "> " or "  "
      local content = string.format(
        "%s%s x:%d y:%d z:%d",
        prefix,
        playerName,
        floor(playerData.x),
        floor(playerData.y),
        floor(playerData.z)
      )

      if not activePlayerTexts[playerName] then
        activePlayerTexts[playerName] = createText(entryLayout, content, false)
      end

      local rowY = entryLayout.position.y + ((index - 1) * entryLayout.spacingY)
      activePlayerTexts[playerName].setContent(content)
      applyTransform(activePlayerTexts[playerName], entryLayout, rowY)
      setObjectVisible(activePlayerTexts[playerName], true)
    end
  end

  -- Hide cached rows for players who are no longer online (do not delete them).
  for playerName, textObject in pairs(activePlayerTexts) do
    if not currentRows[playerName] then
      setObjectVisible(textObject, false)
    end
  end
end

-----------------------------
-- SELECTED PLAYER STATS PANEL
-----------------------------

local function updateStatsPanel(list, wearerData)
  local selectedName = list[selectedPlayerIndex]
  local targetData = selectedName and safeCall(playerz.getPlayer, selectedName)

  if not targetData then
    if statsBg then
      setObjectVisible(statsBg, false)
    end

    for _, textObject in pairs(statsTexts) do
      setObjectVisible(textObject, false)
    end
    return
  end

  local statDimension = stripMinecraftPrefix(targetData.dimension)

  local distanceString = "N/A"
  if wearerData and wearerData.x ~= nil and targetData.x ~= nil
      and wearerData.y ~= nil and targetData.y ~= nil
      and wearerData.z ~= nil and targetData.z ~= nil then
    local dx = targetData.x - wearerData.x
    local dy = targetData.y - wearerData.y
    local dz = targetData.z - wearerData.z
    distanceString = string.format("%.1f blocks", math.sqrt(dx * dx + dy * dy + dz * dz))
  end

  local currentHealth = targetData.health or 20
  local maxHealth = targetData.maxHealth or 20
  local lines = {
    "--- PLAYER STATS ---",
    "Name: " .. selectedName,
    string.format("HP: %s (%d/%d)", getHealthBar(currentHealth, maxHealth), floor(currentHealth), floor(maxHealth)),
    "Dist: " .. distanceString,
    string.format("Pos: %d, %d, %d", floor(targetData.x), floor(targetData.y), floor(targetData.z)),
    "Dim: " .. statDimension
  }

  local backgroundLayout = LAYOUT.stats.background
  local linesLayout = LAYOUT.stats.lines
  local backgroundHeight = (#lines * backgroundLayout.heightPerLine) + backgroundLayout.heightPadding

  if not statsBg then
    statsBg = createRectangle(backgroundLayout, backgroundHeight)
  end

  statsBg.setSizes(backgroundLayout.sizeX, backgroundHeight)
  applyTransform(statsBg, backgroundLayout)
  setObjectVisible(statsBg, true)

  for index, line in ipairs(lines) do
    if not statsTexts[index] then
      statsTexts[index] = createText(linesLayout, line, false)
    end

    local lineY = linesLayout.position.y + ((index - 1) * linesLayout.spacingY)
    statsTexts[index].setContent(line)
    applyTransform(statsTexts[index], linesLayout, lineY)
    setObjectVisible(statsTexts[index], true)
  end

  -- If the number of lines is changed later, disable any unused cached objects.
  for index, textObject in pairs(statsTexts) do
    if index > #lines then
      setObjectVisible(textObject, false)
    end
  end
end

-----------------------------
-- ENVIRONMENT PANEL
-----------------------------

local function updateEnvironmentPanel()
  if not envDetector then
    if envBg then
      setObjectVisible(envBg, false)
    end
    for _, textObject in pairs(envTexts) do
      setObjectVisible(textObject, false)
    end
    return
  end

  local rawTime = safeCall(envDetector.getTime) or 0
  if type(rawTime) == "number" then
    rawTime = math.floor(rawTime % 24000)
  end

  local timeString = tostring(rawTime)
  if textutils and textutils.formatTime and type(rawTime) == "number" then
    timeString = textutils.formatTime(rawTime, true)
  end

  local weatherString = "Clear"
  if safeCall(envDetector.isThundering) then
    weatherString = "Thunder"
  elseif safeCall(envDetector.isRaining) then
    weatherString = "Rain"
  end

  local biomeString = stripMinecraftPrefix(safeCall(envDetector.getBiome))
  local dimensionString = stripMinecraftPrefix(safeCall(envDetector.getDimension))

  local lines = {
    "--- ENVIRONMENT ---",
    "Time: " .. timeString,
    "Weather: " .. weatherString,
    "Biome: " .. biomeString,
    "Dimension: " .. dimensionString
  }

  local backgroundLayout = LAYOUT.environment.background
  local linesLayout = LAYOUT.environment.lines

  if not envBg then
    envBg = createRectangle(backgroundLayout, backgroundLayout.sizeY)
  end

  envBg.setSizes(backgroundLayout.sizeX, backgroundLayout.sizeY)
  applyTransform(envBg, backgroundLayout)
  setObjectVisible(envBg, true)

  for index, line in ipairs(lines) do
    if not envTexts[index] then
      envTexts[index] = createText(linesLayout, line, false)
    end

    local lineY = linesLayout.position.y + ((index - 1) * linesLayout.spacingY)
    envTexts[index].setContent(line)
    applyTransform(envTexts[index], linesLayout, lineY)
    setObjectVisible(envTexts[index], true)
  end

  for index, textObject in pairs(envTexts) do
    if index > #lines then
      setObjectVisible(textObject, false)
    end
  end
end

-----------------------------
-- MAIN UPDATE LOOP
-----------------------------

local function mainLoop()
  while true do
    local statusString = hudVisible and "HUD: ENABLED" or "HUD: DISABLED"
    statusTextObj.setContent(statusString)
    setObjectVisible(statusTextObj, true) -- status remains visible when the rest is hidden

    if hudVisible ~= lastHudVisible then
      lastHudVisible = hudVisible
      refreshAllObjectVisibility()
    end

    if hudVisible then
      local onlinePlayers = safeCall(playerz.getOnlinePlayers) or {}
      if type(onlinePlayers) ~= "table" then
        onlinePlayers = {}
      end

      local wearerData = actualWearerName and safeCall(playerz.getPlayer, actualWearerName) or nil

      updatePlayerList(onlinePlayers)
      updateStatsPanel(onlinePlayers, wearerData)
      updateEnvironmentPanel()
    end

    os.sleep(CONFIG.updateInterval)
  end
end

-----------------------------
-- KEYBOARD LISTENER
-----------------------------

local function keyListener()
  while true do
    local _, key = os.pullEvent("key")

    if key == keys.up or key == keys.w then
      selectedPlayerIndex = selectedPlayerIndex - 1
    elseif key == keys.down or key == keys.s then
      selectedPlayerIndex = selectedPlayerIndex + 1
    elseif key == keys.h or key == keys.v then
      hudVisible = not hudVisible
      refreshAllObjectVisibility()
    end
  end
end

-----------------------------
-- RUN
-----------------------------

parallel.waitForAll(mainLoop, keyListener)
