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
physics.setDrawMode( "hybrid" )


---------------------------------------------------------------------------

-- Forward declarations & variables.
local groupBack = display.newGroup()
local groupObjects = display.newGroup()
local groupFront = display.newGroup()
local groupWalls = display.newGroup()
local groupUI = display.newGroup()
groupFront.alpha = 0


local neutron = {}
local gameover = false


local random = math.random
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
    projectile:setFillColor( 0.95, 0.7, 0 )
    physics.addBody( projectile, "dynamic", { radius = neutronRadius, bounce = 1, friction = 0 } )
    
    function projectile.touch( self, event )
    	local target = self
    	local phase = event.phase
    	local stage = display.getCurrentStage()

        if phase == "began" then
    		stage:setFocus( target )
    		target.isFocus = true
    		target.tempJoint = physics.newJoint( "touch", target, event.x, event.y )
            
        elseif target.isFocus then
    		if phase == "moved" then
    			target.tempJoint:setTarget( event.x, event.y )
            else
    			stage:setFocus( nil )
    			target.isFocus = false	
    			target.tempJoint:removeSelf()
            end
        end
        
        return true
    end
    
    projectile:addEventListener( "touch" )
    
    neutron[#neutron+1] = projectile
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
    
    local angleFiring = math.atan2( display.contentCenterY - cannon.spawn.y, display.contentCenterX - cannon.spawn.x )
    
    function cannon.fire()
        local projectile = newNeutron( cannon.spawn.x, cannon.spawn.y )
        projectile.isActive = true
        
        -- Fire the neutron projectile from the cannon with slight variation in its angle and velocity.
        projectile:setLinearVelocity(
            cos(angleFiring+random(-neutronFireAngleVariance,neutronFireAngleVariance))*neutronBaseSpeed+random(-neutronSpeedVariance,neutronSpeedVariance),
            sin(angleFiring+random(-neutronFireAngleVariance,neutronFireAngleVariance))*neutronBaseSpeed+random(-neutronSpeedVariance,neutronSpeedVariance)
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
    
    if coreTemp >= maxCoreTemp then
        gameover = true
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
        
        -- Create the front and back sectors ("panels", visual only).
        local sectorFront, sectorBack = {}, {}
        for i = 1, panelCount do
            local rotation = (360/panelCount)*(i-1)
            
            -- Apply quadrilateral distortion to make adding the final visual styles easier.    
            sectorFront[i] = display.newRect( groupFront, display.contentCenterX, display.contentCenterY, reactorRadius, wallWidth*2+2 )
            sectorFront[i].anchorX = 0
            sectorFront[i].path.y1 = wallWidth
            sectorFront[i].path.y2 = -wallWidth
            sectorFront[i].rotation = rotation
            sectorFront[i]:setFillColor( math.random( 6, 8 )*0.1 )
            
            sectorBack[i] = display.newRect( groupBack, display.contentCenterX, display.contentCenterY, reactorRadius, wallWidth*2+2 )
            sectorBack[i].anchorX = 0
            sectorBack[i].path.y1 = wallWidth
            sectorBack[i].path.y2 = -wallWidth
            sectorBack[i].rotation = rotation
            sectorBack[i]:setFillColor( math.random( 6, 8 )*0.1 )
        end
        
        -- Create the reactor walls (side segments).
        local angleHalf = rad(180/wallCount)
        local yOffset = sin(angleHalf)*wallThickness*0.5
        local wall = {}
        for i = 1, wallCount do
            local rotation = (360/wallCount)*(i-1)
            local angle = rad(rotation)
            
            wall[i] = display.newRect( groupWalls, display.contentCenterX + cos(angle)*reactorRadius, display.contentCenterY + sin(angle)*reactorRadius, wallThickness, wallWidth+2 )
            wall[i].path.y1 = yOffset
            wall[i].path.y2 = -yOffset
            wall[i].path.y3 = yOffset 
            wall[i].path.y4 = -yOffset
            wall[i].rotation = rotation
            wall[i]:setFillColor( math.random( 2, 4 )*0.1 )
            
            -- The physics body isn't a perfect fit, but it'll do for the game jam.
            physics.addBody( wall[i], "static", { friction = 0, bounce = 1 } )
        end

        local core = display.newCircle( display.contentCenterX, display.contentCenterY, coreRadius )
        core:setFillColor( 0.95, 0, 0 )
        physics.addBody( core, "static", { radius = coreRadius } )

        local function onCoreCollision( self, event )
            -- Prevent neutrons spawned from core by colliding with it immediately.
            if event.phase == "began" and event.other.isActive then
                display.remove( event.other )
                coreTemp = coreTemp + tempIncreasePerHit
                updateTemperature()
                
                print( "hey", gameover )
                
                if gameover then
                    -- isActive
                else
                    -- Nuclear fission time, spawn 3 neutrons from core.
                    for i = 1, 3 do
                        -- Spawn the neutron near the core's outer edge.
                        timer.performWithDelay( 1, function()
                            local angle = rad(random(360))
                            local radius = core.width*0.5 + neutronRadius*1.5
                            local x, y = cos(angle)*radius, sin(angle)*radius
                            
                            local projectile = newNeutron( core.x + x, core.y + y )
                            projectile.xScale, projectile.yScale = 0.5, 0.5
                            projectile.alpha = 0.25
                            
                            -- Fire the neutron projectile from the cannon with slight variation in its angle and velocity.
                            projectile:setLinearVelocity(
                                cos(angle+random(-neutronFireAngleVariance,neutronFireAngleVariance))*neutronBaseSpeed+random(-neutronSpeedVariance,neutronSpeedVariance),
                                sin(angle+random(-neutronFireAngleVariance,neutronFireAngleVariance))*neutronBaseSpeed+random(-neutronSpeedVariance,neutronSpeedVariance)
                            )
                            
                            transition.to( projectile, { time=150, alpha=1, xScale=1, yScale=1, onComplete=function()
                                if projectile then
                                    projectile.isActive = true
                                end
                            end})
                            
                            -- timer.performWithDelay( 250, function()
                            --     if projectile then
                            --         projectile.isActive = true
                            --         projectile.alpha = 1
                            --     end
                            -- end )
                            
                        end )
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
        
    end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene