local chatter = peripheral.find("chat_box")
local plrdt = peripheral.find("player_detector")
local modems = peripheral.find("modem")

if not chatter then
error("Chat Box not found! Please attach one.")
end

if modems then
modems.open(67)
else
print("Warning: Modem not found. Teleport function will not work.")
end

math.randomseed(os.epoch("utc"))

local questionopen = false
local answered = false
local istated = false

local function say(text, baseSleep)
  local randomDelay = math.random(1, 10) / 10
  os.sleep(baseSleep + randomDelay)
  chatter.sendMessage(text, {prefix = "K.I", brackets = "<>"})
end

local function sayJoin(text, baseSleep)
  local naturdel = math.random(1, 10) / 15
  os.sleep(baseSleep + naturdel)
  chatter.sendMessage(text, {prefix = "K.I", brackets = "<>"})
end

local function thisisgonnabeamazing()
  while true do
    local event, uuid, plr, msg, isHidden = os.pullEvent("chat")
    local msgLower = string.lower(msg)

    if questionopen then
      answered = true
        if msgLower == "who are you" or msgLower == "who are you?" then
            say("Hello! I'm Kobold Intelligence, also known as K.I. I'm your personal A.I Friend. Just don't ask me anything. I know nothing.", 4.5)
        elseif msgLower == "do it jiggle?" then
            say("sorry but i cannot fulfill that request.", 4.5)
        elseif msgLower == "it do jiggle though right?" then
            say("im gonna call the police", 4.5)
        elseif msgLower == "eradicate him" then
            say("literally no.", 2.5)
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
            answered = false
        end
        
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
        questionopen = false
    end
    
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
    end

    if istated and plr == "burger_destroyer" then
        say("be quiet.", 0)
    end
    istated = false
    
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
      
    if string.find(msg, "kys", 1, true) and questionopen == false then
        say("die", .6)
    end
      
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
  end
end
