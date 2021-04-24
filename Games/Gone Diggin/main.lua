display.setStatusBar( display.HiddenStatusBar )
display.setDefault( "background", 70/255, 189/255, 194/255 )


local screen = require("scripts.screen")
local newRing = require("scripts.newRing")

local groupBG = display.newGroup()
local groupWorld = display.newGroup()
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
-------------------------------------------------------------
-- World generation & other visual parameters:
local startingLayer = 5
local transitionTime = 150
local debugMode = true

-- NB! These settings are written for 960x640 content area.
local ringParameters = {
    parent = groupWorld,
    radius = screen.width,
    ringCount = 12,
    thickness = 122,
    surfaceLayers = 2,
    segmentsPerRing = 24
}
-------------------------------------------------------------
local currentDifficulty = ringParameters.ringCount - ringParameters.surfaceLayers - startingLayer
local rotationAngle = 360/ringParameters.segmentsPerRing -- How many angles each rotation is.
local activeLayer = startingLayer
local activeColumn = 1
local canMove = true
local bgColourToggled = false
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
groupWorld.x, groupWorld.y = screen.centreX, screen.maxY + (groupWorld.height - ringScale*ringParameters.thickness*2 )*0.5
groupWorld.rotationOffset = 360/ringParameters.segmentsPerRing*0.5
groupWorld.rotatingTo = groupWorld.rotation
-- groupWorld.rotation = -90-groupWorld.rotationOffset
local ringRotation = 360/ringParameters.segmentsPerRing

-- local groundBG = display.newCircle( groupBG, groupWorld.x, groupWorld.y, groupWorld.height*0.5 )


local player = display.newCircle( screen.centreX, groupWorld.y - groupWorld.height*0.5 + playerStartY, 24 )
player:setFillColor(0.8,0,0)


local debugText
if debugMode then
    debugText = display.newText( "", screen.centreX, screen.minY + 40, native.systemFontBold, 20 )
    debugText:setFillColor(0)
end


local function movePlayer( direction )
    local didMove = false
    if canMove then
        if direction == "down" then
            local nextLayer = activeLayer+1 > ringParameters.ringCount and 1 or activeLayer+1
            if not ring[nextLayer][activeColumn].isPassable then
                print("impassable")
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
                    local t = ring[i]
                    t.layer = t.layer-1 >= 1 and t.layer-1 or ringParameters.ringCount
                        local scale = ringScales[t.layer]
                    if t.layer == ringParameters.ringCount then
                        t:reset( currentDifficulty )
                        t.isVisible = true
                        -- TODO: See about fixing the bottom ring layer's non-easing bounce.
                        t.xScale, t.yScale = scale, scale
                        timer.performWithDelay( transitionTime, function() canMove = true end )
                    else
                        transition.to( t, { time=transitionTime, xScale=scale, yScale=scale, transition=easing.outBack })
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
                rotateTo = -rotationAngle
                nextColumn = nextColumn+1
                if nextColumn > ringParameters.segmentsPerRing then
                    nextColumn = 1
                end
            end
            
            if not ring[activeLayer][nextColumn].isPassable then
                print("impassable")
            else
                canMove = false
                groupWorld.rotatingTo = groupWorld.rotatingTo + rotateTo
                transition.to( groupWorld, { time=transitionTime, rotation=groupWorld.rotatingTo, transition=easing.outBack, onComplete=function() canMove = true end })
                activeColumn = nextColumn
                didMove = true
            end
        end
        if debugText then
            local t = ring[activeLayer][activeColumn]
            debugText.text = didMove and (t.isVisited and "Visited." or (t.isGold and "Found gold!" or "Just dirt.") or "")
        end
        
        -- TODO: what happens on movement to accessible segments?
        local t = ring[activeLayer][activeColumn]
        if not t.isVisited then
            t.isVisited = true
            -- TODO: add gold, dig dunnel & update nearby segments if necessary.
        end
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
                if debugText then
                    debugText.text = "No can do! This'll only go deeper!"
                end
            end
        end
    elseif event.phase == "up" and event.keyName == activeKey then
        activeKey = nil
    end
    return false
end
Runtime:addEventListener( "key", keyEvent )