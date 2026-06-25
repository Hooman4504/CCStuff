local modem = peripheral.wrap("right")
local coords = {464, 8, 942}
local doorcooldown = 1.5
local speaker = peripheral.wrap("left")
local speakervol = 2
local open = false

modem.open(4504)

local activeTimer = nil

while true do
    local event, side, channel, replyChannel, message =
        os.pullEvent()

    if event == "modem_message" and channel == 4504 and replyChannel == 4505 then
        print(message)

        if message == "getpos" then
            modem.transmit(
                4504,
                4505,
                table.concat(coords, ",")
            )

        elseif message == "464,8,942" then
            print("close enough")

            redstone.setOutput("top", true)
            if open == false then
            speaker.playNote("chime",speakervol,10)
            end
            open = true
            -- Reset timer every time coordinates arrive
            if activeTimer then
                os.cancelTimer(activeTimer)
            end

            activeTimer = os.startTimer(doorcooldown)
        end

    elseif event == "timer" and activeTimer and message == nil then
        -- Timer finished
        redstone.setOutput("top", false)
        open = false
        activeTimer = nil
    end
end
