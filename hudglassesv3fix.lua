-- STREAMING_CHUNK: Initializing peripherals and permission checks...
local monitor = smartglasses.modules.overlay
local playerz = peripheral.find("player_detector")

local multidimspyallowed = nil
local allowedwearerIsWearing = false

local allowedwearers = {
"Hooman4504",
"burger_destroyer"
}

local wearer = smartglasses.getOwner()

-- Testing for multidimspy/wearer blacklist
local wearplayer = playerz.getPlayer(wearer.uuid)
if wearplayer and wearplayer.dimension ~= nil then
multidimspyallowed = true
else
multidimspyallowed = false
end

for i, v in pairs(allowedwearers) do
if wearplayer and wearplayer.name == v then
allowedwearIsWearing = true
end
end

-- STREAMING_CHUNK: Defining helper functions...
local function floor(value)
return math.floor(value)
end

-- Table to store persistent text element references for each player
local playerTexts = {}

-- STREAMING_CHUNK: Starting the main coordinate tracking loop...
while true do
if not allowedwearerIsWearing then
print("Invalid permissions. Returning.")
return
end

os.sleep(1)

local list = playerz.getOnlinePlayers()
local onlineSet = {}

-- STREAMING_CHUNK: Updating or creating text elements for online players...
for i, plr in pairs(list) do
    onlineSet[plr] = true
    local player = playerz.getPlayer(plr)
    
    if player then
        local x, y, z = floor(player.x), floor(player.y), floor(player.z)
        local content = plr .. " x: " .. x .. " y: " .. y .. " z: " .. z
        if multidimspyallowed and player.dimension then
            content = content .. " [" .. player.dimension .. "]"
        end

        if playerTexts[plr] then
            -- Update existing text element without recreating it
            playerTexts[plr].setText(content)
            playerTexts[plr].setY(i * 30)
        else
            -- Create a new text element if the player just joined
            playerTexts[plr] = monitor.createText({
                gui = true,
                x = 30,
                y = i * 30,
                content = content,
                shadow = true
            })
        end
    end
end

-- STREAMING_CHUNK: Cleaning up elements for disconnected players...
for plr, textObj in pairs(playerTexts) do
    if not onlineSet[plr] then
        if textObj and textObj.delete then
            textObj.delete()
        end
        playerTexts[plr] = nil
    end
end


end
