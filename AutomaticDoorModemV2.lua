local modem = peripheral.wrap("right")

local doorId = os.getComputerID()

modem.open(4504)

local cooldown = 1.5
local timer

while true do
    local event, side,
          channel,
          reply,
          msg =
        os.pullEvent()

    if event == "modem_message"
    and channel == 4504 then
        if msg.type == "discover" then
            modem.transmit(
                4504,
                4505,
                {
                    type="door",
                    id=doorId
                }
            )
        elseif msg.type == "open"
        and msg.id == doorId then
            redstone.setOutput(
                "top",
                true
            )
            if timer then
                os.cancelTimer(
                    timer
                )
            end
            timer =
                os.startTimer(
                    cooldown
                )
        end

    elseif event=="timer" then
        redstone.setOutput(
            "top",
            false
        )
        timer=nil
    end
end
