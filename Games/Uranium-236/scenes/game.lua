local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local sfx = require("classes.sfx")
local utils = require("libs.utils")
local loadsave, savedata

display.setDefault( "background", 0.075 )
local physics = require("physics")
physics.start()
physics.setGravity( 0, 0 )
physics.setReportCollisionsInContentCoordinates( true )
-- physics.setDrawMode( "hybrid" )


---------------------------------------------------------------------------

-- Forward declarations & variables.
local groupHelaDagen = display.newGroup()
local groupBack = display.newGroup()
local groupObjects = display.newGroup()
local groupWalls = display.newGroup()
local groupWallOverlay = display.newGroup()
local groupCore = display.newGroup()

-- Making new game / end game transition easier by stuffing everything into a single group:
groupHelaDagen:insert(groupBack)
groupHelaDagen:insert(groupObjects)
groupHelaDagen:insert(groupWalls)
groupHelaDagen:insert(groupWallOverlay)
groupHelaDagen:insert(groupCore)

local groupUI = display.newGroup()
groupWallOverlay.alpha = 0


local core, coreBlur, coreEmitter, coreGlare, coreGlow, coreReaction, coreTransition, reactorBack, whiteBackground
local wall, wallOverlay, sectorFront, sectorBack, leak, neutronCannon, neutron, spark = {}, {}, {}, {}, {}, {}, {}, {}

local random = math.random
local sqrt = math.sqrt
local atan2 = math.atan2
local rad = math.rad
local cos = math.cos
local sin = math.sin

-- Reactor properties:
local reactorRadius = 240
local wallThickness = 16
local wallCount = 32

-- Object properties:
local neutronRadius = 16
local neutronBaseSpeed = 70
local cannonFireInterval = 5000
local cannonFireVariance = 1500

-- Neutron speed = neutronBaseSpeed +/- neutronSpeedVariance
local neutronSpeedVariance = 10
local neutronFireAngleVariance = 0.06 -- in radians.
local coreRadius = 50

-- Core temperature settings:
local maxCoreTemp = 100
local startTemp = 20
local tempIncreasePerHit = 5
local tempDecreaseInterval = 500
local tempDecreaseAmount = 1

-- NB! Automatically assigned properties (don't touch).
local gameover = false
local touchDistance = reactorRadius + wallThickness
local panelCount = wallCount*0.5
local wallWidth = 2*math.pi*reactorRadius/wallCount
local coreTemp = startTemp
local tempRate = coreTemp/maxCoreTemp
local neutronCount = 0

-- wallCount must be divisible by 4 so that panelCount is divisible by 2.
if wallCount % 4 ~= 0 then
    for i = 1, 10 do
        print( "ERROR: wallCount must be divisible by 4!" )
    end
end

---------------------------------------------------------------------------

-- Functions.
local startGame, stopGame


local function releaseNeutron( target, x1, x2, y1, y2 )
    display.getCurrentStage():setFocus( nil )
    target.isFocus = false	
    target.tempJoint:removeSelf()
    
    -- As player lets go, cause a tiny "explosion" to push it somewhere.
    local angle = atan2( y1-y2, x1-x2 )
    
    -- Fire the neutron projectile from the cannon with slight variation in its angle and velocity.
    target:setLinearVelocity(
        cos(angle)*target.baseVelocity,
        sin(angle)*target.baseVelocity
    )
end

local function newNeutron( x, y )
    local projectile = display.newImageRect( groupObjects, "assets/images/neutron.png", neutronRadius*2, neutronRadius*2 )
    projectile.x, projectile.y = x, y
    projectile.isNeutron = true
    projectile.id = #neutron+1
    projectile:setFillColor( 0.95, 0.7, 0 )
    physics.addBody( projectile, "dynamic", { radius = neutronRadius, bounce = 1, friction = 0 } )
    projectile:toBack()
       
    projectile.baseVelocity = neutronBaseSpeed+random(-neutronSpeedVariance,neutronSpeedVariance)
    
    local prevX, prevY
    
    function projectile.touch( self, event )
    	local phase = event.phase

        if phase == "began" then
    		display.getCurrentStage():setFocus( self )
    		self.isFocus = true
    		self.tempJoint = physics.newJoint( "touch", self, event.x, event.y )
            prevX, prevY = self.x, self.y
            
        elseif not self.isFocus then
    		display.getCurrentStage():setFocus( self )
    		self.isFocus = true
    		self.tempJoint = physics.newJoint( "touch", self, event.x, event.y )
            prevX, prevY = self.x, self.y
            
        else
    		if phase == "moved" then
    			self.tempJoint:setTarget( event.x, event.y )
                
                local distance = sqrt((event.x - core.x)*(event.x - core.x) + (event.y - core.y)*(event.y - core.y))
                if distance > touchDistance then
                    releaseNeutron( self, event.x, prevX, event.y, prevY )
                end
            else
                releaseNeutron( self, event.x, prevX, event.y, prevY )
            end
            
            if event.x ~= prevX or event.y ~= prevY then
                prevX, prevY = self.x, self.y
            end
        end
        
        return true
    end
    
    projectile:addEventListener( "touch" )
    neutronCount = projectile.id
    neutron[projectile.id] = projectile
    return projectile
end

local function newCannon( position )
    -- position defines the position on the wall based on angle (degree).
    local angle = rad( position )
    local x, y = display.contentCenterX + cos(angle)*reactorRadius, display.contentCenterY + sin(angle)*reactorRadius
    
    local cannon = display.newGroup()
    cannon.xStart, cannon.yStart, cannon.rStart = x, y, position
    cannon.rotation = position
    cannon.x, cannon.y = x, y
    groupCore:insert(cannon)
    cannon:toBack()
    
    -- Push the cords further inside the walls.
    local cords = display.newImageRect( cannon, "assets/images/cords.png", 100, 128 )
    cords.x = -16
    cords.anchorX = 0
    
    local nozzle = display.newImageRect( cannon, "assets/images/nozzle.png", 40, 40 )
    cannon.overlay = display.newImageRect( cannon, "assets/images/nozzleOverlay.png", 40, 40 )
    
    cannon.indicator = display.newImageRect( cannon, "assets/images/indicator.png", 16, 16 )
    cannon.indicator:setFillColor(0,1,1)
    cannon.indicator.alpha = 0
    
    local xSpawn = display.contentCenterX + cos(angle)*(reactorRadius-nozzle.width*0.5)
    local ySpawn = display.contentCenterY + sin(angle)*(reactorRadius-nozzle.width*0.5)
    local angleFiring = atan2( display.contentCenterY - ySpawn, display.contentCenterX - xSpawn )
    
    function cannon.fire( self, chargeUp )
        cannon.indicator.xScale = 0.5
        cannon.indicator.yScale = 0.5
        cannon.indicator.alpha = 0
        
        if not chargeUp then
            local projectile = newNeutron( xSpawn, ySpawn )        
            
            -- Fire the neutron projectile from the cannon with slight variation in its angle and velocity.
            projectile:setLinearVelocity(
                cos(angleFiring+random(-neutronFireAngleVariance,neutronFireAngleVariance))*projectile.baseVelocity,
                sin(angleFiring+random(-neutronFireAngleVariance,neutronFireAngleVariance))*projectile.baseVelocity
            )
            
            -- Create a spark effect to hide the newly spawned particle.
            -- local t = display.newImageRect( groupCore, "assets/images/circleGlow.png", neutronRadius*1.5, neutronRadius*1.5 )
            -- t.x, t.y = event.x, event.y
            -- t:toBack()
            -- spark[#spark+1] = t
            -- transition.to( t, { time=150, xScale=0.1, yScale=0.1, alpha=0, onComplete=function()
            --     display.remove(t)
            --     t = nil
            -- end })
        end
        
        -- Set the cannon to fire again.
        transition.to( cannon.indicator, {
            time = cannonFireInterval+random( -cannonFireVariance, cannonFireVariance ),
            xScale = 1,
            yScale = 1,
            alpha = 1,
            onComplete = cannon.fire
        } )
    end
    
    return cannon
end


local function updateTemperature( isTimer )
    -- If updateTemperature is triggered by timer, then reduce the temperature.
    if isTimer then
        coreTemp = coreTemp - tempDecreaseAmount
        if coreTemp < 0 then
            coreTemp = 0
        end
    end
    
    -- Increase the visibility of the wall overlay and adjust all colours.
    tempRate = coreTemp/maxCoreTemp
    groupWallOverlay.alpha = tempRate*1.5
    core:setFillColor( 1, tempRate, 0 )
    coreGlow:setFillColor( 1, 0.8*(1-tempRate), 0 )
    coreGlow.alpha = tempRate*0.25
    
    for i = 1, #wallOverlay do
        wallOverlay[i]:setFillColor( 1, 0.8*(1-tempRate), 0 )
    end
    
    for i = 1, #neutronCannon do
        neutronCannon[i].overlay:setFillColor( 1, 0.8*(1-tempRate), 0 )
        neutronCannon[i].overlay.alpha = tempRate*1.5
    end
    
    if coreTemp >= maxCoreTemp then
        stopGame()
    end
end

local isCoreCold = false
local function animateCore()
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
end

local function resetObjects()
    whiteBackground.alpha = 1
    
    -- Reset the reactor components.
    for i = 1, #wall do
        local obj, overlay = wall[i], wallOverlay[i]
        local x, y, r = obj.xStart, obj.yStart, obj.rStart
        obj.x, obj.y, obj.rotation, overlay.x, overlay.y, overlay.rotation = x, y, r, x, y, r
    end
    
    for i = 1, #sectorBack do
        local obj = sectorBack[i]
        obj.x, obj.y, obj.rotation = obj.xStart, obj.yStart, obj.rStart
    end
    
    for i = 1, #neutronCannon do
        local obj = neutronCannon[i]
        obj.x, obj.y, obj.rotation = obj.xStart, obj.yStart, obj.rStart
        obj.indicator.alpha = 0
    end
    
    for i = 1, #leak do
        leak[i].alpha = 0
    end
    
    -- Reset core's elements.
    core.alpha, core.xScale, core.yScale = core.alphaStart, 1, 1
    coreBlur.alpha, coreBlur.xScale, coreBlur.yScale = coreBlur.alphaStart, 1, 1
    coreEmitter.alpha, coreEmitter.xScale, coreEmitter.yScale = coreEmitter.alphaStart, 1, 1
    coreReaction.alpha, coreReaction.xScale, coreReaction.yScale = coreReaction.alphaStart, 1, 1
    coreGlow.alpha, coreGlow.xScale, coreGlow.yScale = coreGlow.alphaStart, 1, 1
    coreGlare.alpha, coreGlare.xScale, coreGlare.yScale = coreGlare.alphaStart, 1, 1
    coreTransition = nil
end


local firstLaunch = true
function startGame()
    local timeFade, timeReveal
    if firstLaunch then
        timeFade = 0
        timeReveal = 0
    else
        groupHelaDagen.y = screen.height
        timeFade = 750
        timeReveal = 500
    end
    coreTemp = startTemp
    tempRate = coreTemp/maxCoreTemp
    neutronCount = 0
    gameover = false
    
    -- Shuffle the cannon firing order. 
    local order = {}
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
    
    transition.to( whiteBackground, { time=timeFade, alpha=0, onComplete=function()
        transition.to( groupHelaDagen, { time=timeReveal, y=0, transition=easing.inOutBack, onComplete=function()
            
            for i = 1, #neutronCannon do
                local n = order[i]
                timer.performWithDelay( cannonFireInterval*0.25*i+random( -cannonFireVariance, cannonFireVariance ), function()
                    neutronCannon[n].fire( nil, true )
                end )
            end
            
            Runtime:addEventListener( "enterFrame", animateCore )
            updateTemperature( true )
        end })
    end })
    firstLaunch = false
end

function stopGame()
    gameover = true
    transition.cancelAll()
    timer.cancelAll()
    
    for i = 1, #spark do
        display.remove(spark[i])
        spark[i] = nil
    end
    
    -- Determine scale factor based on coreGlare's size so that it'll cover the entire screen.
    local scaleFactor = display.actualContentWidth/coreGlare.width*2
    local time = 500
        
    -- Start gameover transitions.
    transition.to( core, { time=time, xScale=scaleFactor, yScale=scaleFactor, transition=easing.inBack  })
    transition.to( coreEmitter, { time=time, xScale=scaleFactor, yScale=scaleFactor, transition=easing.inBack  })
    transition.to( coreGlare, { delay=time*0.25, time=time, xScale=scaleFactor, yScale=scaleFactor, transition=easing.inBack, onComplete=function()
        -- Remove existing neutrons and restart the game.
        for i = 1, neutronCount do
            if neutron[i] then
                display.remove(neutron[i])
                neutron[i] = nil
            end
        end
        
        Runtime:removeEventListener( "enterFrame", animateCore )
        resetObjects()        
        startGame()
    end })
end

---------------------------------------------------------------------------

function scene:create( event )
    local sceneGroup = self.view
    -- If the project uses savedata, then load existing data or set it up.
    if event.params and event.params.usesSavedata then
        loadsave = require("classes.loadsave")
        savedata = loadsave.load("data.json")
                
        if not savedata then
            -- Assign initial values for save data.
            savedata = {
                
            }
            loadsave.save( savedata, "data.json" )
        end
    end
    
end

---------------------------------------------------------------------------

function scene:show( event )
    local sceneGroup = self.view
    
    if event.phase == "will" then
        -- If coming from launchScreen scene, then start by removing it.
        if composer._previousScene == "scenes.launchScreen" then
            composer.removeScene( "scenes.launchScreen" )
        end
        
    elseif event.phase == "did" then
        
        local xedur = display.newImageRect( "assets/images/launchScreen/XeduR.png", 256, 128 )
        xedur.anchorX, xedur.anchorY = 1, 0
        xedur.x, xedur.y = screen.maxX + 20, screen.minY
        
        local title = display.newText( "LD49: Uranium-236", xedur.x - xedur.width*0.5, xedur.y + xedur.height, nil, 20 )        
        title.anchorY = 0
        
        whiteBackground = display.newRect( groupUI, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
        whiteBackground.alpha = 0
        
        for i = 1, 12 do
            leak[i] = display.newRect( groupBack, display.contentCenterX, display.contentCenterY, 512, 4 )
            leak[i].baseAlpha = 1 / (1 + math.floor( (i-1) / 4 ))
            leak[i].anchorX = 0
            leak[i].alpha = 0
        end
        
        reactorBack = display.newCircle( groupBack, display.contentCenterX, display.contentCenterY, reactorRadius )        
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
            -- sectorFront[i].x, sectorFront[i].y = display.contentCenterX, display.contentCenterY
            -- sectorFront[i].path.y1, sectorFront[i].path.y2 = wallWidth, -wallWidth
            
            -- sectorFront[i] = display.newImageRect( groupFront, "assets/images/sectorFront.png", 256, 96 )
            -- sectorFront[i].x, sectorFront[i].y = display.contentCenterX, display.contentCenterY
            -- sectorFront[i].rotation = rotation
            -- sectorFront[i].anchorX = 0
            -- sectorFront[i]:setFillColor( 1, 0, 0 )
            
            sectorBack[i] = display.newRect( groupBack, display.contentCenterX, display.contentCenterY, reactorRadius, wallWidth*2+2 )
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
            
            wallBody[i] = display.newRect( groupWalls, display.contentCenterX + cos(angle)*reactorRadius, display.contentCenterY + sin(angle)*reactorRadius, wallThickness, wallWidth+2 )
            wallBody[i].path.y1, wallBody[i].path.y2, wallBody[i].path.y3, wallBody[i].path.y4 = yOffset, -yOffset, yOffset, -yOffset
            wallBody[i].rotation = rotation
            wallBody[i].isVisible = false
            
            -- The physics body isn't a perfect fit, but it'll do for the game jam.
            physics.addBody( wallBody[i], "static", { friction = 0, bounce = 1 } )
            
            wall[i] = display.newImageRect( groupWalls, "assets/images/wall.png", wallThickness, wallWidth+2 )
            wall[i].x, wall[i].y = display.contentCenterX + cos(angle)*reactorRadius, display.contentCenterY + sin(angle)*reactorRadius
            wall[i].path.y1, wall[i].path.y2, wall[i].path.y3, wall[i].path.y4 = yOffset, -yOffset, yOffset, -yOffset
            wall[i].rotation = rotation
            wall[i].xStart, wall[i].yStart, wall[i].rStart = wall[i].x, wall[i].y, wall[i].rotation
            -- wall[i]:setFillColor( random( 20, 30 )*0.01 )
            
            -- wallOverlay[i] = display.newRect( groupWalls, display.contentCenterX + cos(angle)*reactorRadius, display.contentCenterY + sin(angle)*reactorRadius, wallThickness, wallWidth+2 )
            wallOverlay[i] = display.newImageRect( groupWallOverlay, "assets/images/wallOverlay.png", wallThickness, wallWidth+2 )
            wallOverlay[i].x, wallOverlay[i].y = display.contentCenterX + cos(angle)*reactorRadius, display.contentCenterY + sin(angle)*reactorRadius
            wallOverlay[i].path.y1, wallOverlay[i].path.y2, wallOverlay[i].path.y3, wallOverlay[i].path.y4 = yOffset, -yOffset, yOffset, -yOffset
            wallOverlay[i].rotation = rotation
        end

        -- The actual core with a physics body.
        core = display.newImageRect( groupCore, "assets/images/circleGlow.png", coreRadius*2, coreRadius*2 )
        core.x, core.y = display.contentCenterX, display.contentCenterY
        core:setFillColor( 0.95, 0, 0 )
        physics.addBody( core, "static", { radius = coreRadius } )
        core.isCore = true
        core.alphaStart = core.alpha
        
        -- A tiny "blur" effect for the core.
        coreBlur = display.newImageRect( groupCore, "assets/images/circleGlow.png", coreRadius*2, coreRadius*2 )
        coreBlur.x, coreBlur.y = display.contentCenterX, display.contentCenterY
        coreBlur:setFillColor( 0.95, 0, 0, 0.9 )
        coreBlur.alphaStart = coreBlur.alpha
        
        local coreBlastArea = core.width*0.75 + neutronRadius*2
        
        -- The larger glow "emitted" by the reactor.
        coreEmitter = display.newImageRect( groupCore, "assets/images/circleGlow.png", coreRadius*2.5, coreRadius*2.5 )
        coreEmitter.x, coreEmitter.y = display.contentCenterX, display.contentCenterY
        coreEmitter:setFillColor( 1, 0.5, 0, 0.5 )    
        coreEmitter.xStart, coreEmitter.yStart = coreEmitter.x, coreEmitter.y
        coreEmitter.alphaStart = coreEmitter.alpha
        
        -- The flash that occurs when a neutron hits the core.
        coreReaction = display.newImageRect( groupCore, "assets/images/circleGlow.png", coreRadius*3, coreRadius*3 )
        coreReaction.x, coreReaction.y = display.contentCenterX, display.contentCenterY
        coreReaction:setFillColor( 0.95, 0.75, 0 )
        coreReaction.alpha = 0
        coreReaction.alphaStart = coreReaction.alpha
        
        -- The larger, but faint glow that is emitted across and beyond the reactor.
        coreGlow = display.newImageRect( groupCore, "assets/images/circleGlow.png", (reactorRadius+wallThickness)*2.5, (reactorRadius+wallThickness)*2.5 )
        coreGlow.x, coreGlow.y = display.contentCenterX, display.contentCenterY
        coreGlow.alpha = 0
        coreGlow.alphaStart = coreGlow.alpha
        
        -- The white glow inside the core.
        coreGlare = display.newImageRect( groupCore, "assets/images/circleGlow.png", coreRadius, coreRadius )
        coreGlare.x, coreGlare.y = display.contentCenterX, display.contentCenterY
        coreGlare:setFillColor( 1 )
        coreGlare.alphaStart = coreGlare.alpha

        local function onCollision( event )
            if event.phase == "began" and not gameover then
                
                -- Neutron collides with the core.
                if event.object1.isCore then
                    display.remove( event.object2 )
                    neutron[event.object2.id] = nil -- remove on gameover.
                    coreTemp = coreTemp + tempIncreasePerHit
                    updateTemperature()
                    
                    
                    if not coreTransition then
                        coreTransition = transition.from( coreReaction, {time=150, alpha=1, xScale=1.25, yScale=1.25, onComplete=function()
                            coreTransition = nil
                        end })
                    end
                    
                    -- Push neutrons that are too close to core away.
                    for i = 1, #neutron do
                        local obj = neutron[i]
                        if obj then
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
                    
                    if not gameover then
                        -- Nuclear fission time, spawn 3 neutrons from core.
                        for i = 1, 3 do
                            -- Spawn the neutron near the core's outer edge.
                            timer.performWithDelay( 1, function()
                                local angle = rad(random(360))
                                local radius = core.width*0.5 + neutronRadius*1.5
                                local x, y = cos(angle)*radius, sin(angle)*radius
                        
                                local projectile = newNeutron( core.x + x, core.y + y )
                        
                                -- Fire the neutron projectile from the cannon with slight variation in its angle and velocity.
                                projectile:setLinearVelocity(
                                    cos(angle)*projectile.baseVelocity,
                                    sin(angle)*projectile.baseVelocity
                                )
                        
                            end )
                        end
                    end
                
                
                elseif event.object2.isNeutron then
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
        
        Runtime:addEventListener( "collision", onCollision )

        -- Create the "neutron cannons".
        neutronCannon[1] = newCannon( -28 )
        neutronCannon[2] = newCannon( 28 )
        neutronCannon[3] = newCannon( -152 )
        neutronCannon[4] = newCannon( 152 )
        
        startGame()
    end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene