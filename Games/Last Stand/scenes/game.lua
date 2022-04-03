local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local sfx = require("classes.sfx")
local utils = require("libs.utils")
local loadsave, savedata

local controls = require("classes.controls")
local zombie = require("classes.zombie")
local physics = physics or require("physics")
physics.setDrawMode( "hybrid" )
physics.start()
physics.setGravity( 0, 0 )

---------------------------------------------------------------------------

-- NB! The game's playable area is an ellipse with width=R and height=R*0.5,
-- which means that when placing objects around the ellipse, in order to
-- maintain the perspective, all y offsets, etc. must be using 0.5 multiplier.

---------------------------------------------------------------------------

-- Forward declarations & variables.
local random = math.random
local sqrt = math.sqrt
local atan2 = math.atan2
local cos = math.cos
local sin = math.sin
local pi = math.pi

local maxHealth = 5
 -- How much relatively slower will dash recover after taking 1 point of damage.
local dashHealthModifier = 0.25
local bulletSpeed = 1000

local currentHealth

-- How many pixels away from the ground's outer radius do the zombies spawn.
local spawnDistance = 100
local spawnVariance = 250
local spawnRateStart = 1000
local spawnRateCurrent

local groundWidthHalf = 320
local groundHeightHalf = 160
local groundOffsetY = 60
local groundLineVariance = 5
local groundVertices = 32
local groundBodyOffsetX = 20
local groundBodyOffsetY = groundBodyOffsetX*0.5

local cleanupTime = 2500

-- filterPlayer: collides with zombie & ground.
local filterPlayer = { categoryBits=1, maskBits=6 }
-- filterZombie - collides with player, bullets & zombies.
local filterZombie = { categoryBits=2, maskBits=11 }
-- filterGround - collides with player.
local filterGround = { categoryBits=4, maskBits=1 }
-- filterBullet - collides with zombies.
local filterBullet = { categoryBits=8, maskBits=2 }


local playerAnimSpeed = 500
local playerAnimation = {
    { name="downIdle", frames={ 1 }, loopCount=1 },
    { name="downRun", frames={ 2,3,4 }, time=playerAnimSpeed },
    { name="upIdle", frames={ 5 }, loopCount=1 },
    { name="upRun", frames={ 6,7,8 }, time=playerAnimSpeed },
}

local playerSheet = graphics.newImageSheet( "assets/images/player.png", {
    width = 64,
    height = 128,
    numFrames = 8
} )

local groupBackground = display.newGroup()
local groupCharacters = display.newGroup()
local groupUI = display.newGroup()

local groundLine = {}
local zombieList = {}
local player
local ground
local timerZombie
local spawnZombie
local mouseClicked
local zombieTarget
local isGameover
local zombieCount
local startGame

---------------------------------------------------------------------------

-- Functions.
local function calculateGroundLines( y, width, height )
    return sqrt( width*width*(1-(y*y)/(height*height)) )
end

local function getVerticesEllipse( n, width, height )
	local v, theta, dtheta = {}, 0, pi*2/n

	local height = height or width
	for i = 1, n*2, 2 do
		v[i] = width * cos(theta)
		v[i+1] = height * sin(theta)
		theta = theta + dtheta
	end

	return v
end

local function resetDash()
    player.canDash = true
end


local function attack( event )
    if event.isPrimaryButtonDown and not mouseClicked then
        mouseClicked = true
        
        local bullet = display.newCircle( groupCharacters, player.x, player.y - player.height*0.5, 4 )
        bullet:setFillColor( 251/255, 245/255, 239/255 )
        physics.addBody( bullet, {
            radius = bullet.width*0.5,
            filter = filterBullet
        })
        bullet.isBullet = true
        
        local a = atan2( event.y-bullet.y, event.x-bullet.x )
        bullet:setLinearVelocity( cos(a)*bulletSpeed, sin(a)*bulletSpeed )
        
        timer.performWithDelay( 500, function()
            -- if bu
        end )
        
    elseif not event.isPrimaryButtonDown and mouseClicked then
        mouseClicked = false
        
    end
end


local function update()
    for i = 1,zombieCount do
        local t = zombieList[i]
        if t then
            t.move( zombieTarget )
        end
    end    
end


local cover = display.newRect( groupUI, screen.centerX, screen.centerY, screen.width, screen.height )
cover:setFillColor(0)
cover.alpha = 1

local function cleanup()
    for i = 1, zombieCount do
        display.remove( zombieList[i] )
        zombieList[i] = nil
    end
    
    startGame()
end


local function stopGame()
    isGameover = true
    zombieTarget = nil
    timer.cancel( timerZombie )
    timerZombie = nil
    controls.stop()
    controls.releaseKeys()
    player:setLinearVelocity(0,0)
    Runtime:removeEventListener( "mouse", attack )
    -- Wait until next frame to give the zombies new directions.
    timer.performWithDelay( 1, function()
        Runtime:removeEventListener( "enterFrame", update )
    end )
    
    transition.to( cover, { time=cleanupTime, alpha=1, onComplete=cleanup })
end


function startGame()
    player.x, player.y = ground.x, ground.y
    player.canDash = true
    player.hp = maxHealth
    
    zombieCount = 0
    isGameover = false
    spawnRateCurrent = spawnRateStart
    mouseClicked = false
    currentHealth = maxHealth
    zombieTarget = player
    
    controls.start()
    Runtime:addEventListener( "mouse", attack )
    timerZombie = timer.performWithDelay( spawnRateCurrent, spawnZombie )
    Runtime:addEventListener( "enterFrame", update )
    
    transition.to( cover, { time=cleanupTime, alpha=0 })
end


local function onCollision( event )
    if not isGameover and event.phase == "began" then
        -- Figure out what is colliding and with what.
        local player = event.object1.isPlayer and event.object1 or event.object2.isPlayer and event.object2 or nil
        local bullet = event.object1.isBullet and event.object1 or event.object2.isBullet and event.object2 or nil
        local zombie = event.object1.isZombie and event.object1 or event.object2.isZombie and event.object2 or nil
        
        -- player hits zombie.
        if player and zombie then
            currentHealth = currentHealth-1
            if currentHealth <= 0 then
                stopGame()
            end
            -- If player is mid dash, then kill the zombie.
            if player.isDashing then
                transition.to( zombie, {alpha=0, time=100, onComplete=function()
                    display.remove(zombie)
                    zombieList[zombie.id] = nil
                end})
            end
            
        -- bullet hits zombie.
        elseif bullet and zombie then
            display.remove( bullet )
            bullet = nil
            transition.to( zombie, {alpha=0, time=100, onComplete=function()
                display.remove(zombie)
                zombieList[zombie.id] = nil
            end})
            
        -- bullet hits level bounds.
        elseif bullet then
            
            
        end      
    end
end


function spawnZombie()
    zombieCount = zombieCount+1
    zombieList[zombieCount] = zombie.new( groupCharacters, ground, spawnDistance, filterZombie )
    zombieList[zombieCount].id = zombieCount
    
    timerZombie = timer.performWithDelay( spawnRateCurrent+random(-spawnVariance,spawnVariance), spawnZombie )
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
    
    -- local title = 
    
    -- Create the ground using jagged lines to give it a rougher look.
    ground = display.newGroup()
    ground.x, ground.y = screen.centerX, screen.centerY + groundOffsetY
    groupBackground:insert(ground)
    ground._width = groundWidthHalf
    ground._height = groundHeightHalf
    
    for i = 1, groundHeightHalf*2-1 do
        local y = i-groundHeightHalf
        local x = calculateGroundLines( y, groundWidthHalf, groundHeightHalf )
        groundLine[i] = display.newRect( ground, random(-groundLineVariance,groundLineVariance), y, x*2, 1 )
        groundLine[i]:setFillColor( 73/255, 77/255, 126/255 )
    end
    -- Create a chain around the ground to constrain the player movement.
    local groundShape = getVerticesEllipse( groundVertices, groundWidthHalf+groundBodyOffsetX, groundHeightHalf+groundBodyOffsetY )
    physics.addBody( ground, "static", {
        chain = groundShape,
        connectFirstAndLastChainVertex = true,
        filter = filterGround
    } )
    
    -- Create the player.
    player = display.newSprite( groupCharacters, playerSheet, playerAnimation )
    player.x, player.y = ground.x, ground.y
    player.anchorY = 1
    physics.addBody( player, "dynamic", {
        -- Add the physics body to roughly the player's feet, bottom 25% of the player model.
        box = { halfWidth=player.width*0.5, halfHeight=player.height*0.125, x=0, y=-player.height*0.125 },
        filter = filterPlayer
    } )
    player.isFixedRotation = true
    player.canDash = true
    player.hp = maxHealth
    player.isPlayer = true
    -- player.collision = onCollision
    -- player:addEventListener( "collision" )
    Runtime:addEventListener( "collision", onCollision )
    
    function player.dash( time )
        local time = (1 + dashHealthModifier*(maxHealth - player.hp))*time
        -- Animate the dash somehow and show a countdown until dash is ready again.
        player.canDash = false
        timer.performWithDelay( time, resetDash )
    end
    
    sceneGroup:insert(groupBackground)
    sceneGroup:insert(groupCharacters)
    sceneGroup:insert(groupUI)
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
        controls.init( player )
        startGame()
        
    end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene