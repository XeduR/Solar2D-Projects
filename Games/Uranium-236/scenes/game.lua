local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local sfx = require("classes.sfx")
local utils = require("libs.utils")
local loadsave

display.setDefault( "background", 0.075 )
local physics = require("physics")
physics.start()
physics.setGravity( 0, 0 )
physics.setReportCollisionsInContentCoordinates( true )
-- physics.setDrawMode( "hybrid" )

-- NB/TODO: audio bugs, audio is not always playing when game ends,
-- this is possibly due to too many audio handles being active at once.

---------------------------------------------------------------------------

-- Forward declarations & variables.
local groupHelaDagen = display.newGroup()
local groupBox = display.newGroup()
local groupBack = display.newGroup()
local groupObjects = display.newGroup()
local groupWalls = display.newGroup()
local groupWallOverlay = display.newGroup()
local groupCannon = display.newGroup()
local groupCore = display.newGroup()
local groupTouch = display.newGroup()
groupTouch.isVisible = false

-- Making new game / end game transition easier by stuffing everything into a single group:
groupHelaDagen:insert(groupBox)
groupHelaDagen:insert(groupBack)
groupHelaDagen:insert(groupObjects)
groupHelaDagen:insert(groupWalls)
groupHelaDagen:insert(groupWallOverlay)
groupHelaDagen:insert(groupCannon)
groupHelaDagen:insert(groupCore)

local gameoverBackground = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
gameoverBackground.isHitTestable = true
gameoverBackground.canPress = false
gameoverBackground.alpha = 0

local groupUI = display.newGroup()
groupWallOverlay.alpha = 0
groupUI.alpha = 0

-- Terrible way of forward declaring local variables (but lack of time plus Ludum Dare => terrible choices).
local furnace, core, coreBlur, coreEmitter, coreGlare, coreGlow, coreReaction, coreTransition, reactorBack, xedur, title, vent
local box, cordLeft, cordBottom, currentOutput, totalOutput, lastScore, gameoverReason, currentOutputTxt, totalOutputTxt, highscoreText, playAgain, startButtonBG, startButton
local wall, wallOverlay, sectorFront, sectorBack, leak, neutronCannon, neutron, spark, residue = {}, {}, {}, {}, {}, {}, {}, {}, {}
local score, scoreText = {}, {}

local random = math.random
local floor = math.floor
local sqrt = math.sqrt
local atan2 = math.atan2
local rad = math.rad
local cos = math.cos
local sin = math.sin

-- Reactor properties:
local xReactor = display.contentCenterX - 140
local yReactor = display.contentCenterY
local reactorRadius = 240
local wallThickness = 16
local wallCount = 32

-- Object properties:
local neutronRadius = 16
local neutronBaseSpeed = 70
local cannonFireInterval = 5000
local cannonFireVariance = 1000
local fireIntervalReduction = 2 -- This is deducted from cannonFireInterval every frame.

-- Neutron speed = neutronBaseSpeed +/- neutronSpeedVariance
local neutronSpeedVariance = 10
local neutronFireAngleVariance = 0.06 -- in radians.
local coreRadius = 50

local coreBlastArea = coreRadius*1.5 + neutronRadius*2

local scoreCount = 5 -- how many highscores are kept.
local wattPerTemp = 2500000 -- score value.
local timePerFrame = 1 / display.fps
local antineutronRate = 0.75

-- Core temperature settings:
local maxCoreTemp = 100
local startTemp = 20
local tempIncreasePerHit = 5 -- neutron hits core
local tempDecreasePerHit = 10 -- antineutron hits core
local tempDecreaseAmount = 0.03

-- NB! Automatically assigned properties (don't touch).
local gameover = true
local touchDistance = reactorRadius + wallThickness
local panelCount = wallCount*0.5
local wallWidth = 2*math.pi*reactorRadius/wallCount
local coreTemp = startTemp
local tempRate = coreTemp/maxCoreTemp
local neutronCount = 0
local currentFireInterval = cannonFireInterval

-- wallCount must be divisible by 4 so that panelCount is divisible by 2.
if wallCount % 4 ~= 0 then
    for i = 1, 10 do
        print( "ERROR: wallCount must be divisible by 4!" )
    end
end

-- Collision filters.
local filterParticle = { categoryBits=1, maskBits=7 }
local filterWalls = { categoryBits=2, maskBits=1 }
local filterTouch = { categoryBits=4, maskBits=1 }

---------------------------------------------------------------------------

-- New, experimental, and probably final control scheme:

-- Test and optional control method for the game.
local playerTouch = display.newImageRect( groupTouch, "assets/images/circleGlow.png", 64, 64 )
physics.addBody( playerTouch, "dynamic", {radius=playerTouch.width*0.5, density=1, bounce=1, friction=0, filter=filterTouch } )
playerTouch:setFillColor( 0.1, 0.5, 0.95 )

local prevX, prevY
local function moveField( event )
    if not playerTouch.isFocus then
        groupTouch.isVisible = true
        playerTouch.x, playerTouch.y = event.x, event.y
		display.getCurrentStage():setFocus( playerTouch )
		playerTouch.isFocus = true
		playerTouch.tempJoint = physics.newJoint( "touch", playerTouch, event.x, event.y )
        prevX, prevY = playerTouch.x, playerTouch.y

    else
		if event.phase == "moved" then
			playerTouch.tempJoint:setTarget( event.x, event.y )
        else
            groupTouch.isVisible = false
            -- Move the touch sensor away when the touch ends.
            playerTouch.x, playerTouch.y = 0, 0
			playerTouch.tempJoint:setTarget( 0, 0 )
        
            display.getCurrentStage():setFocus( nil )
            playerTouch.isFocus = false	
            playerTouch.tempJoint:removeSelf()
            
            playerTouch:setLinearVelocity(0,0)
        end

        if event.x ~= prevX or event.y ~= prevY then
            prevX, prevY = playerTouch.x, playerTouch.y
        end
    end

    return true
end

---------------------------------------------------------------------------

-- Functions.

-- local function releaseNeutron( target, x1, x2, y1, y2 )
--     display.getCurrentStage():setFocus( nil )
--     target.isFocus = false	
--     target.tempJoint:removeSelf()
-- 
--     -- As player lets go, cause a tiny "explosion" to push it somewhere.
--     local angle = atan2( y1-y2, x1-x2 )
-- 
--     -- Fire the neutron projectile from the cannon with slight variation in its angle and velocity.
--     target:setLinearVelocity(
--         cos(angle)*target.baseVelocity,
--         sin(angle)*target.baseVelocity
--     )
-- end

local function newNeutron( x, y, isAntineutron )
    
    local projectile
    if isAntineutron then
        projectile = display.newImageRect( groupObjects, "assets/images/antineutron.png", neutronRadius*2, neutronRadius*2 )
        projectile.isAntineutron = true
    else
        projectile = display.newImageRect( groupObjects, "assets/images/neutron.png", neutronRadius*2, neutronRadius*2 )
        projectile.isNeutron = true
    end
    projectile.isParticle = true
    
    projectile.x, projectile.y = x, y
    projectile.id = #neutron+1
    physics.addBody( projectile, "dynamic", { radius = neutronRadius, bounce = 1, friction = 0, filter = filterParticle } )
    projectile:toBack()
    
    -- Give the neutron some initial transition so that it doesn't just appear.
    projectile.xScale, projectile.yScale, projectile.alpha = 0.1, 0.1, 0
    transition.to( projectile, {time=200, alpha=1, xScale=1, yScale=1} )
    
    projectile.baseVelocity = neutronBaseSpeed+random(-neutronSpeedVariance,neutronSpeedVariance)
    
    -- Old, commented out control mechanic to directly drag the neutrons.
    -- local prevX, prevY
    -- function projectile.touch( self, event )
    -- 	local phase = event.phase
    -- 
    --     if phase == "began" then
    -- 		display.getCurrentStage():setFocus( self )
    -- 		self.isFocus = true
    -- 		self.tempJoint = physics.newJoint( "touch", self, event.x, event.y )
    --         prevX, prevY = self.x, self.y
    -- 
    --     elseif not self.isFocus then
    -- 		display.getCurrentStage():setFocus( self )
    -- 		self.isFocus = true
    -- 		self.tempJoint = physics.newJoint( "touch", self, event.x, event.y )
    --         prevX, prevY = self.x, self.y
    -- 
    --     else
    -- 		if phase == "moved" then
    -- 			self.tempJoint:setTarget( event.x, event.y )
    -- 
    --             local distance = sqrt((event.x - core.x)*(event.x - core.x) + (event.y - core.y)*(event.y - core.y))
    --             if distance > touchDistance then
    --                 releaseNeutron( self, event.x, prevX, event.y, prevY )
    --             end
    --         else
    --             releaseNeutron( self, event.x, prevX, event.y, prevY )
    --         end
    -- 
    --         if event.x ~= prevX or event.y ~= prevY then
    --             prevX, prevY = self.x, self.y
    --         end
    --     end
    -- 
    --     return true
    -- end
    -- projectile:addEventListener( "touch" )
    
    neutronCount = projectile.id
    neutron[projectile.id] = projectile
    return projectile
end

local function newCannon( position )
    -- position defines the position on the wall based on angle (degree).
    local angle = rad( position )
    local x, y = xReactor + cos(angle)*reactorRadius, yReactor + sin(angle)*reactorRadius
    
    local cannon = display.newGroup()
    cannon.xStart, cannon.yStart, cannon.rStart = x, y, position
    cannon.rotation = position
    cannon.x, cannon.y = x, y
    groupCannon:insert(cannon)
    
    -- Push the cords further inside the walls.
    local cords = display.newImageRect( cannon, "assets/images/cords.png", 100, 128 )
    cords.x = -16
    cords.anchorX = 0
    
    local nozzle = display.newImageRect( cannon, "assets/images/nozzle.png", 40, 40 )
    cannon.overlay = display.newImageRect( cannon, "assets/images/nozzleOverlay.png", 40, 40 )
    cannon.overlay.alpha = 0
    
    cannon.indicator = display.newImageRect( cannon, "assets/images/indicator.png", 16, 16 )
    cannon.indicator.alpha = 0
    
    local xSpawn = xReactor + cos(angle)*(reactorRadius-nozzle.width*0.5)
    local ySpawn = yReactor + sin(angle)*(reactorRadius-nozzle.width*0.5)
    local angleFiring = atan2( yReactor - ySpawn, xReactor - xSpawn )
    
    function cannon.fire( self, firstShot )
        cannon.indicator.xScale = 0.5
        cannon.indicator.yScale = 0.5
        cannon.indicator.alpha = 0
        
        local isAntineutron = (not firstShot and random() < antineutronRate)
        if isAntineutron then
            cannon.indicator:setFillColor(0,0.9,1)
        else
            cannon.indicator:setFillColor(1,0.9,0)
        end
        
        -- Set the cannon to fire again.
        transition.to( cannon.indicator, {
            time = not firstShot and (currentFireInterval+random(cannonFireVariance)) or 0,
            xScale = 1,
            yScale = 1,
            alpha = 1,
            onComplete = function()
                local projectile = newNeutron( xSpawn, ySpawn, isAntineutron )
                -- Fire the neutron projectile from the cannon with slight variation in its angle and velocity.
                projectile:setLinearVelocity(
                    cos(angleFiring+random(-neutronFireAngleVariance,neutronFireAngleVariance))*projectile.baseVelocity,
                    sin(angleFiring+random(-neutronFireAngleVariance,neutronFireAngleVariance))*projectile.baseVelocity
                )
                
                cannon.fire()
            end 
        } )
    end
    
    return cannon
end

local stopGame

local reactorCold = false
local function enterFrameUpdate()
    -- Update temperature.
    coreTemp = coreTemp - tempDecreaseAmount
    if coreTemp <= 0 or coreTemp >= maxCoreTemp then
        stopGame( coreTemp <= 0 )
    end
    
    -- Reduce the cannon firing delay.
    currentFireInterval = currentFireInterval - fireIntervalReduction
    -- Animate the player touch area.
    playerTouch.xScale, playerTouch.yScale, playerTouch.alpha = random(95,105)*0.01, random(95,105)*0.01, random(35,50)*0.01
    
    -- Increase the visibility of the wall overlay and adjust all colours.
    tempRate = coreTemp/maxCoreTemp
    groupWallOverlay.alpha = tempRate*1.5
    core:setFillColor( 1, tempRate, 0 )
    coreGlow:setFillColor( 1, 0.8*(1-tempRate), 0 )
    coreGlow.alpha = tempRate*0.25
    
    for i = 1, #wallOverlay do
        wallOverlay[i]:setFillColor( 1, 0.8*(1-tempRate), 0 )
    end
    ventOverlay.alpha = tempRate*1.5
    ventOverlay:setFillColor( 1, 0.8*(1-tempRate), 0 )
    
    for i = 1, #neutronCannon do
        neutronCannon[i].overlay:setFillColor( 1, 0.8*(1-tempRate), 0 )
        neutronCannon[i].overlay.alpha = tempRate*1.5
    end
    
    currentOutputTxt:setFillColor( 1, 0.8*(1-tempRate), 0 )
    totalOutputTxt:setFillColor( 1, 0.8*(1-tempRate), 0 )
    
    -- Update energy/score counters.
    currentOutput = floor( coreTemp*wattPerTemp*timePerFrame )
    totalOutput = totalOutput + currentOutput

    currentOutputTxt.text = string.formatThousands( currentOutput, " " ) .. " kW"
    totalOutputTxt.text = string.formatThousands( totalOutput, " " ) .. " kWh"

    local xStart, yStart = coreEmitter.xStart, coreEmitter.yStart
    
    -- Move the core emitter around a bit.
    local scale = random(95,105)*0.01
    coreEmitter.x, coreEmitter.y = xStart + random(-2,2), yStart + random(-2,2)
    coreEmitter.xScale, coreEmitter.yScale = scale*(1+tempRate*0.3), scale*(1+tempRate*0.3)
    
    -- The core's "glare" effect will grow larger as temperature goes up.
    coreGlare.x, coreGlare.y = xStart + random(-3,3), yStart + random(-3,3)
    if not gameover then
        coreGlare.xScale, coreGlare.yScale = scale*(1+tempRate), scale*(1+tempRate)
    end
    
    -- Adjust core blur and glow.
    coreBlur.x, coreBlur.y = xStart + random(-2,2), yStart + random(-2,2)
    coreGlow.x, coreGlow.y = xStart + random(-1,1), yStart + random(-1,1)
    coreGlow.xScale, coreGlow.yScale = scale, scale
        
    -- "Jiggle around" the reactor components.
    ------------------------------------------
    if tempRate < 0.2 then
        reactorCold = true
        groupCore.alpha = tempRate*5
    else
        if reactorCold then
            reactorCold = false
            groupCore.alpha = 1
        end
        -- Set caps for x, y and rotation changes.
        local dx, dy, dr
        local leakAlpha = 0
        
        if tempRate > 0.85 then
            dx, dy, dr = 5, 5, 3
            leakAlpha = 0.8
        elseif tempRate > 0.6 then
            dx, dy, dr = 4, 4, 2
            leakAlpha = 0.5
        elseif tempRate > 0.45 then
            dx, dy, dr = 3, 3, 2
            leakAlpha = 0.2
        elseif tempRate > 0.3 then
            dx, dy, dr = 2, 2, 1
        else
            dx, dy, dr = 0, 0, 1
        end
        
        for i = 1, #wall do
            local xBounce, yBounce, rBounce = random(-dx,dx), random(-dy,dy), random(-dr,dr)
            local obj, overlay = wall[i], wallOverlay[i]
            local x, y, r = obj.xStart + xBounce, obj.yStart + yBounce, obj.rStart + rBounce
            obj.x, obj.y, obj.rotation, overlay.x, overlay.y, overlay.rotation = x, y, r, x, y, r
        end
        
        for i = 1, #sectorBack do
            local xBounce, yBounce, rBounce = random(-dx,dx), random(-dy,dy), random(-dr,dr)
            local obj = sectorBack[i]
            obj.x, obj.y, obj.rotation = obj.xStart + xBounce, obj.yStart + yBounce, obj.rStart + rBounce
        end
        
        for i = 1, #neutronCannon do
            local xBounce, yBounce, rBounce = random(-dx,dx), random(-dy,dy), random(-dr,dr)
            local obj = neutronCannon[i]
            obj.x, obj.y, obj.rotation = obj.xStart + xBounce, obj.yStart + yBounce, obj.rStart + rBounce
        end
        
        for i = 1, #leak do
            leak[i].rotation = random(360)
            leak[i].alpha = leak[i].baseAlpha*leakAlpha
        end
        
        -- And jiggle the box and its cords too.
        groupBox.x, groupBox.y, groupBox.rotation = groupBox.xStart + random(-dx,dx), groupBox.yStart + random(-dy,dy), groupBox.rStart + random(-dr,dr)
        cordLeft.x, cordLeft.y, cordLeft.rotation = cordLeft.xStart + random(-dx,dx), cordLeft.yStart + random(-dy,dy), cordLeft.rStart + random(-dr,dr)
        cordBottom.x, cordBottom.y, cordBottom.rotation = cordBottom.xStart + random(-dx,dx), cordBottom.yStart + random(-dy,dy), cordBottom.rStart + random(-dr,dr)

        -- Let's shake all the groups for some extra measure.
        groupHelaDagen.x, groupHelaDagen.y = random(-dx,dx), random(-dy,dy)
        
        -- If these aren't shaken at all, it'll just feel odd.
        xedur.x, xedur.y, xedur.rotation = xedur.xStart + random(-dx,dx), xedur.yStart + random(-dy,dy), random(-dr,dr)
        title.x, title.y, title.rotation = title.xStart + random(-dx,dx), title.yStart + random(-dy,dy), random(-dr,dr)
    end
end

local function resetObjects()
    groupHelaDagen.x, groupHelaDagen.y = 0, 0
    gameoverBackground.alpha = 1
    ventOverlay.alpha = 0
    title:setFillColor(1)
    
    -- Reset the reactor components.
    for i = 1, #wall do
        local obj, overlay = wall[i], wallOverlay[i]
        local x, y, r = obj.xStart, obj.yStart, obj.rStart
        obj.x, obj.y, obj.rotation, overlay.x, overlay.y, overlay.rotation = x, y, r, x, y, r
    end
    groupWallOverlay.alpha = 0
    
    for i = 1, #sectorBack do
        local obj = sectorBack[i]
        obj.x, obj.y, obj.rotation = obj.xStart, obj.yStart, obj.rStart
    end
    
    for i = 1, #neutronCannon do
        local obj = neutronCannon[i]
        obj.x, obj.y, obj.rotation = obj.xStart, obj.yStart, obj.rStart
        obj.indicator.alpha = 0
        obj.overlay.alpha = 0
    end
    
    for i = 1, #leak do
        leak[i].alpha = 0
    end
    
    -- Reset core's elements.
    core.alpha, core.xScale, core.yScale, core.x, core.y = 0, 0.01, 0.01, xReactor, yReactor
    core.alpha, core.xScale, core.yScale, core.x, core.y = 0, 0.01, 0.01, xReactor, yReactor
    coreBlur.alpha, coreBlur.xScale, coreBlur.yScale, coreBlur.x, coreBlur.y = 0, 0.01, 0.01, xReactor, yReactor
    coreEmitter.alpha, coreEmitter.xScale, coreEmitter.yScale, coreEmitter.x, coreEmitter.y = 0, 0.01, 0.01, xReactor, yReactor
    coreReaction.alpha, coreReaction.xScale, coreReaction.yScale, coreReaction.x, coreReaction.y = 0, 0.01, 0.01, xReactor, yReactor
    coreGlow.alpha, coreGlow.xScale, coreGlow.yScale, coreGlow.x, coreGlow.y = 0, 0.01, 0.01, xReactor, yReactor
    coreGlare.alpha, coreGlare.xScale, coreGlare.yScale, coreGlare.x, coreGlare.y = 0, 0.01, 0.01, xReactor, yReactor
    coreTransition = nil
    
    -- Reset the "box" and its parts.
    currentOutputTxt.text = "START THE REACTOR"
    currentOutputTxt:setFillColor( 1, 0.8, 0 )
    totalOutputTxt.text = "START THE REACTOR"
    totalOutputTxt:setFillColor( 1, 0.8, 0 )
    groupBox.x, groupBox.y, groupBox.rotation = groupBox.xStart, groupBox.yStart, groupBox.rStart
    cordLeft.x, cordLeft.y, cordLeft.rotation = cordLeft.xStart, cordLeft.yStart, cordLeft.rStart
    cordBottom.x, cordBottom.y, cordBottom.rotation = cordBottom.xStart, cordBottom.yStart, cordBottom.rStart
end


local firstLaunch = true
local order = {}
local function startGame()
    -- Ignite the reactor.
    coreBlur.alpha, coreBlur.xScale, coreBlur.yScale, coreBlur.x, coreBlur.y = coreBlur.alphaStart, 1, 1, xReactor, yReactor
    coreEmitter.alpha, coreEmitter.xScale, coreEmitter.yScale, coreEmitter.x, coreEmitter.y = coreEmitter.alphaStart, 1, 1, xReactor, yReactor
    coreReaction.alpha, coreReaction.xScale, coreReaction.yScale, coreReaction.x, coreReaction.y = coreReaction.alphaStart, 1, 1, xReactor, yReactor
    coreGlow.alpha, coreGlow.xScale, coreGlow.yScale, coreGlow.x, coreGlow.y = coreGlow.alphaStart, 1, 1, xReactor, yReactor
    coreGlare.alpha, coreGlare.xScale, coreGlare.yScale, coreGlare.x, coreGlare.y = coreGlare.alphaStart, 1, 1, xReactor, yReactor
    coreTransition = nil
    
    -- Fire the fire cannon straight away and ensure that it will be neutron.
    local firstCannon = neutronCannon[order[1]]
    firstCannon.indicator:setFillColor(1,0.95,0)
    transition.to( firstCannon.indicator, {time=1000, alpha=1, onComplete=function()
        firstCannon.fire( nil, true )
    end })
    
    for i = 2, #neutronCannon do
        local n = order[i]
        timer.performWithDelay( currentFireInterval*0.25*i+random(cannonFireVariance), function()
            -- Increase the chances that the other first shots are neutrons.
            neutronCannon[n].fire( nil, random() > 0.3 )
        end )
    end
    
    Runtime:addEventListener( "touch", moveField )
    Runtime:addEventListener( "enterFrame", enterFrameUpdate )
end


local function newGame()
    resetObjects()

    transition.to( furnace, {time=8000, rotation=furnace.rotation+360, iterations=0 } )
    
    local timeFade, timeReveal
    if firstLaunch then
        timeFade = 0
        timeReveal = 0
    else
        groupHelaDagen.y = screen.height
        timeFade = 750
        timeReveal = 500
    end
    currentFireInterval = cannonFireInterval
    currentOutput = 0
    totalOutput = 0
    coreTemp = startTemp
    tempRate = coreTemp/maxCoreTemp
    neutronCount = 0
    gameover = false
    
    -- Shuffle the cannon firing order.
    for i = 1, #neutronCannon do
        order[i] = i
    end
    
    function shuffle(t)
        for i = #t, 2, -1 do
            local j = random(i)
            t[i], t[j] = t[j], t[i]
        end
    end
    shuffle(order)
    
    startButton.x, startButton.y = startButtonBG.x, startButtonBG.y
    transition.to( groupUI, {time=timeFade, alpha=0 })
    transition.to( gameoverBackground, { time=timeFade, alpha=0, onComplete=function()
        transition.to( groupHelaDagen, { time=timeReveal, y=0, transition=easing.inOutBack, onComplete=function()
            startButton.canPress = true
        end })
    end })
    firstLaunch = false
end

local function showScores( coreFroze )
    -- Figure out if there's a new high score to show.   
    local pos
    for i = 1, scoreCount do
        if not score[i] or totalOutput > score[i] then
            pos = i
            break
        end
    end
    
    -- Ensure that all texts are visible (counter transition.blink lazily).
    for i = 1, #scoreText do
        scoreText[i].alpha = 1
    end
    
    -- If there is a new highscore, then add it to the scores.
    if pos then
        table.insert( score, pos, totalOutput )
        if #score > scoreCount then
            score[#score] = nil
        end
        
        for i = pos, #score do
            scoreText[i].text =  "#" .. i .. "   -   " .. string.formatThousands( score[i], " " ) .. " kWh"
        end
        
        loadsave.save( score, "score.json" )
        transition.blink( scoreText[pos], { time=2000 } )
    end
    gameoverReason.text = coreFroze and "THE CORE FROZE!" or "THE CORE BLEW UP!"
    lastScore.text = "ENERGY GENERATED LAST ROUND: " .. string.formatThousands( totalOutput, " " ) .. " kWh"
    
    gameoverBackground.alpha = 1 -- NB! there's an issue with this, so hardsetting it to visible makes it touchable.
    playAgain.alpha = 0
    gameoverBackground.canPress = false
    transition.to( groupUI, {time=1500, alpha=1, onComplete=function()
        transition.to( playAgain, {time=500, alpha=1, onComplete=function()
            gameoverBackground.canPress = true
            transition.blink( playAgain, { time=1500 } )
        end})
    end})    
end


function stopGame( coreFroze )    
    gameover = true
    groupTouch.isVisible = false
    Runtime:removeEventListener( "touch", moveField )
    Runtime:removeEventListener( "enterFrame", enterFrameUpdate )
    transition.cancelAll()
    timer.cancelAll()
    
    -- If touch focus was left active, remove it.
    if playerTouch.isFocus then
        display.getCurrentStage():setFocus( nil )
        playerTouch.isFocus = false	
        playerTouch.tempJoint:removeSelf()
    end
    
    for i = 1, neutronCount do
        if neutron[i] then
            transition.to( neutron[i], {time=250, alpha=0 })
        end
    end
    for i = 1, #spark do
        if neutron[i] then
            transition.to( spark[i], {time=250, alpha=0 })
        end
    end
    for i = 1, #residue do
        if neutron[i] then
            transition.to( residue[i], {time=250, alpha=0 })
        end
    end
    
    -- Determine scale factor based on coreGlare's size so that it'll cover the entire screen.
    local scaleFactor = display.actualContentWidth/coreGlare.width*2
    local time = 350
    
    if coreFroze then
        sfx.play("assets/audio/froze.wav")
        
        -- Adjust text colours based on gameover reason.
        gameoverBackground:setFillColor(0)
        title:setFillColor(1)
        gameoverReason:setFillColor( 0.5, 1, 1 )
        highscoreText:setFillColor(1)
        lastScore:setFillColor(1)
        playAgain:setFillColor(1)
        
        for i = 1, scoreCount do
            scoreText[i]:setFillColor(1)
        end                
    else
        sfx.play("assets/audio/meltdown.wav")
        
        -- Adjust text colours based on gameover reason.
        gameoverBackground:setFillColor(1)
        title:setFillColor(0)
        gameoverReason:setFillColor( 0.9, 0, 0 )
        highscoreText:setFillColor(0)
        lastScore:setFillColor(0)
        playAgain:setFillColor(0)
        
        for i = 1, scoreCount do
            scoreText[i]:setFillColor(0)
        end
    end
    transition.to( gameoverBackground, { delay=time, time=time, alpha=1  })
    
    -- Start gameover transitions.
    transition.to( core, { time=time, xScale=scaleFactor, yScale=scaleFactor, transition=easing.inBack  })
    transition.to( coreEmitter, { time=time, xScale=scaleFactor, yScale=scaleFactor, transition=easing.inBack  })
    transition.to( coreGlare, { time=time, xScale=scaleFactor, yScale=scaleFactor, transition=easing.inBack, onComplete=function()
        -- Remove the remaining neutrons, sparks and residue.
        for i = 1, #spark do
            display.remove(spark[i])
            spark[i] = nil
        end
        for i = 1, #residue do
            display.remove(residue[i])
            residue[i] = nil
        end
        for i = 1, neutronCount do
            display.remove(neutron[i])
            neutron[i] = nil
        end
        
        -- Reset the splash & title separately from the rest.
        xedur.x, xedur.y, xedur.rotation = xedur.xStart, xedur.yStart, 0
        title.x, title.y, title.rotation = title.xStart, title.yStart, 0
        
        showScores( coreFroze )
    end })
end

---------------------------------------------------------------------------

function scene:create( event )
    local sceneGroup = self.view
    -- If the project uses savedata, then load existing data or set it up.
    if event.params and event.params.usesSavedata then
        loadsave = require("classes.loadsave")
        score = loadsave.load("score.json") or {}
    end
    
end

---------------------------------------------------------------------------

local function ventRemoveParticle( target )
    -- Keep trying to remove the body.
    if not ( physics.removeBody( target ) ) then
        timer.performWithDelay( 1, function()
            ventRemoveParticle( target )
        end )
    else
        sfx.play("assets/audio/vent.wav")
        target.isRemoved = true
        
        transition.to( target, { time=250, alpha=0, x=vent.x, y=vent.y, onCompete=function()
            display.remove( target )
        end })
    end
end

local function onCollision( event )
    if event.phase == "began" and not gameover then        
        -- Neutron collides with the core.
        if event.object1.isCore then
            display.remove( event.object2 )
            event.object2.isRemoved = true
            -- neutron[event.object2.id] = nil -- remove on gameover.
            
            if event.object2.isAntineutron then
                sfx.play("assets/audio/remove"..random(3)..".wav")
                coreTemp = coreTemp - tempDecreasePerHit
                coreReaction:setFillColor( 0, 0.75, 0.95 )
            else
                sfx.play("assets/audio/core"..random(3)..".wav")
                coreTemp = coreTemp + tempIncreasePerHit
                coreReaction:setFillColor( 0.95, 0.75, 0 )
            end
            
            if not coreTransition then
                coreTransition = transition.from( coreReaction, {time=150, alpha=1, xScale=1.25, yScale=1.25, onComplete=function()
                    coreTransition = nil
                end })
            end
            
            
            for i = 1, random(3,5) do
                -- Create residue on core collisions.
                local r = display.newCircle( groupObjects, event.x + random(-3,3), event.y + random(-3,3), random(6,10) )
                r:setFillColor( random(0,15)*0.01, random(30,50)*0.01 )
                
                residue[#residue+1] = r
                
                transition.to( r, {time=random(350,500), y=r.y+random(130,160), alpha=0, onComplete=function()
                    display.remove(r)
                end })
            end
            
            -- Push neutrons that are too close to core away.
            for i = 1, #neutron do
                local obj = neutron[i]
                if obj and not obj.isRemoved then
                    local distance = sqrt((obj.x - core.x)*(obj.x - core.x) + (obj.y - core.y)*(obj.y - core.y))
                    if distance < coreBlastArea then
                        local angle = atan2( obj.y - core.y, obj.x - core.x )
                        obj:setLinearVelocity(
                            cos(angle)*obj.baseVelocity,
                            sin(angle)*obj.baseVelocity
                        )
                    end
                end
            end
            
            if not gameover and event.object2.isNeutron then
                -- Nuclear fission time, spawn 3 neutrons from core.
                for i = 1, 3 do
                    -- Spawn the neutron near the core's outer edge.
                    timer.performWithDelay( 1, function()
                        local angle = rad(random(360))
                        local radius = core.width*0.5 + neutronRadius*1.5
                        local x, y = cos(angle)*radius, sin(angle)*radius
                
                        -- Core spawns only neutrons.
                        local projectile = newNeutron( core.x + x, core.y + y, false )
                        
                        -- Fire the neutron projectile from the cannon with slight variation in its angle and velocity.
                        projectile:setLinearVelocity(
                            cos(angle)*projectile.baseVelocity,
                            sin(angle)*projectile.baseVelocity
                        )
                
                    end )
                end
            end
        
        -- Collision with vent, so get rid of the particle.
        elseif event.object1.isVent and event.object2.isParticle then
            timer.performWithDelay( 1, function()
                ventRemoveParticle( event.object2 )
            end )
        else
            
            if event.object1.isParticle and event.object2.isParticle then
                if (event.object1.isNeutron and event.object2.isAntineutron) or (event.object2.isNeutron and event.object1.isAntineutron) then
                    -- Destroy opposing particles.
                    sfx.play("assets/audio/bump"..random(3)..".wav")
                    display.remove( event.object1 )
                    event.object1.isRemoved = true
                    display.remove( event.object2 )
                    event.object2.isRemoved = true
                else
                    sfx.play("assets/audio/remove"..random(3)..".wav")
                end
                
            else
                sfx.play("assets/audio/bump"..random(3)..".wav")
            end
            
            
            -- Create a new "spark" on the collision location.
            local t = display.newImageRect( groupCore, "assets/images/circleGlow.png", neutronRadius*1.5, neutronRadius*1.5 )
            t.x, t.y = event.x, event.y
            t:toBack()
            spark[#spark+1] = t
            transition.to( t, { time=150, xScale=0.1, yScale=0.1, alpha=0, onComplete=function()
                display.remove(t)
                t = nil
            end })
            
        end

    end
end


local function pressPlayAgain( event )
    if event.phase == "began" and event.target.canPress then
        sfx.play("assets/audio/newGame.wav")
        event.target.canPress = false
        newGame()
    end
end


local function createTexts()
    highscoreText = display.newText( groupUI, "YOUR HIGH SCORES:", display.contentCenterX, screen.minY + 70, "assets/fonts/PathwayGothicOne-Regular.ttf", 40 )  
    highscoreText:setFillColor(0)
    
    for i = 1, scoreCount do
        scoreText[i] = display.newText( groupUI, "#" .. i .. "   -   " .. (string.formatThousands( score[i], " " ) or "0") .. " kWh", display.contentCenterX, highscoreText.y + 80 + (i-1)*48, "assets/fonts/PathwayGothicOne-Regular.ttf", 26 )        
        scoreText[i]:setFillColor(0)
    end
    
    gameoverReason = display.newText( groupUI, "placeholder", display.contentCenterX, scoreText[#scoreText].y + 72, "assets/fonts/PathwayGothicOne-Regular.ttf", 36 )        
    
    -- Rewrote the texts, left this as is due to time constraints.
    lastScore = display.newText(
        {
            parent = groupUI,
            text = "placeholder",
            x = display.contentCenterX,
            y = gameoverReason.y + 50,
            font = "assets/fonts/PathwayGothicOne-Regular.ttf",
            align = "center",
            fontSize = 30
        }
    )
    lastScore.anchorY = 0
    lastScore:setFillColor(0)
    
    playAgain = display.newText( groupUI, "PLAY AGAIN", display.contentCenterX, lastScore.y + lastScore.height + 60, "assets/fonts/PathwayGothicOne-Regular.ttf", 40 )  
    playAgain:setFillColor(0)
end


function scene:show( event )
    local sceneGroup = self.view
    
    if event.phase == "will" then
        -- If coming from launchScreen scene, then start by removing it.
        if composer._previousScene == "scenes.launchScreen" then
            composer.removeScene( "scenes.launchScreen" )
        end
        
    elseif event.phase == "did" then
        
        xedur = display.newImageRect( "assets/images/launchScreen/XeduR.png", 256, 128 )
        xedur.x, xedur.y = screen.maxX - xedur.width*0.5 - 40, screen.minY + xedur.height*0.5
        xedur.xStart, xedur.yStart = xedur.x, xedur.y
        
        title = display.newText( "LD49: Uranium-236", xedur.x, xedur.y + xedur.height*0.5, "assets/fonts/PathwayGothicOne-Regular.ttf", 20 )        
        title.anchorY = 0
        title.xStart, title.yStart = title.x, title.y
        
        box = display.newImageRect( groupBox, "assets/images/box.png", 248, 400 )
        
        groupBox.x, groupBox.y = xedur.x, title.y + box.height*0.5 + 40
        groupBox.xStart, groupBox.yStart, groupBox.rStart = groupBox.x, groupBox.y, groupBox.rotation
        
        currentOutputTxt = display.newText( groupBox, "START THE REACTOR", box.x + 90, box.y - 102, "assets/fonts/PathwayGothicOne-Regular.ttf", 26 )        
        currentOutputTxt.anchorX = 1
        currentOutputTxt:setFillColor( 1, 0.8, 0 )
        
        totalOutputTxt = display.newText( groupBox, "START THE REACTOR", box.x + 90, box.y + 13, "assets/fonts/PathwayGothicOne-Regular.ttf", 26 )        
        totalOutputTxt.anchorX = 1
        totalOutputTxt:setFillColor( 1, 0.8, 0 )
        
        cordLeft = display.newImageRect( groupBox, "assets/images/cordLeft.png", 200, 100 )
        cordLeft.x, cordLeft.y = -140, -12
        cordLeft.xStart, cordLeft.yStart, cordLeft.rStart = cordLeft.x, cordLeft.y, cordLeft.rotation
        cordLeft:toBack()
        
        cordBottom = display.newImageRect( groupBox, "assets/images/cordBottom.png", 64, 200 )
        cordBottom.x, cordBottom.y = 32, 250
        cordBottom.xStart, cordBottom.yStart, cordBottom.rStart = cordBottom.x, cordBottom.y, cordBottom.rotation
        cordBottom:toBack()
        
        startButtonBG = display.newImageRect( groupBox, "assets/images/buttonOff.png", 80, 80 )
        startButtonBG.x, startButtonBG.y = box.x, box.y + box.height*0.5 - 116
        startButtonBG.xStart, startButtonBG.yStart, startButtonBG.rStart = cordBottom.x, cordBottom.y, cordBottom.rotation
        
        startButton = display.newImageRect( groupBox, "assets/images/button.png", 80, 80 )
        startButton.x, startButton.y = startButtonBG.x, startButtonBG.y
        startButton.canPress = true

        -- Just setup and forget the glint shader.
        require("assets.glint")
        startButton.fill.effect = "filter.custom.glint"
        startButton.fill.effect.intensity = 1.0 -- how bright the glint is
        startButton.fill.effect.size = 0.3 -- how wide the glint is as a percent of the object
        startButton.fill.effect.tilt = -0.2 -- tilt the direction of the glint
        startButton.fill.effect.speed = 1.0 -- how fast the glint moves across the object
                
        startButton:addEventListener( "touch", function( event )
            if event.phase == "began" then
                if event.target.canPress then
                    event.target.canPress = false
                    sfx.play("assets/audio/button.wav")
                    startGame()
                    
                    local oops = display.newCircle( event.x, event.y, startButton.width )
                    oops.xScale, oops.yScale = 0.1, 0.1
                    
                    transition.to( oops, {time=250, xScale=1, yScale=1, alpha=0, onCompete=function()
                        display.remove(oops)
                        oops = nil
                    end })
                    
                    transition.to( event.target, {time=350, y=screen.minY + screen.height*0.5 + event.target.height, transition=easing.inOutBack  })
                end
            end
            return true
        end )
        
        gameoverBackground:addEventListener( "touch", pressPlayAgain )
        
        -- hastily added function to remove locals from the function (issue with 60 upvalues).
        createTexts()
        
        for i = 1, 12 do
            leak[i] = display.newRect( groupBack, xReactor, yReactor, 512, 4 )
            leak[i].baseAlpha = 1 / (1 + floor( (i-1) / 4 ))
            leak[i].anchorX = 0
            leak[i].alpha = 0
        end
        
        reactorBack = display.newCircle( groupBack, xReactor, yReactor, reactorRadius )
        reactorBack.fill.effect = "generator.radialGradient"
        reactorBack.fill.effect.color1 = { 0.1, 0.1, 0.1, 1 }
        reactorBack.fill.effect.color2 = { 0.85, 0.85, 0.85, 1 }
        reactorBack.fill.effect.center_and_radiuses  =  { 0.5, 0.5, 0, 0.75 }
        reactorBack.fill.effect.aspectRatio  = 1
        
        -- Create the front and back sectors ("panels", visual only).
        local prevFill 
        for i = 1, panelCount do
            local rotation = (360/panelCount)*(i-1)
            
            -- Apply quadrilateral distortion to make adding the final visual styles easier.
            -- TODO: quadrilateral distortion doesn't work. :D
            -- sectorFront[i] = display.newImageRect( groupFront, "assets/images/sectorFront.png", reactorRadius, wallWidth*2+2 )
            -- sectorFront[i].x, sectorFront[i].y = xReactor, yReactor
            -- sectorFront[i].path.y1, sectorFront[i].path.y2 = wallWidth, -wallWidth
            
            -- sectorFront[i] = display.newImageRect( groupFront, "assets/images/sectorFront.png", 256, 96 )
            -- sectorFront[i].x, sectorFront[i].y = xReactor, yReactor
            -- sectorFront[i].rotation = rotation
            -- sectorFront[i].anchorX = 0
            -- sectorFront[i]:setFillColor( 1, 0, 0 )
            
            sectorBack[i] = display.newRect( groupBack, xReactor, yReactor, reactorRadius, wallWidth*2+2 )
            sectorBack[i].path.y1, sectorBack[i].path.y2 = wallWidth+1, -wallWidth-1
            sectorBack[i].rotation = rotation
            sectorBack[i].anchorX = 0
            sectorBack[i].xStart, sectorBack[i].yStart, sectorBack[i].rStart = sectorBack[i].x, sectorBack[i].y, sectorBack[i].rotation
            
            local fill = random( 65, 75 )*0.01
            if prevFill and prevFill == fill then
                repeat
                    fill = random( 65, 75 )*0.01
                until prevFill ~= fill
            end
            sectorBack[i]:setFillColor( fill, 0.5 )
            prevFill = fill
        end
        
        -- Create the reactor walls (side segments).
        local angleHalf = rad(180/wallCount)
        local yOffset = sin(angleHalf)*wallThickness*0.5
        local wallBody = {}
        for i = 1, wallCount do
            local rotation = (360/wallCount)*(i-1)
            local angle = rad(rotation)
            
            wallBody[i] = display.newRect( groupWalls, xReactor + cos(angle)*reactorRadius, yReactor + sin(angle)*reactorRadius, wallThickness, wallWidth+2 )
            wallBody[i].path.y1, wallBody[i].path.y2, wallBody[i].path.y3, wallBody[i].path.y4 = yOffset, -yOffset, yOffset, -yOffset
            wallBody[i].rotation = rotation
            wallBody[i].isVisible = false
            
            -- The physics body isn't a perfect fit, but it'll do for the game jam.
            physics.addBody( wallBody[i], "static", { friction = 0, bounce = 1, filter=filterWalls } )
            
            
            wall[i] = display.newImageRect( groupWalls, "assets/images/wall.png", wallThickness, wallWidth+2 )
            wall[i].x, wall[i].y = xReactor + cos(angle)*reactorRadius, yReactor + sin(angle)*reactorRadius
            wall[i].path.y1, wall[i].path.y2, wall[i].path.y3, wall[i].path.y4 = yOffset, -yOffset, yOffset, -yOffset
            wall[i].rotation = rotation
            wall[i].xStart, wall[i].yStart, wall[i].rStart = wall[i].x, wall[i].y, wall[i].rotation
            -- wall[i]:setFillColor( random( 20, 30 )*0.01 )
            
            -- wallOverlay[i] = display.newRect( groupWalls, display.contentCenterX + cos(angle)*reactorRadius, display.contentCenterY + sin(angle)*reactorRadius, wallThickness, wallWidth+2 )
            wallOverlay[i] = display.newImageRect( groupWallOverlay, "assets/images/wallOverlay.png", wallThickness, wallWidth+2 )
            wallOverlay[i].x, wallOverlay[i].y = xReactor + cos(angle)*reactorRadius, yReactor + sin(angle)*reactorRadius
            wallOverlay[i].path.y1, wallOverlay[i].path.y2, wallOverlay[i].path.y3, wallOverlay[i].path.y4 = yOffset, -yOffset, yOffset, -yOffset
            wallOverlay[i].rotation = rotation
        end
        
        furnace = display.newImageRect( groupWalls, "assets/images/furnace.png", 80, 80 )
        furnace.x, furnace.y = xReactor, yReactor

        -- The actual core with a physics body.
        core = display.newImageRect( groupCore, "assets/images/circleGlow.png", coreRadius*2, coreRadius*2 )
        core.x, core.y = xReactor, yReactor
        core:setFillColor( 0.95, 0, 0 )
        physics.addBody( core, "static", { radius = coreRadius, filter=filterWalls } )
        core.isCore = true
        core.alphaStart = core.alpha
        
        -- A tiny "blur" effect for the core.
        coreBlur = display.newImageRect( groupCore, "assets/images/circleGlow.png", coreRadius*2, coreRadius*2 )
        coreBlur.x, coreBlur.y = xReactor, yReactor
        coreBlur:setFillColor( 0.95, 0, 0, 0.9 )
        coreBlur.alphaStart = coreBlur.alpha
        
        -- The larger glow "emitted" by the reactor.
        coreEmitter = display.newImageRect( groupCore, "assets/images/circleGlow.png", coreRadius*2.5, coreRadius*2.5 )
        coreEmitter.x, coreEmitter.y = xReactor, yReactor
        coreEmitter:setFillColor( 1, 0.5, 0, 0.5 )    
        coreEmitter.xStart, coreEmitter.yStart = coreEmitter.x, coreEmitter.y
        coreEmitter.alphaStart = coreEmitter.alpha
        
        -- The flash that occurs when a neutron hits the core.
        coreReaction = display.newImageRect( groupCore, "assets/images/circleGlow.png", coreRadius*3, coreRadius*3 )
        coreReaction.x, coreReaction.y = xReactor, yReactor
        coreReaction:setFillColor( 0.95, 0.75, 0 )
        coreReaction.alpha = 0
        coreReaction.alphaStart = coreReaction.alpha
        
        -- The larger, but faint glow that is emitted across and beyond the reactor.
        coreGlow = display.newImageRect( groupCore, "assets/images/circleGlow.png", (reactorRadius+wallThickness)*2.5, (reactorRadius+wallThickness)*2.5 )
        coreGlow.x, coreGlow.y = xReactor, yReactor
        coreGlow.alpha = 0
        coreGlow.alphaStart = coreGlow.alpha
        
        -- The white glow inside the core.
        coreGlare = display.newImageRect( groupCore, "assets/images/circleGlow.png", coreRadius, coreRadius )
        coreGlare.x, coreGlare.y = xReactor, yReactor
        coreGlare:setFillColor( 1 )
        coreGlare.alphaStart = coreGlare.alpha
        
        Runtime:addEventListener( "collision", onCollision )

        -- Create the "neutron cannons".
        neutronCannon[1] = newCannon( -28 )
        neutronCannon[2] = newCannon( 28 )
        neutronCannon[3] = newCannon( -152 )
        neutronCannon[4] = newCannon( 152 )
        
        -- Add a vent to the bottom of the reactor for removing neutrons.
        vent = display.newImageRect( groupCannon, "assets/images/ventNozzle.png", 120, 40 )
        vent.x, vent.y = xReactor, yReactor+reactorRadius+4
        vent.xStart, vent.yStart, vent.rStart = vent.x, vent.y, vent.rotation
        vent.isVent = true
        physics.addBody( vent, "static", {filter=filterWalls} )
        
        ventOverlay = display.newImageRect( groupCannon, "assets/images/ventOverlay.png", 120, 40 )
        ventOverlay.x, ventOverlay.y = vent.x, vent.y
        -- ventOverl"ay.xStart, ventOverlay.yStart, ventOverlay.rStart = ventOverlay.x, ventOverlay.y, ventOverlay.rotation
        
        ventCord = display.newImageRect( groupCannon, "assets/images/cordBottom.png", 100, 200 )
        ventCord.x, ventCord.y = vent.x - 6, vent.y
        ventCord.xScale = -1
        ventCord.anchorY = 0
        ventCord.xStart, ventCord.yStart, ventCord.rStart = ventCord.x, ventCord.y, ventCord.rotation
        ventCord:toBack()
        
        newGame()
    end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene