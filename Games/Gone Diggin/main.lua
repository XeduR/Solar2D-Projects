display.setStatusBar( display.HiddenStatusBar )
display.setDefault( "background", 70/255, 189/255, 194/255 )


local screen = require("scripts.screen")
local newRing = require("scripts.newRing")
local diggingPath = require("data.paths")

local groupBG = display.newGroup()
local groupWorldBack = display.newGroup()
local groupPlayer = display.newGroup()
local groupWorldFront = display.newGroup()
local groupUI = display.newGroup()

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

local goldCounter = display.newText( groupUI, "0", screen.minX+10, screen.minY+10, native.systemFontBold, 30 )
goldCounter.anchorX, goldCounter.anchorY = 0, 0

local gameoverBackground = display.newRect( groupUI, screen.centreX, screen.centreY, screen.width, screen.height )
gameoverBackground:setFillColor(0)
gameoverBackground.alpha = 0

-------------------------------------------------------------
-- World generation & other visual parameters:
local startingLayer = 5
local transitionTime = 150
local gameoverTransitionTime = 0
local debugMode = true

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
local activeLayer, activeColumn, goldCount, activeKey
local rotationAngle = 360/ringParameters.segmentsPerRing -- How many angles each rotation is.
local canMove = true
local bgColourToggled = false
-------------------------------------------------------------


local player = display.newCircle( groupPlayer, screen.centreX, 0, 24 )
player:setFillColor(0.8,0,0)
player.isVisible = false



local debugText
if debugMode then
    debugText = display.newText( "", screen.centreX, screen.minY + 40, native.systemFontBold, 20 )
    debugText:setFillColor(0)
end

local function generateWorld( seed )
    if type( seed ) == "number" then
        math.randomseed( seed )
    end
    
    -- Reset the game world.
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
    
    display.setDefault( "background", 70/255, 189/255, 194/255 )
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
    goldCounter.text = "0"

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
    
    player.y = groupWorldBack.y - groupWorldBack.height*0.5 + playerStartY
    player.isVisible = true
end


local function movePlayer( direction )
    local didMove = false
    if canMove then
        local impassable = false
        if direction == "down" then
            local nextLayer = activeLayer+1 > ringParameters.ringCount and 1 or activeLayer+1
            if not ring[nextLayer][activeColumn].isPassable then
                impassable = true
            else
                canMove = false
                currentDifficulty = currentDifficulty + 1
                if bgShading.alpha < 1 then
                    local alpha = (currentDifficulty - startingLayer)/5
                    transition.to( bgShading, { time=transitionTime, alpha=alpha  })
                    transition.to( maskTop, { time=transitionTime, alpha=alpha  })
                else
                    if not bgColourToggled then
                        bgColourToggled = true
                        display.setDefault( "background", 0.5, 0.4, 0.25  )
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
                        transition.to( ringOverlay, { time=transitionTime, xScale=scale, yScale=scale, transition=easing.outBack })
                        transition.to( ringBack, { time=transitionTime, xScale=scale, yScale=scale, transition=easing.outBack })
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
                rotateTo = rotationAngle
                nextColumn = nextColumn-1
                if nextColumn < 1 then
                    nextColumn = ringParameters.segmentsPerRing
                end
            else
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
                transition.to( groupWorldBack, { time=transitionTime, rotation=groupWorldBack.rotation + rotateTo, transition=easing.outBack, onComplete=function() canMove = true end })
                transition.to( groupWorldFront, { time=transitionTime, rotation=groupWorldFront.rotation + rotateTo, transition=easing.outBack })
                activeColumn = nextColumn
                didMove = true
            end
        end
        if debugText then
            if impassable then
                debugText.text = "We can't dig there!"
            else
                local t = ring[activeLayer].overlay[activeColumn]
                debugText.text = didMove and (t.isVisited and "" or (t.isGold and "Found gold!" or "Just dirt.") or "")
            end
        end
        
        if didMove then
            local overlay = ring[activeLayer].overlay[activeColumn]
            local backdrop = ring[activeLayer].backdrop[activeColumn]
            if not overlay.isVisited then
                overlay.isVisited = true
                overlay.isVisible = false
                
                if overlay.isGold then
                    goldCount = goldCount+1
                    goldCounter.text = goldCount
                end
                
                ----------------------------------------------------------------------------------------------------------------
                -- We can get by using simple bitmasking value calculations since the player can only move left, right or down.
                -- This means that we only ever need to update the new segment where the player moves to, as well as the segment
                -- they were in before the move. Also, the game has a guaranteed impassable segment on every ring, so the player
                -- can't move to a visited segment from a previously unvisited segment.
                
                -- This means that all we need to do is take the bitmask value for the direction from where the player came from
                -- and apply this to the new segment's fill. Then we update the previous segment's fill by adding the direction
                -- to where the player moved to.
                ----------------------------------------------------------------------------------------------------------------
                
                local dirComing, dirGoing
                if direction == "left" then
                    dirComing = 2
                    dirGoing = 4
                elseif direction == "right" then
                    dirComing = 4
                    dirGoing = 2
                else
                    dirComing = 1
                    dirGoing = 8
                end
                
                if previousSegment then
                    previousSegment.bitmask = previousSegment.bitmask + dirGoing
                    previousSegment.fill = diggingPath[previousSegment.bitmask]
                end
                backdrop.fill = diggingPath[dirComing]
                backdrop.bitmask = dirComing
            end
            -- Store previous segment so that its digging path can be updated.
            previousSegment = backdrop
        end
    end
end

local function gameover()
    Runtime:removeEventListener( "key", keyEvent )
    transition.to( gameoverBackground, {time=gameoverTransitionTime,alpha=1, onComplete=function()
        generateWorld()
        gameoverBackground.alpha = 0
        Runtime:addEventListener( "key", keyEvent )
    end })
end

function keyEvent( event )
    if event.phase == "down" then
        -- Keep track of currently held key and prevent additional keystrokes.
        if not activeKey then
            activeKey = event.keyName
            if activeKey == "a" or activeKey == "left" then
                movePlayer("left")
            elseif activeKey == "d" or activeKey == "right" then
                movePlayer("right")
            elseif activeKey == "s" or activeKey == "down" then
                movePlayer("down")
            elseif activeKey == "w" or activeKey == "up" then
                if debugText then
                    debugText.text = "No can do! This'll only go deeper!"
                end
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
