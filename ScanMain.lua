local detector = peripheral.wrap("right")
local speaker = peripheral.wrap("top")
local monidor = peripheral.wrap("left")
local modemsussy = peripheral.wrap("bottom")
local activationdist = 11
local radarspeed = .5

local hudmodem = peripheral.wrap("back")

hudmodem.clear()
hudmodemresetSize()
hudmodem.setBackgroundColour(0) --transparent background
hudmodem.setTextColour(colors.white)
hudmodem.setCursorPos(1,1)

modemsussy.open(4504)

local acquiredpcpos = {}

local function distcalcT2(vec1,vec2,plr)
  --this is 100% nessescary
  --vec1 is plr
  local center = vec2
  local half = activationdist/2
  local halfvector - vector.new(half,half,half)

  local minpos = center - halfvector
  local maxpos = center + halfvector
  return detector.isPlayerInCoords(minpos,maxpos,plr)
end

local function modemget()
  modemsussy.transmit(4504,4505,"getpos")
  while true do
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    if channel == 4504 and replyChannel == 4505 then
      local vectors = vector.new(0,0,0)
      local i = 1
      for item in string.gmatch(message,"[^,]+") do
        if i == 1 then
          vectors.x = item
        elseif i == 2 then
          vectors.y = item
        elseif i == 3 then
          vectors.z = item
        end
        i = i + 1
      end
      table insert(acquiredpcpos,vectors)
    end
  end
end

local function radar_tick() --main function
  while true do
    os.sleep(1)
    monidor.clear()
    monidor.setCursorPos(1,1)
    speaker.playNote("pling",1,10)

    for i,v in pairs(detector.getOnlinePlayers()) do
      local player = detector.getPlayer(v)
      local vectors = vector.new(player.x,player.y,player.z)
      for i,v in pairs(acquiredpcpos) do
        local dist = distcalcT2(vectors,v,player.name)
        if dist == true then
          modemsussy.transmit(4504,4505,tostring(v)
        end
        print(dist)
        end
        speaker.playerNote("bit",.5,i)
        
        local playerinfostring = player.name..": x = "..
        player.x.." y = "..player.y.." z = "..player.z..
        " "..player.dimension
        
        monidor.write(playerinfostring)
        hudmodem.write(playerinfostring)
        local x,y = monidor.getCursorPos()
        monidor.setCursorPos(1,y+1)
        hudmodem.setCursorPos(1, y+1)
      end
    end
  end

  parallel.waitForAll(modemget,radar_tick)
    
