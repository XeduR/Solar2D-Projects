display.setStatusBar( display.HiddenStatusBar )
display.setDefault( "background", 70/255, 189/255, 194/255 )

local screen = require("scripts.screen")
local newRing = require("scripts.newRing")

local background = display.newGroup()
local world = display.newGroup()

-- local mask = graphics.newMask( "images/mask.jpg" )
-- world:setMask( mask )

local shadeRect = display.newRect( background, screen.centreX, screen.centreY, screen.width, screen.height )
shadeRect:setFillColor(0)
shadeRect.alpha = 0

-------------------------------------------------------------
-- World generation values:
local startingLayer = 5

-- NB! These settings are written for 960x640 content area.
local ringParameters = {
    parent = world,
    radius = screen.width,
    ringCount = 12,
    thickness = 122,
    surfaceLayers = 2,
    segmentsPerRing = 32,
    debugInfo = true,
}
-------------------------------------------------------------
local currentDifficulty = ringParameters.ringCount - ringParameters.surfaceLayers - startingLayer
local activeLayer = startingLayer
local activeColumn = 1
-------------------------------------------------------------

local ring, ringScales = newRing.create( ringParameters, startingLayer )

-- Position the world and calculate initial rotation values, plus how much to rate per move.
local ringScale, playerStartY = 0, 0
for i = 1, #ring do
    ringScale = ringScale + ring[i].xScale
    if i < startingLayer then
        playerStartY = playerStartY + ring[i].xScale*ringParameters.thickness
    elseif i == startingLayer then
        playerStartY = playerStartY + ring[i].xScale*ringParameters.thickness*0.5
    end
end
world.x, world.y = screen.centreX, screen.maxY + (world.height - ringScale*ringParameters.thickness*2 )*0.5
world.rotationOffset = 360/ringParameters.segmentsPerRing*0.5
world.rotation = -90-world.rotationOffset
local ringRotation = 360/ringParameters.segmentsPerRing


local player = display.newCircle( screen.centreX, world.y - world.height*0.5 + playerStartY, 24 )
player:setFillColor(0.8,0,0)

-- world.maskX = world.x - 50
-- world.maskY = world.y - (world.height*0.5)

-- transition.to( world, {time=5000,rotation=world.rotation + 360})

local debugText
if ringParameters.debugInfo then
    debugText = display.newText( "", screen.centreX, screen.minY + 40, native.systemFontBold, 20 )
    debugText:setFillColor(0)
end


local function movePlayer( direction )
    local didMove = false
    if direction == "down" then
        local nextLayer = activeLayer+1 > ringParameters.ringCount and 1 or activeLayer+1
        if not ring[nextLayer][activeColumn].isPassable then
            print("impassable")
        else
            currentDifficulty = currentDifficulty + 1
            shadeRect.alpha = (currentDifficulty - startingLayer)/6
            
            for i = 1, #ring do
                local t = ring[i]
                t.layer = t.layer - 1
                if t.layer < 1 then
                    t:reset( currentDifficulty )
                    t.isVisible = true
                    t.layer = ringParameters.ringCount
                end
                local scale = ringScales[t.layer]
                t.xScale, t.yScale = scale, scale
            end
            activeLayer = activeLayer+1
            if activeLayer > ringParameters.ringCount then
                activeLayer = 1
            end
            didMove = true
        end
    else
        local nextColumn = activeColumn
        if direction == "left" then
            nextColumn = nextColumn-1
            if nextColumn < 1 then
                nextColumn = ringParameters.segmentsPerRing
            end
        else
            nextColumn = nextColumn+1
            if nextColumn > ringParameters.segmentsPerRing then
                nextColumn = 1
            end
        end
        
        if not ring[activeLayer][nextColumn].isPassable then
            print("impassable")
        else
            world.rotation = world.rotation + (direction == "left" and ringRotation or -ringRotation)
            activeColumn = nextColumn
            didMove = true
        end
    end
    if debugText then
        debugText.text = didMove and (ring[activeLayer][activeColumn].isGold and "Found gold!" or "Just dirt.") or ""
    end
end


-- Keep track of currently held key and prevent additional keystrokes.
local activeKey = nil
local function keyEvent( event )
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
                print("No can do! This'll only go deeper!")
            end
        end
    elseif event.phase == "up" and event.keyName == activeKey then
        activeKey = nil
    end
    return false
end
Runtime:addEventListener( "key", keyEvent )