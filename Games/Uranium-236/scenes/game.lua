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
-- physics.setDrawMode( "hybrid" )


---------------------------------------------------------------------------

-- Forward declarations & variables.
local groupBack = display.newGroup()
local groupObjects = display.newGroup()
local groupFront = display.newGroup()
local groupWalls = display.newGroup()
local groupWallOverlay = display.newGroup()
local groupUI = display.newGroup()
groupFront.alpha = 0
groupWallOverlay.alpha = 0


local core, coreEmitter, coreReaction, coreTransition
local sectorFront, sectorBack = {}, {}
local wall, wallOverlay = {}, {}
local neutron = {}
local gameover = false


local random = math.random
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
local tempIncreasePerHit = 5
local tempDecreaseInterval = 200
local tempDecreaseAmount = 3

-- NB! Automatically assigned properties (don't touch).
local panelCount = wallCount*0.5
local wallWidth = 2*math.pi*reactorRadius/wallCount
local coreTemp = 0
local tempRate = 0

-- wallCount must be divisible by 4 so that panelCount is divisible by 2.
if wallCount % 4 ~= 0 then
    for i = 1, 10 do
        print( "ERROR: wallCount must be divisible by 4!" )
    end
end

---------------------------------------------------------------------------

-- Functions.
local function newNeutron( x, y )
    local projectile = display.newCircle( groupObjects, x, y, neutronRadius )
    projectile.id = #neutron+1
    projectile:setFillColor( 0.95, 0.7, 0 )
    physics.addBody( projectile, "dynamic", { radius = neutronRadius, bounce = 1, friction = 0 } )
    
    projectile.baseVelocity = neutronBaseSpeed+random(-neutronSpeedVariance,neutronSpeedVariance)
    
    local prevX, prevY
    
    function projectile.touch( self, event )
    	local phase = event.phase
    	local stage = display.getCurrentStage()

        if phase == "began" then
    		stage:setFocus( self )
    		self.isFocus = true
    		self.tempJoint = physics.newJoint( "touch", self, event.x, event.y )
            prevX, prevY = self.x, self.y
            
        elseif not self.isFocus then
    		stage:setFocus( self )
    		self.isFocus = true
    		self.tempJoint = physics.newJoint( "touch", self, event.x, event.y )
            prevX, prevY = self.x, self.y
            
        else
    		if phase == "moved" then
    			self.tempJoint:setTarget( event.x, event.y )
            else
    			stage:setFocus( nil )
    			self.isFocus = false	
    			self.tempJoint:removeSelf()
                
                -- As player lets go, cause a tiny "explosion" to push it somewhere.
                local angle = atan2( event.y - prevY, event.x - prevX )
                
                -- -- Fire the neutron projectile from the cannon with slight variation in its angle and velocity.
                self:setLinearVelocity(
                    cos(angle)*projectile.baseVelocity,
                    sin(angle)*projectile.baseVelocity
                )
                
            end
            
            if event.x ~= prevX or event.y ~= prevY then
                prevX, prevY = self.x, self.y
            end
        end
        
        return true
    end
    
    projectile:addEventListener( "touch" )
    
    neutron[projectile.id] = projectile
    return projectile
end

local function newCannon( position )
    -- position defines the position on the wall based on angle (degree).
    local angle = rad( position )
    local x, y = display.contentCenterX + cos(angle)*reactorRadius, display.contentCenterY + sin(angle)*reactorRadius
    
    local cannon = display.newRect( groupWalls, x, y, 40, 40 )
    cannon:setFillColor( 0, 0.3, 0.75 )
    cannon.rotation = position
    
    cannon.spawn = {
        x = display.contentCenterX + cos(angle)*(reactorRadius-cannon.width*0.5),
        y = display.contentCenterY + sin(angle)*(reactorRadius-cannon.width*0.5) 
    }
    
    local angleFiring = atan2( display.contentCenterY - cannon.spawn.y, display.contentCenterX - cannon.spawn.x )
    
    function cannon.fire()
        local projectile = newNeutron( cannon.spawn.x, cannon.spawn.y )
        projectile.isActive = true
        projectile.alpha = 0.25
        projectile.xScale, projectile.yScale = 0.75, 0.75
        transition.to( projectile, { time=250, alpha=1, xScale=1, yScale=1 } )
        
        
        -- Fire the neutron projectile from the cannon with slight variation in its angle and velocity.
        projectile:setLinearVelocity(
            cos(angleFiring+random(-neutronFireAngleVariance,neutronFireAngleVariance))*projectile.baseVelocity,
            sin(angleFiring+random(-neutronFireAngleVariance,neutronFireAngleVariance))*projectile.baseVelocity
        )
        
        -- Set the cannon to fire again.
        timer.performWithDelay( cannonFireInterval+random( -cannonFireVariance, cannonFireVariance ), cannon.fire, "cannon" )
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
    
    -- Increase the visibility of the wall overlay and adjust the colours.
    tempRate = coreTemp/maxCoreTemp
    groupWallOverlay.alpha = tempRate*1.5
    
    for i = 1, #wallOverlay do
        wallOverlay[i]:setFillColor( 1, 0.8*(1-tempRate), 0 )
    end
    
    if coreTemp >= maxCoreTemp then
        gameover = true
        display.setDefault( "background", 0.9, 0, 0 )
    end
end

local function animateCore()
    -- Move the core emitter around a bit.
    local scale = random(95,105)*0.01
    coreEmitter.x, coreEmitter.y = coreEmitter.xStart + random(-2,2), coreEmitter.yStart + random(-2,2)
    coreEmitter.xScale, coreEmitter.yScale = scale, scale
    
    -- print( tempRate )
    if tempRate > 0.35 then
        -- local xBounce, yBounce, rBounce
        -- if tempRate < 0.7 then
        --     xBounce, yBounce, rBounce = random(-1,1), random(-1,1), 0
        -- else
        --     xBounce, yBounce, rBounce = random(-2,2), random(-2,2), random(-1,1)
        -- end
        
        for i = 1, #wall do
            local xBounce, yBounce, rBounce
            if tempRate < 0.7 then
                xBounce, yBounce, rBounce = random(-1,1), random(-1,1), 0
            else
                xBounce, yBounce, rBounce = random(-2,2), random(-2,2), random(-1,1)
            end
            
            local obj, overlay = wall[i], wallOverlay[i]
            local x, y, r = obj.xStart + xBounce, obj.yStart + yBounce, obj.rStart + rBounce
            obj.x, obj.y, obj.r, overlay.x, overlay.y, overlay.r = x, y, r, x, y, r
        end
        
        for i = 1, #sectorBack do
            local xBounce, yBounce, rBounce
            if tempRate < 0.7 then
                xBounce, yBounce, rBounce = random(-1,1), random(-1,1), 0
            else
                xBounce, yBounce, rBounce = random(-2,2), random(-2,2), random(-1,1)
            end
            
            local obj = sectorBack[i]
            obj.x, obj.y, obj.r = obj.xStart + xBounce, obj.yStart + yBounce, obj.rStart + rBounce
        end
    end
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
        
        local background = display.newCircle( groupBack, display.contentCenterX, display.contentCenterY, reactorRadius )
        background:setFillColor( math.random( 6, 8 )*0.1 )
        
        -- Create the front and back sectors ("panels", visual only).
        for i = 1, panelCount do
            local rotation = (360/panelCount)*(i-1)
            
            -- Apply quadrilateral distortion to make adding the final visual styles easier.    
            sectorFront[i] = display.newRect( groupFront, display.contentCenterX, display.contentCenterY, reactorRadius, wallWidth*2+2 )
            sectorFront[i].path.y1, sectorFront[i].path.y2 = wallWidth, -wallWidth
            sectorFront[i].rotation = rotation
            sectorFront[i].anchorX = 0
            sectorFront[i]:setFillColor( math.random( 6, 8 )*0.1 )
            
            sectorBack[i] = display.newRect( groupBack, display.contentCenterX, display.contentCenterY, reactorRadius, wallWidth*2+2 )
            sectorBack[i].path.y1, sectorBack[i].path.y2 = wallWidth, -wallWidth
            sectorBack[i].rotation = rotation
            sectorBack[i].anchorX = 0
            sectorBack[i].xStart, sectorBack[i].yStart, sectorBack[i].rStart = sectorBack[i].x, sectorBack[i].y, sectorBack[i].rotation
            sectorBack[i]:setFillColor( math.random( 6, 8 )*0.1 )
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
            
            wall[i] = display.newRect( groupWalls, display.contentCenterX + cos(angle)*reactorRadius, display.contentCenterY + sin(angle)*reactorRadius, wallThickness, wallWidth+2 )
            wall[i].path.y1, wall[i].path.y2, wall[i].path.y3, wall[i].path.y4 = yOffset, -yOffset, yOffset, -yOffset
            wall[i].rotation = rotation
            wall[i].xStart, wall[i].yStart, wall[i].rStart = wall[i].x, wall[i].y, wall[i].rotation
            wall[i]:setFillColor( math.random( 20, 30 )*0.01 )
            
            -- wallOverlay[i] = display.newRect( groupWalls, display.contentCenterX + cos(angle)*reactorRadius, display.contentCenterY + sin(angle)*reactorRadius, wallThickness, wallWidth+2 )
            wallOverlay[i] = display.newImageRect( groupWallOverlay, "assets/images/wallOverlay.png", wallThickness, wallWidth+2 )
            wallOverlay[i].x, wallOverlay[i].y = display.contentCenterX + cos(angle)*reactorRadius, display.contentCenterY + sin(angle)*reactorRadius
            wallOverlay[i].path.y1, wallOverlay[i].path.y2, wallOverlay[i].path.y3, wallOverlay[i].path.y4 = yOffset, -yOffset, yOffset, -yOffset
            wallOverlay[i].rotation = rotation
        end

        core = display.newCircle( groupWalls, display.contentCenterX, display.contentCenterY, coreRadius )
        core:setFillColor( 0.95, 0, 0 )
        physics.addBody( core, "static", { radius = coreRadius } )
        
        local coreBlastArea = core.width*0.5 + neutronRadius*2
        
        coreEmitter = display.newCircle( groupWalls, display.contentCenterX, display.contentCenterY, coreRadius )
        coreEmitter:setFillColor( 1, 0.5, 0, 0.5 )    
        coreEmitter.xStart, coreEmitter.yStart = coreEmitter.x, coreEmitter.y
        
        coreReaction = display.newCircle( groupWalls, display.contentCenterX, display.contentCenterY, coreRadius*1.1 )
        coreReaction:setFillColor( 0.95, 0.75, 0 )
        coreReaction.alpha = 0

        local function onCoreCollision( self, event )
            -- Prevent neutrons spawned from core by colliding with it immediately.
            if event.phase == "began" and event.other.isActive then
                display.remove( event.other )
                neutron[event.other.id] = nil
                coreTemp = coreTemp + tempIncreasePerHit
                updateTemperature()
                
                if gameover then
                    -- isActive
                    timer.cancel( "cannon" )
                    timer.cancel( "temperature" )
                else
                    if not coreTransition then
                        coreTransition = transition.from( coreReaction, {time=150, alpha=1, xScale=1.25, yScale=1.25, onComplete=function()
                            coreTransition = nil
                        end })
                    end
                    
                    -- Push neutrons that are too close to core away.
                    for i = 1, #neutron do
                        local obj = neutron[i]
                        if obj then
                            local distance = (obj.x - core.x)*(obj.x - core.x) + (obj.y - core.y)*(obj.y - core.y)
                            if distance < coreBlastArea then
                                local angle = atan2( obj.y - core.y, obj.x - core.x )
                                obj:setLinearVelocity(
                                    cos(angle)*projectile.baseVelocity,
                                    sin(angle)*projectile.baseVelocity
                                )
                            end
                        end
                    end
                    
                    -- Nuclear fission time, spawn 3 neutrons from core.
                    for i = 1, 3 do
                        -- Spawn the neutron near the core's outer edge.
                        timer.performWithDelay( 1, function()
                            local angle = rad(random(360))
                            local radius = core.width*0.5 + neutronRadius*1.5
                            local x, y = cos(angle)*radius, sin(angle)*radius
                            
                            local projectile = newNeutron( core.x + x, core.y + y )
                            projectile.xScale, projectile.yScale = 0.75, 0.75
                            projectile.alpha = 0.25
                            
                            -- Fire the neutron projectile from the cannon with slight variation in its angle and velocity.
                            projectile:setLinearVelocity(
                                cos(angle)*projectile.baseVelocity,
                                sin(angle)*projectile.baseVelocity
                            )
                            
                            transition.to( projectile, { time=250, alpha=1, xScale=1, yScale=1, onComplete=function()
                                if projectile then
                                    projectile.isActive = true
                                end
                            end})
                        end, "cannon" )
                    end
                end
            end
        end
        
        core.collision = onCoreCollision
        core:addEventListener( "collision" )

        -- Create the "neutron cannons".
        local neutronCannon = {}
        neutronCannon[1] = newCannon( -28 )
        neutronCannon[2] = newCannon( 28 )
        neutronCannon[3] = newCannon( -152 )
        neutronCannon[4] = newCannon( 152 )
        
        -- Start each cannon with increasing delay and shuffle them so they don't fire in order.
        local delay = 0
        
        local order = {}
        for i = 1, #neutronCannon do
            order[i] = i
        end
        
        function shuffle(t)
            for i = #t, 2, -1 do
                local j = math.random(i)
                t[i], t[j] = t[j], t[i]
            end
        end
        shuffle(order)
        
        for i = 1, #neutronCannon do
            local n = order[i]
            delay = delay + cannonFireInterval+random( -cannonFireVariance, cannonFireVariance )
            timer.performWithDelay( delay, neutronCannon[n].fire, "cannon" )
        end
        
        timer.performWithDelay( tempDecreaseInterval, updateTemperature, 0, "temperature" )
        Runtime:addEventListener( "enterFrame", animateCore )
        
    end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene