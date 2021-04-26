display.setStatusBar( display.HiddenStatusBar )

local json = require( "json" )
local sfx = require("scripts.sfx")
local screen = require("scripts.screen")
local newRing = require("scripts.newRing")
local diggingPath = require("data.paths")

local font = "fonts/Amagro-bold.ttf"
local isBrowser = (system.getInfo( "environment" ) == "browser")

local getTimer = system.getTimer

local groupBG = display.newGroup()
local groupWorldBack = display.newGroup()
local groupPlayer = display.newGroup()
local groupWorldFront = display.newGroup()
local groupEmitter = display.newGroup()
local groupUI = display.newGroup()

-------------------------------------------------------------
-- Setting up stationary UI elements

local bgShading = display.newRect( groupBG, screen.centreX, screen.centreY, screen.width, screen.height )
bgShading:setFillColor(0)
bgShading.alpha = 0

-- Hacking by using a masks to hide the ugly "snap to transitions".
local maskTop = display.newImageRect( groupUI, "images/maskTop.png", 960, 256 )
maskTop.x, maskTop.y = screen.centreX, screen.minY
maskTop.anchorY = 0
maskTop.alpha = 0
local maskBottom = display.newImageRect( groupUI, "images/maskBottom.png", 960, 100 )
maskBottom.x, maskBottom.y = screen.centreX, screen.maxY
maskBottom.anchorY = 1

local gameoverBackground = display.newRect( groupUI, screen.centreX, screen.centreY, screen.width, screen.height )
gameoverBackground:setFillColor(0)
gameoverBackground.alpha = 0

local diggingCounter = display.newGroup()
groupUI:insert(diggingCounter)
diggingCounter.x, diggingCounter.y = screen.centreX, screen.maxY + 100

local diggingBG = display.newImageRect( diggingCounter, "images/timer.png", 256, 64 )
local diggingText = display.newText( diggingCounter, "", 0, 0 + (isBrowser and 2 or 0), font, 22 )
diggingText.anchorY = 1
local diggingMeter = display.newRect( diggingCounter, diggingBG.x, diggingBG.y + 10, 236, 20 )
diggingMeter.x = diggingBG.x - diggingBG.width*0.5 + (diggingBG.width-diggingMeter.width)*0.5
diggingMeter.maxWidth = diggingMeter.width
diggingMeter.anchorX = 0

-- Create a text object with a duplicate text as a shadow to make reading easier.
local function generateText( group, text, x, y, anchorX, anchorY, fontSize )
    local textObject = display.newGroup()
    textObject.x, textObject.y = x, y
    group:insert(textObject)
    
    textObject.back = display.newText( textObject, text, 1, 1, font, fontSize )
    textObject.back.anchorX, textObject.back.anchorY = anchorX, anchorY
    textObject.back:setFillColor(0)
    textObject.front = display.newText( textObject, text, 0, 0, font, fontSize )
    textObject.front.anchorX, textObject.front.anchorY = anchorX, anchorY
    
    function textObject:text(s)
        textObject.back.text = s
        textObject.front.text = s
    end
    
    return textObject
end

local goldCounter = generateText( diggingCounter, "0", diggingBG.x, diggingBG.y - diggingBG.height*0.5 - 8 + (isBrowser and 2 or 0), 0.5, 1, 30 )
local goldCounterCopy = generateText( groupUI, "0", screen.centreX, 540 - 4 + (isBrowser and 2 or 0), 0.5, 1, 30 )
goldCounterCopy.xStart, goldCounterCopy.yStart = goldCounterCopy.x, goldCounterCopy.y
goldCounterCopy.isVisible = false
local highscore = generateText( groupUI, "Highscore: 0", screen.minX + 10, screen.minY + 10 + (isBrowser and 2 or 0), 0, 0, 32 )
local lastScore = generateText( groupUI, "Last score: 0", highscore.x, highscore.y + highscore.height + 20 + (isBrowser and 2 or 0), 0, 0, 32 )

local howToPlay = generateText( groupUI, "Use arrow keys or WASD to move.", screen.centreX, screen.centreY - 100 + (isBrowser and 2 or 0), 0.5, 0.5, 32 )

-- Create and animate the logo
local logo = display.newImageRect( groupUI, "images/logo.png", 320, 128 )
logo.x, logo.y = screen.centreX, screen.minY + 10
logo.yStart = logo.y
logo.anchorY = 0
local logoT2
local function logoT1() 
    transition.to( logo, { time=500, xScale=1.05, yScale=1.05, transition=easing.inOutQuad, onComplete=function()
        logoT2()
    end })
end
function logoT2() 
    transition.to( logo, { time=500, xScale=0.95, yScale=0.95, transition=easing.inOutQuad, onComplete=function()
        logoT1()
    end })
end
logoT1()

-------------------------------------------------------------
-- Audio setup:

-- Creating audio button and function for controlling audio levels in the game.
local buttonAudio = display.newImageRect( groupUI, "images/logo.png", 48, 48 )
buttonAudio.x, buttonAudio.y = screen.maxX - buttonAudio.width*0.5 - 4, screen.minY + buttonAudio.height*0.5 + 4
buttonAudio.state = true
buttonAudio.fillOn = {
    type = "image",
    filename = "images/buttonMusicOn.png"
}
buttonAudio.fillOff = {
    type = "image",
    filename = "images/buttonMusicOff.png"
}
buttonAudio.fill = buttonAudio.fillOn

buttonAudio:addEventListener( "touch", function(event)
    if event.phase == "began" then
        event.target.state = not event.target.state
        if event.target.state then
            audio.setVolume( sfx.maxVolume )
            buttonAudio.fill = buttonAudio.fillOn
        else
            -- Lazy sound controller, i.e. everything plays, they are just quieted.
            audio.setVolume( 0 )
            buttonAudio.fill = buttonAudio.fillOff
        end
    end
end )

-------------------------------------------------------------
-- World generation, gameplay & other parameters:
local startingLayer = 5
local transitionTime = 150
local gameoverTransitionTime = 750
local timeBeforeGameover = 10000
local extraTimeFromGold = 500
-- local debugMode = true

-- NB! These settings are written for 960x640 content area.
local ringParameters = {
    groupBack = groupWorldBack,
    groupFront = groupWorldFront,
    radius = screen.width,
    ringCount = 12,
    thickness = 122,
    surfaceLayers = 2,
    segmentsPerRing = 24
}

-------------------------------------------------------------
-- Forward declaring variables.
local ring, ringScales, currentDifficulty, previousSegment, keyEvent
local activeLayer, activeColumn, goldCount, activeKey, gameover
local rotationAngle = 360/ringParameters.segmentsPerRing -- How many angles each rotation is.
local canMove, bgColourToggled, firstMove, startTime, bonusTime, timerStarted
local highscoreVal, lastScoreVal = 0, 0

-------------------------------------------------------------
-- Create particle emitters.

local function createEmitter( filename, x, y )
    local filePath = system.pathForFile( filename )
    local f = io.open( filePath, "r" )
    local emitterData = f:read( "*a" )
    f:close()
    local emitterParams = json.decode( emitterData )
     
    local emitter = display.newEmitter( emitterParams )
    groupEmitter:insert(emitter)
    emitter:stop()
    emitter.x = x
    emitter.y = y
    return emitter
end

local emitterGold = createEmitter( "data/particleGold.json", screen.centreX, screen.centreY )
local emitterGround = createEmitter( "data/particleGround.json", screen.centreX, screen.centreY )

-------------------------------------------------------------
-- Create character

local sheetOptions = {
    width = 64,
    height = 64,
    numFrames = 4,
    
    sheetContentWidth = 64,
    sheetContentHeight = 256
}
local sequenceData =
{
    name="idle",
    frames= { 1, 2, 1, 3, 1, 4 }, -- frame indexes of animation, in image sheet
    time = 500,
    loopCount = 0
}
local characterSheet = graphics.newImageSheet( "images/characterSheet.png", sheetOptions )

-- local player = display.newImageRect( groupPlayer, "images/character.png", 48, 48 )
local player = display.newSprite( characterSheet, sequenceData )
local playerScale = 48 / player.width
player.xScale, player.yScale = playerScale, playerScale
player.x = screen.centreX
player.isVisible = false
player:play()

-------------------------------------------------------------
-- General gameplay functions

-- enterFrame listener that updates the time left counter
local function update()
    local timeLeft = 1-(getTimer()-startTime-bonusTime)/(timeBeforeGameover)
    if timeLeft <= 0 then
        diggingText.text = "Out of time!"
        gameover()
        return
    end
    
    local r, g = 0, 1
    if timeLeft > 0.5 then
        r = (1 - timeLeft)*2
    else
        r = 1
        g = timeLeft*2
    end
    
    if timeLeft < 0.2 then
        diggingText.text = "Dig faster! Hurry!"
    elseif timeLeft < 0.5 then
        diggingText.text = "Deeper and deeper!"
    elseif timeLeft < 0.75 then
        diggingText.text = "Dig deeper!"
    end
    
    diggingMeter.width = diggingMeter.maxWidth*timeLeft
    diggingMeter:setFillColor( r, g, 0 )
end

-- Recreates the gameworld and sets it up for play.
local function generateWorld( seed )
    if type( seed ) == "number" then
        math.randomseed( seed )
    end
    
    if ring then
        for i = 1, #ring do
            for j = 1, #ring[i].overlay do
                display.remove(ring[i].overlay[j])
                display.remove(ring[i].backdrop[j])
            end
            display.remove(ring[i].back)
            display.remove(ring[i])
        end
        ring = nil
    end
    groupWorldBack.rotation = 0
    groupWorldFront.rotation = 0
    
    display.setDefault( "background", 96/255, 203/255, 239/255 )
    bgShading.alpha = 0
    maskTop.alpha = 0
    
    ring, ringScales = newRing.create( ringParameters, startingLayer )
    currentDifficulty = ringParameters.ringCount - ringParameters.surfaceLayers - startingLayer
    activeLayer = startingLayer
    activeColumn = 1
    canMove = true
    goldCount = 0
    activeKey = nil
    bgColourToggled = false
    bonusTime = 0
    firstMove = true
    goldCounter:text(0)
    goldCounter.isVisible = true
    timerStarted = false
    diggingText.text = "Dig for gold!"

    -- Position the world and calculate initial rotation values, plus how much to rate per move.
    local scaleFactor, playerStartY = 0, 0
    for i = 1, #ring do
        scaleFactor = scaleFactor + ring[i].xScale
        if i < startingLayer then
            playerStartY = playerStartY + ring[i].xScale*ringParameters.thickness
        elseif i == startingLayer then
            playerStartY = playerStartY + ring[i].xScale*ringParameters.thickness*0.5
        end
    end
    groupWorldBack.x, groupWorldBack.y = screen.centreX, screen.maxY + (groupWorldBack.height - scaleFactor*ringParameters.thickness*2 )*0.5
    groupWorldFront.x, groupWorldFront.y = groupWorldBack.x, groupWorldBack.y
    
    -- ring[activeLayer].overlay[activeColumn].bitmask = 0
    
    player.y = groupWorldBack.y - groupWorldBack.height*0.5 + playerStartY + 14
    player.startY = player.y
    player.isVisible = true
end

-- Handle all player movements and the related segment state and visual updates.
local function movePlayer( direction )
    local didMove = false
    if canMove then
        local impassable = false
        if direction == "down" then
            local nextLayer = activeLayer+1 > ringParameters.ringCount and 1 or activeLayer+1
            if not ring[nextLayer][activeColumn].isPassable then
                impassable = true
            else
                if firstMove then
                    firstMove = false
                    transition.to( player, { time=350, y=player.y - 12 } )
                    transition.to( howToPlay, { time=350, alpha=0 } )
                    transition.to( logo, { time=350, y=screen.minY - logo.height*2 } )
                end
                
                canMove = false
                currentDifficulty = currentDifficulty + 1
                if bgShading.alpha < 1 then
                    local alpha = (currentDifficulty - startingLayer)/5
                    transition.to( bgShading, { time=transitionTime, alpha=alpha  })
                    transition.to( maskTop, { time=transitionTime, alpha=alpha  })
                else
                    if not bgColourToggled then
                        bgColourToggled = true
                        display.setDefault( "background", 157/255, 120/255, 73/255  )
                    end
                end
                
                for i = 1, #ring do
                    local ringOverlay = ring[i]
                    local ringBack = ring[i].back
                    ringOverlay.layer = ringOverlay.layer-1 >= 1 and ringOverlay.layer-1 or ringParameters.ringCount
                    local scale = ringScales[ringOverlay.layer]
                    if ringOverlay.layer == ringParameters.ringCount then
                        ringOverlay:reset( currentDifficulty )
                        ringOverlay.isVisible = true
            			ringBack.isVisible = true
                        ringOverlay.xScale, ringOverlay.yScale = scale, scale
                        ringBack.xScale, ringBack.yScale = scale, scale
                        timer.performWithDelay( transitionTime, function() canMove = true end )
                    else
                        transition.to( ringOverlay, { time=transitionTime, xScale=scale, yScale=scale, transition=easing.inSine })
                        transition.to( ringBack, { time=transitionTime, xScale=scale, yScale=scale, transition=easing.inSine  })
                    end
                    
                end
                activeLayer = activeLayer+1
                if activeLayer > ringParameters.ringCount then
                    activeLayer = 1
                end
                didMove = true
            end
        else
            local nextColumn = activeColumn
            local rotateTo
            if direction == "left" then
                player.xScale = playerScale
                rotateTo = rotationAngle
                nextColumn = nextColumn-1
                if nextColumn < 1 then
                    nextColumn = ringParameters.segmentsPerRing
                end
            else
                player.xScale = -playerScale
                rotateTo = -1*rotationAngle
                nextColumn = nextColumn+1
                if nextColumn > ringParameters.segmentsPerRing then
                    nextColumn = 1
                end
            end
            
            if not ring[activeLayer].overlay[nextColumn].isPassable then
                impassable = true
            else
                canMove = false
                transition.to( groupWorldBack, { time=transitionTime, rotation=groupWorldBack.rotation + rotateTo, transition=easing.inSine, onComplete=function() canMove = true end })
                transition.to( groupWorldFront, { time=transitionTime, rotation=groupWorldFront.rotation + rotateTo, transition=easing.inSine })
                activeColumn = nextColumn
                didMove = true
            end
        end
        
        if didMove then
            local overlay = ring[activeLayer].overlay[activeColumn]
            local backdrop = ring[activeLayer].backdrop[activeColumn]
            if not overlay.isVisited then
                overlay.isVisited = true
                -- overlay.isVisible = false
                
                local whichAudio
                
                local activeEmitter = emitterGround
                if overlay.isGold then
                    whichAudio = sfx["gold"]
                    
                    goldCount = goldCount+1
                    goldCounter:text(goldCount)
                    goldCounter.front:setFillColor(1,210/255,0)
                    transition.from( goldCounter, { time=100, xScale=1.5, yScale=1.5, onComplete=function()
                        goldCounter.front:setFillColor(1)
                    end })
                    if timerStarted then
                        bonusTime = bonusTime + extraTimeFromGold
                    end
                    activeEmitter = emitterGold
                    
                    -- To make the game slightly easier at immediate start, only start
                    -- the timer after the player has already picked a few gold segments.
                    if not timerStarted and goldCount > 2 then
                        timerStarted = true
                        startTime = getTimer()
                        
                        transition.to( diggingCounter, {time=350, y=screen.maxY-64, transition=easing.inSine} )
                        diggingMeter:setFillColor(0,1,0)
                        Runtime:addEventListener( "enterFrame", update )
                        audio.play( sfx["timerStart"] )
                    end
                else
                    whichAudio = sfx["ground"]
                end
                audio.play( whichAudio )
                    
                ----------------------------------------------------------------------------------------------------------------
                -- We can get by using simple bitmasking value calculations since the player can only move left, right or down.
                -- This means that we only ever need to update the new segment where the player moves to, as well as the segment
                -- they were in before the move. Also, the game has a guaranteed impassable segment on every ring, so the player
                -- can't move to a visited segment from a previously unvisited segment.
                
                -- This means that all we need to do is take the bitmask value for the direction from where the player came from
                -- and apply this to the new segment's fill. Then we update the previous segment's fill by adding the direction
                -- to where the player moved to.
                ----------------------------------------------------------------------------------------------------------------
                
                local particleOffsetX = 78
                local dirComing, dirGoing
                if direction == "left" then
                    dirComing = 2
                    dirGoing = 4
                    activeEmitter.x = screen.centreX - particleOffsetX
                    activeEmitter.y = player.y
                elseif direction == "right" then
                    dirComing = 4
                    dirGoing = 2
                    activeEmitter.x = screen.centreX + particleOffsetX
                    activeEmitter.y = player.y
                else
                    dirComing = 1
                    dirGoing = 8
                    activeEmitter.x = screen.centreX
                    activeEmitter.y = player.y + 40
                end
                
                if previousSegment then
                    previousSegment.bitmask = previousSegment.bitmask + dirGoing
                    previousSegment.fill = diggingPath[previousSegment.bitmask]
                end
                backdrop.bitmask = dirComing
                backdrop.fill = diggingPath[dirComing]
                
                if ring[activeLayer].isVisible then
                    activeEmitter:start()
                end
                
                transition.to( overlay, { time=transitionTime, alpha=0, onComplete=function()
                    overlay.isVisible = false
                    overlay.alpha = 1
                end })
            end
            -- Store previous segment so that its digging path can be updated.
            previousSegment = backdrop
        end
    end
end

-- Prevent further gameplay actions, handle score and prepare to restart the game.
function gameover()
    Runtime:removeEventListener( "enterFrame", update )
    Runtime:removeEventListener( "key", keyEvent )
    audio.play( sfx["gameover"] )
    
    goldCounterCopy.x, goldCounterCopy.y = goldCounterCopy.xStart, goldCounterCopy.yStart
    goldCounterCopy:text(goldCount)
    goldCounterCopy.isVisible = true
    goldCounter.isVisible = false
    
    transition.to( goldCounterCopy, { delay=250, time=gameoverTransitionTime*0.5, x=240, y=88+goldCounterCopy.height*0.5, onComplete=function()
        transition.to( player, { time=350, y=player.startY } )
        transition.from( highscore, { time=100, xScale=1.5, yScale=1.5 })
        transition.from( lastScore, { time=100, xScale=1.5, yScale=1.5 })
        goldCounterCopy.isVisible = false
        
        
        if goldCount > highscoreVal then
            highscoreVal = goldCount
            highscore.front:setFillColor(1,210/255,0)
            highscore:text( "Highscore: " .. goldCount )
        else
            highscore.front:setFillColor(1)
        end
        if goldCount > lastScoreVal then
            lastScore.front:setFillColor(1,210/255,0)
        else
            lastScore.front:setFillColor(1)
        end
        lastScore:text("Last score: " .. goldCount)
        lastScoreVal = goldCount
    end })
    transition.to( diggingCounter, { delay=250, time=500, y=screen.maxY+100, transition=easing.outBack })
    transition.to( gameoverBackground, {time=firstMove and 0 or gameoverTransitionTime, alpha=1, onComplete=function()
        generateWorld()
        transition.to( howToPlay, { time=350, alpha=1 } )
        transition.to( logo, { time=350, y=logo.yStart } )
        transition.to( gameoverBackground, { delay=250, time=500, alpha=0, onComplete=function()
            Runtime:addEventListener( "key", keyEvent )
        end })
    end })
end

-- Keep track of currently held key and prevent additional keystrokes.
function keyEvent( event )
    if event.phase == "down" then
        if not activeKey then
            activeKey = event.keyName
            if activeKey == "a" or activeKey == "left" then
                movePlayer("left")
            elseif activeKey == "d" or activeKey == "right" then
                movePlayer("right")
            elseif activeKey == "s" or activeKey == "down" then
                movePlayer("down")
            elseif activeKey == "w" or activeKey == "up" then
                
            elseif activeKey == "q" then
                gameover()
            end
        end
    elseif event.phase == "up" and event.keyName == activeKey then
        activeKey = nil
    end
    return false
end

generateWorld()
Runtime:addEventListener( "key", keyEvent )
