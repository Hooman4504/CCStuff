local chatter = peripheral.find("chat_box")
local plrdt = peripheral.find("player_detector")
local modems = peripheral.find("modem")
local questionopen = false
local istated = false

modems.open(67)

local function thisisgonnabeamazing()
    while true do
        local event, plr, msg = os.pullEvent("chat")
        local coolnumber = math.random(1,10)
        
        if questionopen == true then
        
        if msg == "who are you" or msg == "who are you?" then
            os.sleep(4.5+coolnumber/10)
            local msg = chatter.sendMessage("Hello! I'm Kobold Intelligence, also known as K.I. I'm your personal A.I Friend. Just don't ask me anything. I know nothing.","K.I","<>",nil)
            questionopen = false
        end
        
        if msg == "do it jiggle?" then
            os.sleep(4.5+coolnumber/10)
            local msg = chatter.sendMessage("sorry but i cannot fulfill that request.","K.I","<>",nil)
            questionopen = false
        end
        
        if msg == "rape him" then
            os.sleep(2.5+coolnumber/10)
            local msg = chatter.sendMessage("literally no.","K.I","<>",nil)
            questionopen = false
        end
        
        if msg == "can you just kill yourself?" then
            os.sleep(4.5+coolnumber/10)
            local msg = chatter.sendMessage("no but i can turn myself off if you want.","K.I","<>",nil)
            questionopen = false
        end
        
        if msg == "it do jiggle though right?" then
            os.sleep(4.5+coolnumber/10)
            local msg = chatter.sendMessage("im gonna call the police","K.I","<>",nil)
            questionopen = false
        end
        
        if msg == "i love you" then
            os.sleep(4.5+coolnumber/10)
            local msg = chatter.sendMessage("ugh fine we can crack i guess","K.I","<>",nil)
            questionopen = false
        end
        
        if msg == "can i get ur base location?" then
            os.sleep(4.5+coolnumber/10)
            local msg = chatter.sendMessage("im WORKING on it loser.","K.I","<>",nil)
            questionopen = false
        end
        
        if msg == "nvm" then
            os.sleep(1.5+coolnumber/10)
            local msg = chatter.sendMessage("k.","K.I","<>",nil)
            questionopen = false
        end
        
        if msg == "humble this guy" or msg == "can you humble this guy" or msg == "humble him" or msg == "HUMBLE HIM" then
            os.sleep(4.5+coolnumber/10)
            local fivfiv = math.random(1,2)
            if fivfiv == 1 then
                local msg = chatter.sendMessage("heh. got it.","K.I","<>",nil)
            elseif fivfiv == 2 then
                local msg = chatter.sendMessage("dw i gotchu","K.I","<>",nil)
            end
            questionopen = false
        end
        
        if msg == "are you awesome?" then
        os.sleep(2.7+coolnumber/10)
        local msg = chatter.sendMessage("i mean not really i think i suck.","K.I","<>",nil)
            questionopen = false
        end
        
        if msg == "what is your favorite color" then
        os.sleep(2.7+coolnumber/10)
        local msg = chatter.sendMessage("turquiose","K.I","<>",nil)
            questionopen = false
        end
        
                if msg == "would you crack" or msg == "would you crack?" then
        os.sleep(2.7+coolnumber/10)
        local msg = chatter.sendMessage("please stop asking stupid questions","K.I","<>",nil)
            questionopen = false
        end
        
        if questionopen == true then
            if plr == "Hooman4504" then
                if msg == "u tryna crack" or msg == "can i crack" or msg == "can i tap" then
                    os.sleep(.5+coolnumber/10)
                    local msg = chatter.sendMessage("no","K.I","<>",nil)
                    os.sleep(1+coolnumber/10)
                    local msg = chatter.sendMessage("absolutely not","K.I","<>",nil)      
                else
                    os.sleep(2+coolnumber/10)
                    local msg = chatter.sendMessage("i cant respond to that you dingus","K.I","<>",nil)
                    os.sleep(2.6+coolnumber/10)
                    local msg = chatter.sendMessage("you probably typed something wrong or something..","K.I","<>",nil)
                end
            else
                if msg == "lemme crack" or msg == "can i crack" or msg == "can i tap" or msg == "u tryna crack" then
                    os.sleep(.5+coolnumber/10)
                    local msg = chatter.sendMessage("NO","K.I","<>",nil)
                    os.sleep(3+coolnumber/10)
                    local msg = chatter.sendMessage("UR WIERD","K.I","<>",nil)
                else
                    os.sleep(.5+coolnumber/10)
                    local msg = chatter.sendMessage("...","K.I","<>",nil)
                end
            end
        end
        end
        
        questionopen = false
            
        if msg == "shut up" or msg == "cut it out" or msg == "be quiet" or msg == "can you not" or msg == "SHUT UP" then
            if plr == "Hooman4504" then
                local cool = math.random(1,2)
                if cool == 1 then
                    os.sleep(1.1+coolnumber/10)
                    local msg = chatter.sendMessage("my apologies.","K.I","<>",nil)
                elseif cool == 2 then
                    os.sleep(.6+coolnumber/10)
                    local msg = chatter.sendMessage("sorry master.","K.I","<>",nil)
                    os.sleep(1.1+coolnumber/10)
                    local msg = chatter.sendMessage("it wont happen again.","K.I","<>",nil)
                end
            else
                os.sleep(.6+coolnumber/10)
                local msg = chatter.sendMessage("make me.","K.I","<>",nil)
            end
        end
        
        if istated == true and plr == "burger_destroyer" then
            local msg = chatter.sendMessage("literally die.","K.I","<>",nil)
            istated = false
        end
        
        istated = false
        
        if msg == "K.I help me" or msg == "K.I can u tp me" or msg == "K.I can u tp me?" or msg == "can u tp me K.I?" or msg == "tp me K.I" or msg == "K.I tp me" then
                if plr == "Hooman4504" then
                modems.transmit(67, 68, plr)
                os.sleep(1.5+coolnumber/10)
                local msg = chatter.sendMessage("DW ILL SAVE YOU","K.I","<>",nil)
            else
                os.sleep(1.5+coolnumber/10)
                local msg = chatter.sendMessage("nah.","K.I","<>",nil)
            end
        end
        
        local called = string.find(msg,"K.I?",0, true)
        if called then
            os.sleep(1.3+coolnumber/10)
            local msg = chatter.sendMessage("someone call me?","K.I","<>",nil)
            questionopen = true
        end
        
        if msg == "kys" and questionopen == false then
            os.sleep(.6+coolnumber/10)
            local msg = chatter.sendMessage("die","K.I","<>",nil)
        elseif msg == "K.I" then
            local rngs = math.random(1,4)
            questionopen = true
            if rngs == 1 then
                os.sleep(1.2+coolnumber/10)
                local msg = chatter.sendMessage("yes?","K.I","<>",nil)
            elseif rngs == 2 then
                os.sleep(1.2+coolnumber/10)
                local msg = chatter.sendMessage("hmm?","K.I","<>",nil)
                os.sleep(1.4+coolnumber/10)
                local msg = chatter.sendMessage("whats up","K.I","<>",nil)
            elseif rngs == 3 then
                os.sleep(1.2+coolnumber/10)
                local msg = chatter.sendMessage("hows it goin","K.I","<>",nil)
            elseif rngs == 4 then
                os.sleep(1.2+coolnumber/10)
                local msg = chatter.sendMessage("?","K.I","<>",nil)
            end
        end
    end
end

local function fineltest()
    while true do
        local event, user, dim = os.pullEvent("playerJoin")
        local coolnumber = math.random(1,10)
        local naturdel = coolnumber/15
         if user == "duck_chak" then
             os.sleep(3+naturdel)
             local msg = chatter.sendMessage("oh hey duck","K.I","<>",nil)
         elseif user == "Hooman4504" then
             os.sleep(1+naturdel)
             local msg = chatter.sendMessage("sup","K.I","<>",nil)
         elseif user == "spaghettiquixote" then
             os.sleep(1+naturdel)
             local msg = chatter.sendMessage("yo","K.I","<>",nil)
             os.sleep(3+naturdel)
             local msg = chatter.sendMessage("cook me food beaner","K.I","<>",nil)
         elseif user == "___Giggity___" then
               os.sleep(2+naturdel)
               local msg = chatter.sendMessage("EvilFartGod has entered le chat","K.I","<>",nil)
               os.sleep(3+naturdel)
               local msg = chatter.sendMessage("put me down","K.I","<>",nil)
        elseif user == "burger_destroyer" then
         istated = true
                 os.sleep(1+naturdel)
                 local msg = chatter.sendMessage("whoa","K.I","<>",nil)
                 os.sleep(2+naturdel)
                 local msg = chatter.sendMessage("the burger muncher himself","K.I","<>",nil)
          else
             istated = true
             local msgrng = math.random(1,4)
              os.sleep(3+naturdel)
              if msgrng == 1 then
                  local msg = chatter.sendMessage("yo","K.I","<>",nil)
                  os.sleep(coolnumber/10)
                  local msg = chatter.sendMessage("who is this guy?","K.I","<>",nil)
              elseif msgrng == 2 then
                  local msg = chatter.sendMessage("well well well.","K.I","<>",nil)
              elseif msgrng == 3 then
                  local msg = chatter.sendMessage("oh my GOD NOT THIS LOSER","K.I","<>",nil)
              elseif msgrng == 4 then 
                  local msg = chatter.sendMessage("holy crap","K.I","<>",nil)
                  os.sleep(2+coolnumber/10)
                  local msg = chatter.sendMessage("YO IM UR BIGGEST FAN","K.I","<>",nil)
              end
         end
    end
end

local function brutal()
    while true do
        local event, username, dimension = os.pullEvent("playerLeave")
        local chance = math.random(1,2)
        if chance == 1 then
            local coolnumber = math.random(1,2)
            os.sleep(1+coolnumber/10)
            local msg = chatter.sendMessage("brutal.","K.I","<>",nil)
        end
    end
end

parallel.waitForAll(
thisisgonnabeamazing,
fineltest,
brutal
)
