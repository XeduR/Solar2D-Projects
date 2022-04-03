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
local getTimer = system.getTimer
local random = math.random
local sqrt = math.sqrt
local atan2 = math.atan2
local cos = math.cos
local sin = math.sin
local max = math.max
local rad = math.rad
local pi = math.pi

local maxHealth = 5
 -- How much relatively slower will dash recover after taking 1 point of damage.
local dashHealthModifier = 0.25
local bulletSpeed = 1000

local currentHealth
local startTime

-- How many pixels away from the ground's outer radius do the zombies spawn.
local spawnDistance = 100
local spawnVariance = 250
local spawnRateStart = 1500
local spawnRateMax = 750
local spawnRateCurrent

local groundWidthHalf = 320
local groundHeightHalf = 160
local groundOffsetY = 60
local groundLineVariance = 5
local groundVertices = 32
local groundBodyOffsetX = 20
local groundBodyOffsetY = groundBodyOffsetX*0.5

-- How quickly the player needs to get away from a zombie before a new chomp
local chompTime = 500

-- Black screen cover transition time.
local cleanupTime = 3000

local weaponStats = {
    -- spread is in degrees to both directions.
    ["pistol"] = {
        damage = 2,
        penetration = 1,
        spread = 1,
        shotsFired = 1,
        clipSize = 18,
        startAmmo = 5,
        cooldown = 150,
        inventoryKey = "1",
    },
    ["shotgun"] = {
        damage = 1,
        penetration = 1,
        spread = 15,
        shotsFired = 8,
        clipSize = 6,
        startAmmo = 5,
        cooldown = 350,
        inventoryKey = "2",
    },
    ["rifle"] = {
        damage = 3,
        penetration = 3,
        spread = 2,
        shotsFired = 1,
        clipSize = 9,
        startAmmo = 5,
        cooldown = 600,
        inventoryKey = "3",
    },
}

-- filterPlayer: collides with zombie & ground.
local filterPlayer = { categoryBits=1, maskBits=6 }
-- filterZombie - collides with player, bullets & zombies.
local filterZombie = { categoryBits=2, maskBits=11 }
-- filterGround - collides with player.
local filterGround = { categoryBits=4, maskBits=1 }
-- filterBullet - collides with zombies.
local filterBullet = { categoryBits=8, maskBits=2 }


local walkAnimSpeed = 500
local deathAnimSpeed = 250
local playerAnimation = {
    { name="downIdle", frames={ 1 }, loopCount=1 },
    { name="downRun", frames={ 2,3,4 }, time=walkAnimSpeed },
    { name="upIdle", frames={ 5 }, loopCount=1 },
    { name="upRun", frames={ 6,7,8 }, time=walkAnimSpeed },
    { name="death", frames={ 9,10,11,12 }, loopCount=1, time=deathAnimSpeed },
}

local playerSheet = graphics.newImageSheet( "assets/images/player.png", {
    width = 64,
    height = 128,
    numFrames = 12
} )

local groupBackground = display.newGroup()
local groupCharacters = display.newGroup()
local groupUI = display.newGroup()

local weapon = "shotgun"
local gameState = "menu"
local groundLine = {}
local zombieList = {}
local bulletList = {}
local bulletCount
local zombieCount

local player
local ground
local key
local timerDash
local timerChomp = {}
local timerZombie
local spawnZombie
local zombieTarget
local startGame


local magazine, inventoryKey, lastFired = {}, {}, {}
for i, v in pairs( weaponStats ) do
    lastFired[i] = 0
    magazine[i] = v.startAmmo or 0
    inventoryKey[v.inventoryKey] = i
end

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


local function shoot( event )
    if gameState == "game" and event.phase == "began" then
        local data = weaponStats[weapon]
        local time = getTimer()
        
        -- Check for bullets and weapon cooldown.
        if magazine[weapon] > 0 and time > lastFired[weapon] + data.cooldown then
            lastFired[weapon] = time
            
            for i = 1, data.shotsFired do
                bulletCount = bulletCount+1
                
                local bullet = display.newCircle( groupCharacters, player.x, player.y - player.height*0.5, 4 )
                bullet:setFillColor( 251/255, 245/255, 239/255 )
                physics.addBody( bullet, {
                    radius = bullet.width*0.5,
                    filter = filterBullet,
                    isSensor = true,
                })
                bullet.id = bulletCount
                bullet.isBullet = true
                bullet.damage = data.damage
                bullet.penetration = data.penetration
                bullet.damage = data.damage
                
                local a = atan2( event.y-bullet.y, event.x-bullet.x )
                if data.spread > 0 then
                    a = a + rad(random( -data.spread, data.spread ))
                end
                bullet:setLinearVelocity( cos(a)*bulletSpeed, sin(a)*bulletSpeed )
                
                bulletList[bulletCount] = bullet
                
                timer.performWithDelay( 1000, function()
                    if bullet then
                        display.remove(bullet)
                        bulletList[bullet.id] = nil
                    end
                end )
            end
            magazine[weapon] = magazine[weapon]-1
        end
    end
end


local function update()
    for i = 1,zombieCount do
        if not zombieList[i].isKilled then
            zombieList[i].move( zombieTarget )
        end
    end    
end


local cover = display.newRect( groupUI, screen.centerX, screen.centerY, screen.width, screen.height )
cover:setFillColor(0)
cover.alpha = 0

-- Just doing dirty clean up. No object pooling or anything.
local function cleanup()
    for i = 1, zombieCount do
        if timerChomp[i] then
            timer.cancel( timerChomp[i] )
            timerChomp[i] = nil
        end
        display.remove( zombieList[i] )
        zombieList[i] = nil
    end
    for i = 1, bulletCount do
        display.remove( bulletList[i] )
        bulletList[i] = nil
    end
    
    gameState = "menu"
end



local function stopGame()
    if gameState == "game" then
        gameState = "gameover"
        
        Runtime:removeEventListener( "collision", onCollision )
        player.isKilled = true
        zombieTarget = nil
        
        if timerDash then
            timer.cancel( timerDash )
            timerDash = nil
        end
        timer.cancel( timerZombie )
        timerZombie = nil
        
        controls.stop()
        controls.releaseKeys()
        Runtime:removeEventListener( "mouse", shoot )
        
        -- Wait until next frame to give the zombies new directions.
        timer.performWithDelay( 1, function()
            Runtime:removeEventListener( "enterFrame", update )
        end )
        
        transition.to( cover, { time=cleanupTime, alpha=1, onComplete=cleanup })
    end
end


function startGame()
    player.x, player.y = ground.x, ground.y
    physics.addBody( player, "dynamic", {
        -- Add the physics body to roughly the player's feet, bottom 25% of the player model.
        box = { halfWidth=player.width*0.5, halfHeight=player.height*0.125, x=0, y=-player.height*0.125 },
        filter = filterPlayer
    } )
    player.isFixedRotation = true
    player.canDash = true
    player.hp = maxHealth
    player.isKilled = false
    
    player:setSequence( "downIdle" )
    player:play()
    
    weapon = "pistol"
    for i, v in pairs( weaponStats ) do
        lastFired[i] = 0
        magazine[i] = v.startAmmo or 0
    end
    
    bulletCount = 0
    zombieCount = 0
    
    startTime = getTimer()
    spawnRateCurrent = spawnRateStart
    currentHealth = maxHealth
    zombieTarget = player
    
    controls.start()
    Runtime:addEventListener( "mouse", shoot )
    timerZombie = timer.performWithDelay( (cover.alpha == 1 and cleanupTime or 0) + spawnRateCurrent, spawnZombie )
    Runtime:addEventListener( "enterFrame", update )
    Runtime:addEventListener( "collision", onCollision )
    
    transition.to( cover, { time=cleanupTime, alpha=0 })
    
    gameState = "game"
end


local function spriteListener( event )
    if event.phase == "ended" and event.target.isKilled then
           
        if event.target.isZombie then
            physics.removeBody( event.target )
            event.target:toBack()
        elseif event.target.isPlayer then
            physics.removeBody( player )
        end
    end
end

local function playerDamage( damage )
    local damage = type( damage ) == "table" and damage.source.damage or damage
    if not player.isKilled then
        currentHealth = currentHealth-damage
        if currentHealth <= 0 then
            player:setSequence("death")
            player:play()
            stopGame()
        end
    end
end

function onCollision( event )
    if not player.isKilled then
        -- Figure out what is colliding and with what.
        local player = event.object1.isPlayer and event.object1 or event.object2.isPlayer and event.object2 or nil
        local bullet = event.object1.isBullet and event.object1 or event.object2.isBullet and event.object2 or nil
        local zombie = event.object1.isZombie and event.object1 or event.object2.isZombie and event.object2 or nil
        
        -- Zombies can be shot anywhere, but player can only collide with zombies legs.
        local correctCollision = player and event.element1 == event.element2 or false
        
        if event.phase == "began" then
            -- player hits zombie.
            if correctCollision and player and zombie and not zombie.isKilled then
                playerDamage( zombie.damage )
                -- If player is mid dash, then kill the zombie.
                if player.isDashing then
                    zombie.isKilled = true
                    zombie:setSequence("death")
                    zombie:play()
                else
                    if timerChomp[zombie.id] then
                        timer.cancel( timerChomp[zombie.id] )
                    end
                    timerChomp[zombie.id] = timer.performWithDelay( chompTime, playerDamage, 0 )
                    timerChomp[zombie.id].damage = zombie.damage
                end
                
            -- bullet hits zombie.
            elseif bullet and zombie then
                zombie.hp = zombie.hp - bullet.damage
                if zombie.hp <= 0 and not zombie.isKilled then
                    zombie.isKilled = true
                    zombie:setSequence("death")
                    zombie:play()
                end
                
                bullet.penetration = bullet.penetration-1
                if bullet.penetration <= 0 then
                    display.remove( bullet )
                    bulletList[bullet.id] = nil
                end
                
            end
            
        elseif event.phase == "ended" then
            -- Stop the chomp timer if player got away.
            if correctCollision and player and zombie then
                if timerChomp[zombie.id] then
                    timer.cancel( timerChomp[zombie.id] )
                end
            end
        end
    end
end


function spawnZombie()
    zombieCount = zombieCount+1
    zombieList[zombieCount] = zombie.new( groupCharacters, ground, spawnDistance, filterZombie, spriteListener )
    zombieList[zombieCount].id = zombieCount
    
    spawnRateCurrent = max( spawnRateMax, spawnRateCurrent - (getTimer()-startTime)*0.001 )
    timerZombie = timer.performWithDelay( spawnRateCurrent+random(-spawnVariance,spawnVariance), spawnZombie )
end


-- Handle menu controls.
local function onKeyEvent( event )
    if event.phase == "down" then
        local keyName = event.keyName
        if keyName == "escape" or keyName == "esc" then
            if gameState == "game" then
                playerDamage( maxHealth )
            end
            
        elseif key[keyName] == "dash" then
            if gameState == "menu" then
                startGame()
            end
            
        else
            if gameState == "game" then
                local _weapon = inventoryKey[keyName]
                local ammo = magazine[_weapon]
                if ammo and ammo > 0 then
                    weapon = _weapon
                end
            end        
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
                audio = true,
                highscore = {},
            }
            loadsave.save( savedata, "data.json" )
        end
    end
    
    local bgSensor = display.newRect( groupBackground, screen.centerX, screen.centerY, screen.width, screen.height )
    bgSensor.isHitTestable = true
    bgSensor.isVisible = false
    bgSensor:addEventListener( "touch", shoot )
    
    local title = display.newImageRect( groupUI, "assets/images/title.png", 512, 128 )
    title.x, title.y = screen.centerX, screen.minY
    title.anchorY = 0
    
    local watermark = display.newImageRect( groupUI, "assets/images/launchScreen/XeduR.png", 256, 128 )
    watermark.x, watermark.y = screen.maxX + 20, screen.minY
    watermark.anchorX, watermark.anchorY = 1, 0
    
    local buttonAudio = display.newRect( groupUI, screen.minX + 10, screen.minY + 10, 64, 64 )
    buttonAudio.anchorX, buttonAudio.anchorY = 0, 0
    
    local fillOn = {
        type = "image",
        filename = "assets/images/audioOn.png"
    }
    local fillOff = {
        type = "image",
        filename = "assets/images/audioOff.png"
    }
    
    if savedata.audio then
        buttonAudio.fill = fillOn
    else
        buttonAudio.fill = fillOff
    end
    
    buttonAudio:addEventListener( "touch", function(event)
        if event.phase == "began" then
            savedata.audio = not savedata.audio
            if savedata.audio then
                buttonAudio.fill = fillOn
            else
                buttonAudio.fill = fillOff
            end
            loadsave.save( savedata, "data.json" )
        end
        return true
    end )
    
    
    local buttonReset = display.newImageRect( groupUI, "assets/images/restart.png", 64, 64 )
    buttonReset.x, buttonReset.y = buttonAudio.x + buttonAudio.width + 10, buttonAudio.y
    buttonReset.anchorX, buttonReset.anchorY = 0, 0
    buttonReset:addEventListener( "touch", function(event)
        if gameState == "game" and event.phase == "began" then
            playerDamage( maxHealth )
        end
        return true
    end )    
    
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
    player.isPlayer = true
    player:addEventListener( "sprite", spriteListener )
    
    function player.dash( time )
        local time = (1 + dashHealthModifier*(maxHealth - player.hp))*time
        -- Animate the dash somehow and show a countdown until dash is ready again.
        player.canDash = false
        timerDash = timer.performWithDelay( time, resetDash )
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
        key = controls.init( player )
        Runtime:addEventListener( "key", onKeyEvent )
        -- startGame()
        
    end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene