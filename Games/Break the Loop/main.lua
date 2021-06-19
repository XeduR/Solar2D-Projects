--[[
Break the Loop - Created for Ludum Dare 47
==========================================
Copyright 2020 Eetu Rantanen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

display.setStatusBar( display.HiddenStatusBar )

local loop = require("loops")

local _random = math.random
local _max = math.max

audio.setVolume( 0.2 )
audio.reserveChannels( 1 )
local bgMusic =  audio.loadSound( "audio/blippy-trance-by-kevin-macleod-from-filmmusic-io.mp3")
audio.play( bgMusic, {channel=1, loops=-1} )

local audioClick =  audio.loadSound( "audio/click.mp3")
local audioSuccess =  audio.loadSound( "audio/success.mp3")

--------------------------------------------

local font = "fonts/slkscr.ttf"
local snapTimePerPixel = 2
local snapMaxDuration = 500
local flashTime = 500

--------------------------------------------

local codeSize = 16
local codeStartX = 52
local codeStartY = 182
local codePaddingX = 6
local codePaddingY = 6
local codeBlockHorizontalPadding = 4
local codeHeight = 24
local codeTabSize = 24
local codeColor = { 0, 0, 0, 1 }
local codeBgColor = { 0.9, 0.5, 0.5, 1 }

--------------------------------------------

local lineCount = 15
local lineSize = 17
local lineStartX = 476
local lineStartY = 60
local lineHeight = 36
local lineColor = { 0.9, 0.8, 0.1, 1 }

--------------------------------------------

local barStartX = 25
local barStartY = 117
local barCount = 10
local barWidth = 36
local barHeight = 72
local barPadding = 1
local barDuration = 200
local barDurationVar = 100
local barColor = { 0.9, 0.8, 0.1, 1 }

--------------------------------------------

local optionsOpen = false
local gameStopped = false
local soundOn = true
local musicOn = true
local canTouch = true
local stopLoop = false
local gameComplete = false
local loopReset = false
local currentLine = 0
local loopN = 1
local activeLoop
local newLoop

--------------------------------------------

local group = display.newGroup()
local groupOptions = display.newGroup()
groupOptions.isVisible = false
local groupOutput = display.newGroup()
local groupCode

local ui = {}
local code = {}
local codeBlock = {}
local bar = {}
local output = {}

local function showOptions( event )
    if canTouch then
        if event.phase == "began" then
            local target = event.target
            target.isTouched = true
            target.isInside = true
            target.fill = target.pressed
            display.getCurrentStage():setFocus( target )
                    
        elseif event.phase == "moved" then
            local target = event.target
            if target.isTouched then
                if event.x >= target.contentBounds.xMin and event.x <= target.contentBounds.xMax and event.y >= target.contentBounds.yMin and event.y <= target.contentBounds.yMax then
                    if not target.isInside then
                        target.isInside = true
                        target.fill = target.pressed
                    end
                else
                    if target.isInside then
                        target.isInside = false
                        target.fill = target.default
                    end
                end
            end
        else
            local target = event.target
            target.fill = target.default
            
            if target.isInside then
                optionsOpen = not optionsOpen
                groupOptions.isVisible = optionsOpen
                groupOutput.isVisible = not optionsOpen
                if soundOn then audio.play( audioClick ) end
            end
            
            target.isTouched = false
            target.isInside = false
            display.getCurrentStage():setFocus( nil )
        end
    end
    return true
end

local function updateBar( target )
    if not gameStopped then
        local height = 1+target.barHeight*_max(0.1,_random())
        transition.to( target, { time=barDuration+barDurationVar*_random(), height=height, onComplete=updateBar })
    end
end

ui.bg = display.newImage( group, "images/bg.png", 480, 320 )

ui.flash = display.newRect( group, 229, 348, 368, 362 )
ui.flash.alpha = 0

ui.options = display.newRect( group, 148, 580, 230, 52 )
ui.options.default = {
    type = "image",
    filename = "images/button.png"
}
ui.options.pressed = {
    type = "image",
    filename = "images/buttonPressed.png"
}
ui.options.fill = ui.options.default
ui.options:addEventListener( "touch", showOptions )
ui.options.isTouched = false
ui.options.isInside = false

ui.title = display.newText({
    parent = group,
    text = "Break the Loop\nfor Ludum Dare 47\nby Eetu Rantanen",
    x = 356,
    y = 580,
    font = font,
    fontSize = 15,
})

local function setOption( event )
    if event.phase == "ended" then
        if event.target.id == "sounds" then
            soundOn = not soundOn
            event.target.text = soundOn and "SOUNDS: ON" or "SOUNDS: OFF"
            
        elseif event.target.id == "music" then
            musicOn = not musicOn
            event.target.text = musicOn and "MUSIC: ON" or "MUSIC: OFF"
            audio.setVolume( musicOn and 1 or 0, { channel=1 } )
            
        else
            gameStopped = true
            
            ui.options.title.text = "Loop broken\n\nLoop broken"
            ui.options.sounds.text = "Loop broken"
            ui.options.music.text = "Loop broken"
            ui.options.divider.text = "Loop broken"
            ui.options.exit.text = "Loop broken"
            ui.options.credits.text = "Loop broken\n\nLoop broken\n\nLoop broken\n\nLoop broken\nLoop broken\nLoop broken\nLoop broken\nLoop broken"
            
            text = "=========\n\nGame by Eetu Rantanen\n\nSFX by kenney.nl\n\nBlippy Trance by Kevin MacLeod\nLink: https://incompetech.filmmusic.io/song/\n5759-blippy-trance\nLicense: http://creativecommons.org/\nlicenses/by/4.0/",
            
            transition.to( groupCode, {delay=500,time=1000,alpha=0} )
            
            local screencover = display.newRect( 229, 348, 368, 1 )
            screencover.alpha = 0
            screencover:setFillColor(0)
            transition.to( screencover, {delay=500,time=500,alpha=1,height=362,width=368} )
            
            local bg = display.newRect( 480, 320, 960, 640 )
            bg.alpha = 0
            bg:setFillColor(0)
            
            local function block(event)
                return true
            end
            
            bg:addEventListener( "touch", block )
            bg:addEventListener( "tap", block )
            audio.fadeOut( { channel=1, time=2500 } )
            transition.to( bg, {delay=500,time=2000,alpha=1,onComplete=function()
                ui.options.title = display.newText({
                    text = "Application terminated.\n\nThe loop is broken.\n\n\n\nNow, close the game. I didn't program that part. ^^",
                    x = 480,
                    y = 320,
                    font = font,
                    align = "center",
                    fontSize = 26,
                })
                if soundOn then audio.play( audioSuccess, {channel=audio.findFreeChannel(2)} ) end
            end})
        end
        if soundOn then audio.play( audioClick ) end
    end
    return true
end

ui.options.title = display.newText({
    parent = groupOptions,
    text = "OPTIONS:\n\n=========",
    x = 470,
    y = 70,
    font = font,
    fontSize = 26,
})
ui.options.title:setFillColor( lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 1 )
ui.options.title.anchorX, ui.options.title.anchorY = 0, 0

ui.options.sounds = display.newText({
    parent = groupOptions,
    text = "SOUNDS: ON",
    x = ui.options.title.x,
    y = ui.options.title.y+ui.options.title.height+40,
    font = font,
    fontSize = 26,
})
ui.options.sounds:setFillColor( lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 1 )
ui.options.sounds.anchorX, ui.options.sounds.anchorY = 0, 0
ui.options.sounds.id = "sounds"
ui.options.sounds:addEventListener( "touch", setOption )

ui.options.music = display.newText({
    parent = groupOptions,
    text = "MUSIC: ON",
    x = ui.options.title.x,
    y = ui.options.sounds.y+ui.options.sounds.height+40,
    font = font,
    fontSize = 26,
})
ui.options.music:setFillColor( lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 1 )
ui.options.music.anchorX, ui.options.music.anchorY = 0, 0
ui.options.music.id = "music"
ui.options.music:addEventListener( "touch", setOption )

ui.options.divider = display.newText({
    parent = groupOptions,
    text = "=========",
    x = ui.options.title.x,
    y = ui.options.music.y+ui.options.music.height+40,
    font = font,
    fontSize = 26,
})
ui.options.divider:setFillColor( lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 1 )
ui.options.divider.anchorX, ui.options.divider.anchorY = 0, 0

ui.options.exit = display.newText({
    parent = groupOptions,
    text = "EXIT GAME",
    x = ui.options.title.x,
    y = ui.options.divider.y+ui.options.divider.height+40,
    font = font,
    fontSize = 26,
})
ui.options.exit:setFillColor( lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 1 )
ui.options.exit.anchorX, ui.options.exit.anchorY = 0, 0
ui.options.exit.id = "exit"
ui.options.exit:addEventListener( "touch", setOption )

ui.options.credits = display.newText({
    parent = groupOptions,
    text = "=========\n\nGame by Eetu Rantanen\n\nSFX by kenney.nl\n\nBlippy Trance by Kevin MacLeod\nLink: https://incompetech.filmmusic.io/song/\n5759-blippy-trance\nLicense: http://creativecommons.org/\nlicenses/by/4.0/",
    x = ui.options.title.x,
    y = ui.options.exit.y+ui.options.exit.height+40,
    font = font,
    fontSize = 16,
})
ui.options.credits:setFillColor( 1 )
ui.options.credits.anchorX, ui.options.credits.anchorY = 0, 0

-- Set up the top left bars (these do nothing for the game, they are purely visual).
for i = 1, barCount do
    bar[i] = display.newRect( group, barStartX+i*(barWidth+barPadding), barStartY, barWidth, barHeight )
    bar[i]:setFillColor( barColor[1], barColor[2], barColor[3], barColor[4] or 1 )
    bar[i].barHeight = barHeight
    bar[i].anchorY = 1
    updateBar( bar[i] )
end

-- Set up initial output lines, i.e. the code screen text.
for i = 1, lineCount do
    output[i] = display.newText({
        parent = groupOutput,
        text = "",
        x = lineStartX,
        y = lineStartY+(i-1)*lineHeight,
        font = font,
        fontSize = lineSize,
    })
    output[i]:setFillColor( lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 1 )
    output[i].anchorX, output[i].anchorY = 0, 0
end
local lineDelta = output[2].y-output[1].y

local function resetTouch()
    canTouch = true
end

local function dragCode( event )
    if canTouch then
        if event.phase == "began" then
            if optionsOpen then
                optionsOpen = false
                groupOptions.isVisible = false
                groupOutput.isVisible = true
            end
            event.target.isTouched = true
            event.target.xStart = event.target.x
            event.target.yStart = event.target.y
            display.getCurrentStage():setFocus( event.target )
            event.target:toFront()
                    
        elseif event.phase == "moved" then
            if event.target.isTouched then
                local target = event.target
                target.x = target.xStart+event.xDelta
                target.y = target.yStart+event.yDelta
                for i = 1, #codeBlock do
                    local bounds = code[codeBlock[i].ref[1]][codeBlock[i].ref[2]].contentBounds                    
                    if event.x >= bounds.xMin and event.x <= bounds.xMax and event.y >= bounds.yMin and event.y <= bounds.yMax then
                        codeBlock[i].isInside = true
                    else
                        codeBlock[i].isInside = false
                    end
                end
            end
        else
            if event.target.isTouched then
                if soundOn then audio.play( audioClick ) end
                loopReset = true
                loopN = 0
                
                local target = event.target
                target.isTouched = false
                canTouch = false
                
                local destination
                for i = 1, #codeBlock do
                    if codeBlock[i].isInside and codeBlock[i] ~= target then
                        destination = codeBlock[i]
                    end
                    codeBlock[i].isInside = false
                end
                
                if not destination then
                    local to = code[target.ref[1]][target.ref[2]]
                    transition.to( target, { time=math.min(math.sqrt((event.x-to.xReturn)^2+(event.y-to.yReturn)^2)*snapTimePerPixel,snapMaxDuration), x=to.xReturn, y=to.yReturn, transition=easing.outElastic, onComplete=resetTouch })
                else
                    -- NB! This functionality is very clunky and should be rewritten (if someone wants to write something similar outside Ludum Dare).
                    
                    local fromRef1, fromRef2, fromRefCode = target.ref[1], target.ref[2], code[target.ref[1]][target.ref[2]].ref
                    local toRef1, toRef2, toRefCode = destination.ref[1], destination.ref[2], code[destination.ref[1]][destination.ref[2]].ref
                    
                    code[fromRef1][fromRef2].ref = toRefCode
                    codeBlock[fromRefCode].ref = {toRef1, toRef2}
                    code[toRef1][toRef2].ref = fromRefCode
                    codeBlock[toRefCode].ref = {fromRef1, fromRef2}
                    
                    code[toRef1][toRef2].text = target.text
                    code[fromRef1][fromRef2].text = destination.text
                    
                    local to = code[toRef1][toRef2]
                    target:toFront()
                    transition.to( target, { time=math.min(math.sqrt((event.x-to.xReturn)^2+(event.y-to.yReturn)^2)*snapTimePerPixel,snapMaxDuration), x=to.xReturn, y=to.yReturn, transition=easing.outElastic })
                    
                    local from = code[fromRef1][fromRef2]
                    destination:toFront()
                    transition.to( destination, { time=math.min(math.sqrt((event.x-from.xReturn)^2+(event.y-from.yReturn)^2)*snapTimePerPixel,snapMaxDuration), x=from.xReturn, y=from.yReturn, transition=easing.outElastic })
                end
                
                display.getCurrentStage():setFocus( nil )
            end
        end
    end
    return true
end


local lineCountReached = false
local function updateOutput( msg, success )
    currentLine = currentLine+1
    loopN = loopN+1
    local time = os.date("*t")
    output[currentLine].text = ("%02d:%02d:%02d"):format(time.hour, time.min, time.sec ) .. " - " .. msg
    
    if msg == "error" or msg == "false" or msg == "error: infinite loop" then
        output[currentLine]:setFillColor( 0.9, 0, 0 )
    elseif msg == "success" or msg == "true" then
        output[currentLine]:setFillColor( 0, 0.9, 0 )
    elseif msg == "os: have tried turning it off?" then
        output[currentLine]:setFillColor( 0.3, 0.9, 0.6 )
    else
        output[currentLine]:setFillColor( lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 1 )
    end
    
    if lineCountReached then
        for i = 1, lineCount do
            output[i].y = output[i].y-lineDelta
        end
        local prevNumber = currentLine == 1 and lineCount or currentLine-1
        output[currentLine].y = output[prevNumber].y+lineDelta
    end
    
    if currentLine == lineCount then
        lineCountReached = true
        currentLine = 0
    end
    
    if success then
        if soundOn then audio.play( audioSuccess ) end
        ui.flash:setFillColor( 0.1, 0.8, 0 )
        ui.flash.alpha = 1
        transition.to( ui.flash, {time=flashTime,alpha=0})
        canTouch = false
        stopLoop = true
        timer.cancelAll()
        timer.performWithDelay( 250, function()
            updateOutput( "initializing next loop..." )
        end )
        transition.to( groupCode, {delay=500,time=750,alpha=0,onComplete=function()
            updateOutput( "next loop ready..." )
            code = {}
            codeBlock = {}
            display.remove( groupCode )
            
            activeLoop = activeLoop+1
            if activeLoop > #loop then
                activeLoop = 1
                gameComplete = true
            end
            newLoop(activeLoop)
        end})
    else
        if not stopLoop then
            canTouch = true
        end
    end
end

local function runLoop()
    if not gameStopped and not stopLoop then
        -- NB! The original idea was to use pcall/loadstring to handle the code dynamically,
        -- but given the time restraints, I opted to simply run predetermined codes, which
        -- let's me easily determine what to print and how to handle loops with errors.
        
        local s, msg, success = {}, msg, false
        for i = 1, #code do
            s[i] = ""
            for j = 1, #code[i] do
                s[i] = s[i].." "..code[i][j].text
            end
        end
        
        -- ----------------
        -- -- FOR TESTING:
        -- print("------")
        -- for i = 1, #s do
        --     print( i, s[i] )
        -- end
        -- print("------")
        -- activeLoop = 5
        -- ----------------
        
        if activeLoop == 1 then
            if s[4] == " while false do" then
                success = true
                msg = "success"
            else
                msg = "false"
            end
        
        elseif activeLoop == 2 then
            if
                s[4] == " while false do" and
                s[9] == " local var = true" and
                s[10] == " until var == true"
            then
                success = true
                msg = "success"
            else
                if s[4] == " while Lua do" then
                    if s[5] == " print( this language is false )" then
                        msg = "this language is false"
                    else
                        msg = "this language is true"
                    end
                elseif s[4] == " while true do" then
                    if s[5] == " print( this language is false )" then
                        msg = "this language is false"
                    else
                        msg = "this language is awesome"
                    end
                else
                    msg = "error: infinite loop"
                end
            end
            
        elseif activeLoop == 3 then
            if
                s[2] == " noloop , loop = true, false" and
                s[8] == " while not ( noloop ) do"
            then
                success = true
                msg = "success"
            else
                if s[2]:sub(1,5) == " loop" then
                    msg = s[5]:sub(10,-5)
                else
                    if s[2]:sub(1,7) == " noloop" then
                        if s[8] == " while type ( noloop ) do" then
                            msg = "or is it magic after all?"
                        else
                            msg = "error"
                        end
                    else
                        msg = "error"
                    end
                end
            end
            
        elseif activeLoop == 4 then
            local n = tonumber(code[5][4].text)
            if loopReset and n then
                loopReset = false
                loopN = loopN + n
            end
            
            if s[4]:sub(1,6) ~= " limit" or not n then
                msg = "error"
            else
                local a = code[6][2].text
                if a == "n" then
                    a = loopN
                else
                    a = tonumber(a)
                end
                local operator = code[6][3].text
                local b = tonumber(code[6][4].text)
                local result = tonumber(code[6][6].text)
                
                if not a or not b or not result or tonumber(code[6][3].text) then
                    msg = "error"
                else
                    local calculation = loadstring( "return " .. (a..operator..b.."=="..result))
                    
                    if calculation() then
                        msg = "true"
                        success = true
                    else
                        msg = "false"
                    end
                end
            end

        elseif activeLoop == 5 then
            local text = s[4]:sub(7,-2)
            local n1 = tonumber( code[6][4].text )
            local n2 = tonumber( code[6][6].text )
            local n3 = tonumber( code[6][8].text )
            local n4 = tonumber( code[6][10].text )
            local a = n1+n2
            local b = n3*n4
            local substring = text:sub(a,b)
            if substring == "lazy" then
                updateOutput( substring )
                msg = "success"
                success = true
            else
                msg = substring
            end
                        
        else
            msg = "error"
        end
        updateOutput( msg, success )
    end
    if not stopLoop then
        timer.performWithDelay( 200, runLoop )
        -- Give the player a hint randomly that they should turn off the game.
        if gameComplete and math.random() > 0.95 then
            updateOutput( "os: have tried turning it off?" )
        end
    end
end

function newLoop( loopNumber )
    activeLoop = loopNumber
    local loop = loop[loopNumber]
    local t, lineStart = {}, {}
    local longestMoveable = 0
    
    for i = 1, #loop do
        lineStart[i] = codeStartX + tonumber(loop[i]:sub(1,1))*codeTabSize
        local s = loop[i]:sub(2)
        t[i] = {}
        
        -- Split every word/variable/element from each line.
        for entry in string.gmatch(s, "[^%s]+") do
            -- Words beginning with an asterix are moveable code blocks.
            if entry:sub(1,1) == "*" then
                local s = entry:sub(2)
                t[i][#t[i]+1] = { s=s, moveable=true }
                local temp = display.newText({
                    text = s,
                    x = 1000,
                    y = 1000,
                    font = font,
                    fontSize = codeSize,
                })
                if temp.width > longestMoveable then longestMoveable = temp.width end
                display.remove( temp )
            else
                t[i][#t[i]+1] = { s=entry, moveable=false }
            end
        end
    end
    
    groupCode = display.newGroup()
    groupCode.alpha = 0
    local prevX
    
    for i = 1, #t do
        code[i] = {}
        prevX = 0
        for j = 1, #t[i] do
            local isMoveable = t[i][j].moveable
            
            if isMoveable then
                code[i][j] = display.newRect( groupCode, lineStart[i]+prevX+(j-1)*codePaddingX, codeStartY+(i-1)*(codeHeight+codePaddingY), longestMoveable+codeBlockHorizontalPadding, codeHeight )
                code[i][j]:setFillColor( codeBgColor[1], codeBgColor[2], codeBgColor[3], codeBgColor[4] or 1 )
                code[i][j].anchorX = 0
                code[i][j].text = t[i][j].s
            end
            
            local object = display.newText({
                parent = groupCode,
                text = t[i][j].s,
                x = lineStart[i]+prevX+(j-1)*codePaddingX,
                y = codeStartY+(i-1)*(codeHeight+codePaddingY),
                font = font,
                fontSize = codeSize,
            })
            object:setFillColor( codeColor[1], codeColor[2], codeColor[3], codeColor[4] or 1 )
            
            if isMoveable then
                object:addEventListener( "touch", dragCode )
                object.x = object.x + (longestMoveable+codeBlockHorizontalPadding)*0.5
                code[i][j].xReturn, code[i][j].yReturn = object.x, object.y
                code[i][j].ref = #codeBlock+1
                object.ref = {i,j}
                table.insert( codeBlock, object )
                prevX = prevX+longestMoveable+codeBlockHorizontalPadding
            else
                object.anchorX = 0
                table.insert( code[i], object )
                prevX = prevX+code[i][j].width
            end
        end
    end
    
    canTouch = true
    stopLoop = false
    transition.to( groupCode, {time=500,alpha=1,onComplete=runLoop})
end

newLoop( 1 )