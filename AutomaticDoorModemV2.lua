local modem = peripheral.wrap("right")

modem.open(4504)

local x,y,z = gps.locate(2)

if not x then
    error("No GPS signal")
end

local coords = vector.new(x,y,z)

print("Position:", coords)

local timer

while true do

    local event, side,
          channel,
          reply,
          msg =
        os.pullEvent()

    if event == "modem_message"
    and channel == 4504
    and reply == 4505 then

        if msg == "getpos" then

            modem.transmit(
                4504,
                4505,
                {
                    x=x,
                    y=y,
                    z=z,
                    id=os.getComputerID()
                }
            )

        elseif type(msg)=="table"
        and msg.type=="open" then

            if msg.id ==
               os.getComputerID() then

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
                        1.5
                    )
            end
        end

    elseif event=="timer" then

        redstone.setOutput(
            "top",
            false
        )

        timer=nil
    end
end
