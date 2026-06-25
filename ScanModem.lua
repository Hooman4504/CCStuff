local modems = peripheral.wrap("right")
local coords = {464, 8, 942}
modems.open(4504)

while true do --goolllyyy brooo
  local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
  if channel == 4504 and replyChannel == 4505 then
    print(message)
    if message == "getpos" then
      modems.transmit(4504,4505,coords[1]..","..coords[2]..","..coords[3])
    elseif message == "464,8,942" then --i am SO SO sorry for hardcoding the coordinates i didnt wanna make a constilation or whatever
      print("close enough")
      redstone.setOutput("top",true)
      sleep(3)
      redstone.setOutput("top",false)
    end
  end
end
