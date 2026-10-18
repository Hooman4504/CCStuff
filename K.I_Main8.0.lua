-- STREAMING_CHUNK: fix this in the future.
local chatter = peripheral.find("chat_box")
local plrdt = peripheral.find("player_detector")
local modems = peripheral.find("modem")

-- Added safety checks to prevent crashes if a peripheral disconnects
if not chatter then
error("Chat Box not found! Please attach one.")
end

if modems then
modems.open(67)
else
print("Warning: Modem not found. Teleport function will not work.")
end

-- Initialize random seed so the responses are different every time you restart the script
math.randomseed(os.epoch("utc"))

local questionopen = false
local istated = false

-- STREAMING_CHUNK: Defining helper functions for sending messages...

-- Helper function: Sends a message to chat with a random delay added to the base sleep time.
-- This removes the need to constantly type os.sleep() and math.random() in your logic!
-- (It also fixes the Advanced Peripherals bug by dropping the trailing 'nil' argument).
local function say(text, baseSleep)
local randomDelay = math.random(1, 10) / 10
os.sleep(baseSleep + randomDelay)
chatter.sendMessage(text, "K.I", "<>")
end

-- Helper function: Specifically for join messages which use a different delay math.
local function sayJoin(text, baseSleep)
local naturdel = math.random(1, 10) / 15
os.sleep(baseSleep + naturdel)
chatter.sendMessage(text, "K.I", "<>")
end

-- STREAMING_CHUNK: Setting up the main chat event loop...
local function thisisgonnabeamazing()
while true do
local event, plr, msg = os.pullEvent("chat")

    -- Convert the message to lowercase so capitalization doesn't break the commands
    local msgLower = string.lower(msg)
    
    -- STREAMING_CHUNK: Handling user states and random interrupts...
    if istated and plr == "burger_destroyer" then
        say("be quiet.", 0)
    end
    istated = false
    
    if msgLower == "shut up" or msgLower == "cut it out" or msgLower == "be quiet" or msgLower == "can you not" then
        if plr == "Hooman4504" then
            local cool = math.random(1, 2)
            if cool == 1 then
                say("my apologies.", 1.1)
            else
                say("sorry master.", 0.6)
                say("it wont happen again.", 1.1)
            end
        else
            say("make me.", 0.6)
        end
        -- Skip the rest of the checks for this message
    end
    
    -- STREAMING_CHUNK: Handling teleport commands via table lookup...
    local tpCommands = {
        ["k.i help me"] = true, ["k.i can u tp me"] = true, ["k.i can u tp me?"] = true,
        ["can u tp me k.i?"] = true, ["tp me k.i"] = true, ["k.i tp me"] = true
    }
    
    if tpCommands[msgLower] then
        if plr == "Hooman4504" then
            if modems then modems.transmit(67, 68, plr) end
            say("DW ILL SAVE YOU", 1.5)
        else
            say("nah.", 1.5)
        end
    end
    
    -- STREAMING_CHUNK: Handling getting K.I.'s attention...
    -- string.find is case sensitive because we use the raw 'msg' here (matching your original logic)
    if string.find(msg, "K.I?", 1, true) then
        say("someone call me?", 1.3)
        questionopen = true
    end
    
    if msg == "K.I" then
        local rngs = math.random(1, 4)
        questionopen = true
        if rngs == 1 then
            say("yes?", 1.2)
        elseif rngs == 2 then
            say("hmm?", 1.2)
            say("whats up", 1.4)
        elseif rngs == 3 then
            say("hows it goin", 1.2)
        elseif rngs == 4 then
            say("?", 1.2)
        end
    end
    
    -- STREAMING_CHUNK: Handling active question interactions...
    if questionopen then
        local answered = true -- Keeps track if we matched a specific question
        
        if msgLower == "who are you" or msgLower == "who are you?" then
            say("Hello! I'm Kobold Intelligence, also known as K.I. I'm your personal A.I Friend. Just don't ask me anything. I know nothing.", 4.5)
        elseif msgLower == "do it jiggle?" then
            say("sorry but i cannot fulfill that request.", 4.5)
        elseif msgLower == "eradicate him" then
            say("literally no.", 2.5)
        elseif msgLower == "it do jiggle though right?" then
            say("im gonna call the police", 4.5)
        elseif msgLower == "i love you" then
            say("ugh fine we can crack i guess", 4.5)
        elseif msgLower == "can i get ur base location?" then
            say("im WORKING on it loser.", 4.5)
        elseif msgLower == "nvm" then
            say("k.", 1.5)
        elseif msgLower == "humble this guy" or msgLower == "can you humble this guy" or msgLower == "humble him" then
            if math.random(1, 2) == 1 then
                say("heh. got it.", 4.5)
            else
                say("dw i gotchu", 4.5)
            end
        elseif msgLower == "are you awesome?" then
            say("i mean not really i think i suck.", 2.7)
        elseif msgLower == "what is your favorite color" then
            say("turquiose", 2.7)
        elseif msgLower == "would you crack" or msgLower == "would you crack?" then
            say("please stop asking stupid questions", 2.7)
        else
            answered = false -- No specific question matched!
        end
        
        -- If a specific question was not found, drop into the catch-all behavior
        if not answered then
            if plr == "Hooman4504" then
                if msgLower == "u tryna crack" or msgLower == "can i crack" or msgLower == "can i tap" then
                    say("no", 0.5)
                    say("absolutely not", 1.0)
                else
                    say("i cant respond to that you dingus", 2.0)
                    say("you probably typed something wrong or something..", 2.6)
                end
            else
                if msgLower == "lemme crack" or msgLower == "can i crack" or msgLower == "can i tap" or msgLower == "u tryna crack" then
                    say("NO", 0.5)
                    say("UR WIERD", 3.0)
                else
                    say("...", 0.5)
                end
            end
        end
        
        -- Always close the question state after an interaction
        questionopen = false
    end
end


end

-- STREAMING_CHUNK: Setting up player join logic...
local function fineltest()
while true do
local event, user, dim = os.pullEvent("playerJoin")

    if user == "duck_chak" then
        sayJoin("oh hey duck", 3.0)
    elseif user == "Hooman4504" then
        sayJoin("sup", 1.0)
    elseif user == "___Giggity___" then
        sayJoin("bro.", 2.0)
    elseif user == "burger_destroyer" then
        istated = true
        sayJoin("whoa", 1.0)
        sayJoin("the burger muncher himself", 2.0)
    else
        istated = true
        local msgrng = math.random(1, 3)
        if msgrng == 1 then
            sayJoin("yo", 3.0)
            say("who is this guy?", 0)
        elseif msgrng == 2 then
            sayJoin("well well well.", 3.0)
        elseif msgrng == 3 then
            sayJoin("holy crap", 3.0)
            say("YO IM UR BIGGEST FAN", 2.0)
        end
    end
end


end

-- STREAMING_CHUNK: Setting up player leave logic...
local function brutal()
while true do
local event, username, dimension = os.pullEvent("playerLeave")

    -- 50% chance to comment on the player leaving
    if math.random(1, 2) == 1 then
        say("brutal.", 1.0)
    end
end


end

-- STREAMING_CHUNK: Running all threads in parallel...
parallel.waitForAll(
thisisgonnabeamazing,
fineltest,
brutal
)
