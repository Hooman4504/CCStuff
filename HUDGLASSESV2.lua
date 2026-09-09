------------------------------------------------------------
-- Advanced Peripherals 0.8
-- Smart Glasses Entity ESP
--
-- Required:
--   Smart Glasses
--   Overlay Module
--   Environment Detector
--   Player Detector
--
-- scanEntities() is deliberately only called every 2 sec.
-- Overlay objects are updated continuously.
------------------------------------------------------------


------------------------------------------------------------
-- CONFIGURATION
------------------------------------------------------------

local SCAN_RANGE = 16
local SCAN_INTERVAL = 2

-- How frequently existing overlays are updated.
local UPDATE_INTERVAL = 0.05

-- Entity box size.
--
-- These are intentionally approximate because
-- scanEntities() does not provide entity bounding boxes.
local BOX_X = 0.7
local BOX_Y = 1.8
local BOX_Z = 0.7

-- Move the box upward so its bottom is approximately
-- at the entity's feet.
local BOX_Y_OFFSET = BOX_Y / 2

-- Text position above the entity.
local TEXT_Y_OFFSET = 0.5

-- Ignore tiny differences when determining whether an
-- entity is the wearer.
local PLAYER_ORIGIN_TOLERANCE = 0.05

-- Whether the ESP should render through blocks.
local DEPTH_TEST = false

-- Box transparency.
local BOX_OPACITY = 0.20

-- Colors.
local PLAYER_COLOR = 0x00FFFF
local HOSTILE_COLOR = 0xFF0000
local PASSIVE_COLOR = 0x00FF00
local DEFAULT_COLOR = 0xFFFFFF


------------------------------------------------------------
-- PERIPHERALS
------------------------------------------------------------

if not smartglasses then
    error("Smart Glasses not found.")
end


local overlay = smartglasses.modules["advancedperipherals:overlay"]

if not overlay then
    error("Overlay Module not installed.")
end


local environmentDetector = peripheral.find("environment_detector")

if not environmentDetector then
    error("Environment Detector not found.")
end


local playerDetector = peripheral.find("player_detector")

if not playerDetector then
    error("Player Detector not found.")
end


------------------------------------------------------------
-- STATE
------------------------------------------------------------

-- Latest successful scan.
--
-- entities[uuid] = entity
local entities = {}

-- Overlay objects.
--
-- overlays[uuid] = {
--     box = BoxObject,
--     name = TextObject,
--     coords = TextObject
-- }
local overlays = {}

-- UUID of the player wearing the glasses.
local wearerUUID = nil

-- Absolute world position of the scanner origin.
--
-- This is calculated from:
--
--     playerWorldPosition
--                  -
--     player's relative scan position
--
local scannerOrigin = nil

-- True after at least one successful scan.
local hasScan = false


------------------------------------------------------------
-- UTILITY
------------------------------------------------------------

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)

    if not ok then
        return nil
    end

    return result
end


local function round(number)
    return math.floor(number + 0.5)
end


local function distanceSquared(x, y, z)
    return x * x + y * y + z * z
end


------------------------------------------------------------
-- FIND THE GLASSES WEARER
------------------------------------------------------------
--
-- scanEntities() gives us all nearby entities.
--
-- The wearer appears at approximately:
--
--     x = 0
--     z = 0
--
-- and their UUID is also available.
--
-- We use getOnlinePlayers() to make sure the entity
-- is actually a player before accepting it as the wearer.
------------------------------------------------------------

local function findWearer(scanResult)

    local onlinePlayers = safeCall(
        playerDetector.getOnlinePlayers
    )

    if not onlinePlayers then
        return nil, nil
    end


    -- Convert the online-player list into a UUID lookup.
    local onlineUUIDs = {}

    for _, players in pairs(onlinePlayers) do
	local player = playerDetector.getPlayer(players)
	local uuid = player.uuid
        onlineUUIDs[uuid] = true
    end


    local bestEntity = nil
    local bestDistance = math.huge


    for _, entity in pairs(scanResult) do

        if entity.uuid and onlineUUIDs[entity.uuid] then

            local x = entity.x or math.huge
            local z = entity.z or math.huge

            local distance = distanceSquared(
                x,
                0,
                z
            )

            if distance < bestDistance then
                bestDistance = distance
                bestEntity = entity
            end

        end

    end


    if not bestEntity then
        return nil, nil
    end


    -- Make sure the player really is at the scanner origin.
    if math.sqrt(bestDistance) > PLAYER_ORIGIN_TOLERANCE then
        return nil, nil
    end


    local player = safeCall(
        playerDetector.getPlayer,
        bestEntity.uuid
    )

    if not player then
        return nil, nil
    end


    return bestEntity, player
end


------------------------------------------------------------
-- UPDATE SCANNER ORIGIN
------------------------------------------------------------

local function updateScannerOrigin(scanResult)

    local localPlayer, player = findWearer(scanResult)

    if not localPlayer or not player then
        return false
    end


    wearerUUID = localPlayer.uuid


    --------------------------------------------------------
    -- The scanner coordinates are relative.
    --
    -- Example:
    --
    -- Player Detector:
    --     player.x = 100
    --     player.y = 64
    --     player.z = 200
    --
    -- Scanner sees player:
    --     x = 0
    --     y = -1.62
    --     z = 0
    --
    -- Therefore:
    --
    -- scanner origin:
    --     x = 100
    --     y = 65.62
    --     z = 200
    --
    -- This automatically compensates for the difference
    -- between the player's position and the scanner origin.
    --------------------------------------------------------

    scannerOrigin = {
        x = player.x - localPlayer.x,
        y = player.y - localPlayer.y,
        z = player.z - localPlayer.z,

        dimension = player.dimension
    }


    return true
end


------------------------------------------------------------
-- CONVERT RELATIVE -> WORLD COORDINATES
------------------------------------------------------------

local function getWorldPosition(entity)

    if not scannerOrigin then
        return nil
    end


    return {
        x = scannerOrigin.x + entity.x,
        y = scannerOrigin.y + entity.y,
        z = scannerOrigin.z + entity.z
    }
end


------------------------------------------------------------
-- ENTITY COLOR
------------------------------------------------------------

local function getEntityColor(entity)

    -- Player
    if entity.uuid == wearerUUID then
        return PLAYER_COLOR
    end


    -- Hostile entities can be identified through tags
    -- if the scanner supplies them.
    --
    -- This is deliberately conservative; anything we
    -- don't recognize gets the default color.
    if entity.tags then

        for _, tag in pairs(entity.tags) do

            if tag == "minecraft:hostile" then
                return HOSTILE_COLOR
            end

        end

    end


    return DEFAULT_COLOR
end


------------------------------------------------------------
-- CREATE ENTITY OVERLAY
------------------------------------------------------------

local function createOverlay(uuid, entity, position)

    --------------------------------------------------------
    -- Box
    --------------------------------------------------------

    local box = overlay.createBox({

        x = position.x,

        y = position.y + BOX_Y_OFFSET,

        z = position.z,


        sizeX = BOX_X,
        sizeY = BOX_Y,
        sizeZ = BOX_Z,


        color = getEntityColor(entity),

        opacity = BOX_OPACITY,


        -- IMPORTANT:
        -- These are world coordinates, not coordinates
        -- relative to the player's head.
        relativePosition = false,

        depthTest = DEPTH_TEST,

        culling = false
    })


    --------------------------------------------------------
    -- Name
    --------------------------------------------------------

    local name = overlay.createText({

        x = position.x,

        y = position.y + BOX_Y + TEXT_Y_OFFSET,

        z = position.z,


        content = entity.name or "Unknown",

        color = getEntityColor(entity),

        fontSize = 1,

        shadow = true,

        center = true
    })


    --------------------------------------------------------
    -- Coordinates
    --------------------------------------------------------

    local coords = overlay.createText({

        x = position.x,

        y = position.y + BOX_Y + 0.15,

        z = position.z,


        content = string.format(
            "X: %d Y: %d Z: %d",
            round(position.x),
            round(position.y),
            round(position.z)
        ),

        color = 0xFFFFFF,

        fontSize = 0.7,

        shadow = true,

        center = true
    })


    overlays[uuid] = {
        box = box,
        name = name,
        coords = coords
    }
end


------------------------------------------------------------
-- UPDATE ENTITY OVERLAY
------------------------------------------------------------

local function updateOverlay(uuid, entity)

    local position = getWorldPosition(entity)

    if not position then
        return
    end


    local objects = overlays[uuid]


    --------------------------------------------------------
    -- Create if necessary
    --------------------------------------------------------

    if not objects then

        createOverlay(
            uuid,
            entity,
            position
        )

        return
    end


    --------------------------------------------------------
    -- Update box
    --------------------------------------------------------

    objects.box.setPos(
        position.x,
        position.y + BOX_Y_OFFSET,
        position.z
    )


    --------------------------------------------------------
    -- Update box color
    --------------------------------------------------------

    objects.box.setColor(
        getEntityColor(entity)
    )


    --------------------------------------------------------
    -- Update name
    --------------------------------------------------------

    objects.name.setPos(
        position.x,
        position.y + BOX_Y + TEXT_Y_OFFSET,
        position.z
    )

    objects.name.setContent(
        entity.name or "Unknown"
    )


    --------------------------------------------------------
    -- Update coordinates
    --------------------------------------------------------

    objects.coords.setPos(
        position.x,
        position.y + BOX_Y + 0.15,
        position.z
    )

    objects.coords.setContent(
        string.format(
            "X: %d Y: %d Z: %d",
            round(position.x),
            round(position.y),
            round(position.z)
        )
    )
end


------------------------------------------------------------
-- REMOVE ENTITY OVERLAY
------------------------------------------------------------

local function removeOverlay(uuid)

    local objects = overlays[uuid]

    if not objects then
        return
    end


    overlay.removeObject(
        objects.box.getId()
    )

    overlay.removeObject(
        objects.name.getId()
    )

    overlay.removeObject(
        objects.coords.getId()
    )


    overlays[uuid] = nil
end


------------------------------------------------------------
-- REMOVE ALL ENTITY OVERLAYS
------------------------------------------------------------

local function clearEntityOverlays()

    for uuid in pairs(overlays) do
        removeOverlay(uuid)
    end
end


------------------------------------------------------------
-- SCAN
------------------------------------------------------------

local function performScan()

    --------------------------------------------------------
    -- pcall is important here.
    --
    -- If scanEntities() temporarily becomes unavailable,
    -- we don't want the entire program to crash.
    --------------------------------------------------------

    local ok, result = pcall(
        environmentDetector.scanEntities,
        SCAN_RANGE,
        true
    )


    if not ok or type(result) ~= "table" then

        print(
            "Entity scan failed; keeping previous scan."
        )

        return
    end


    --------------------------------------------------------
    -- Establish the scanner's absolute world position.
    --------------------------------------------------------

    if not updateScannerOrigin(result) then

        print(
            "Could not determine Smart Glasses wearer."
        )

        return
    end


    --------------------------------------------------------
    -- Build a new UUID-indexed entity table.
    --------------------------------------------------------

    local newEntities = {}


    for _, entity in pairs(result) do

        if entity.uuid then

            -- Don't render the wearer.
            if entity.uuid ~= wearerUUID then

                newEntities[entity.uuid] = entity

            end

        end

    end


    --------------------------------------------------------
    -- Only replace the old scan after everything above
    -- succeeded.
    --------------------------------------------------------

    entities = newEntities

    hasScan = true
end


------------------------------------------------------------
-- SCAN LOOP
------------------------------------------------------------

local function scanLoop()

    while true do

        performScan()

        sleep(SCAN_INTERVAL)

    end
end


------------------------------------------------------------
-- RENDER LOOP
------------------------------------------------------------

local function renderLoop()

    while true do

        if hasScan and scannerOrigin then

            ------------------------------------------------
            -- Update every entity.
            ------------------------------------------------

            for uuid, entity in pairs(entities) do

                updateOverlay(
                    uuid,
                    entity
                )

            end


            ------------------------------------------------
            -- Remove overlays that are no longer in the
            -- most recent successful scan.
            ------------------------------------------------

            for uuid in pairs(overlays) do

                if not entities[uuid] then
                    removeOverlay(uuid)
                end

            end

        end


        sleep(UPDATE_INTERVAL)

    end
end


------------------------------------------------------------
-- START
------------------------------------------------------------

parallel.waitForAny(
    scanLoop,
    renderLoop
)
