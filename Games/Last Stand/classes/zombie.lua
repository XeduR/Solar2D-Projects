local zombie = {}

local zombieType = {
    ["normal"] = {
        animWalkSpeed = 500,
        animDeathSpeed = 250,
        revealTime = 1000,
        dropRate = 0.2,
        speed = 40,
        damage = 2,
        hp = 2,
        -- physics shape properties:
        widthMultiplier = 0.6,
        heightMultiplier = 0.9
    },
    ["fast"] = {
        animWalkSpeed = 250,
        animDeathSpeed = 250,
        revealTime = 500,
        dropRate = 0.3,
        speed = 100,
        damage = 1,
        hp = 1,
        -- physics shape properties:
        widthMultiplier = 0.5,
        heightMultiplier = 0.9
    },
    ["tank"] = {
        animWalkSpeed = 1000,
        animDeathSpeed = 500,
        revealTime = 3000,
        dropRate = 0.5,
        speed = 20,
        damage = 5,
        hp = 5,
        -- physics shape properties:
        widthMultiplier = 0.9,
        heightMultiplier = 0.9
    }
}

local zombieAnimation = {
    ["normal"] = {
        { name="walk", frames={ 1,2,3,4 }, time=zombieType["normal"].animWalkSpeed },
        { name="death", frames={ 5,6,7,8,9,10 }, loopCount=1, time=zombieType["normal"].animDeathSpeed },
    },
    ["fast"] = {
        { name="walk", frames={ 1,2,3,4 }, time=zombieType["normal"].animWalkSpeed },
        { name="death", frames={ 5,6,7,8,9,10 }, loopCount=1, time=zombieType["normal"].animDeathSpeed },
    },
    ["tank"] = {
        { name="walk", frames={ 1,2,3,4 }, time=zombieType["normal"].animWalkSpeed },
        { name="death", frames={ 5,6,7,8,9,10 }, loopCount=1, time=zombieType["normal"].animDeathSpeed },
    },
}

local zombieSheet = {
    ["normal"] = graphics.newImageSheet( "assets/images/zombieNormal.png", {
        width = 50,
        height = 50,
        numFrames = 10
    }),
    ["fast"] = graphics.newImageSheet( "assets/images/zombieFast.png", {
        width = 50,
        height = 50,
        numFrames = 10
    }),
    ["tank"] = graphics.newImageSheet( "assets/images/zombieTank.png", {
        width = 50,
        height = 50,
        numFrames = 10
    }),
}

-- An absolutely terrible drop rate/table implementation.
local weaponStats = require( "data.weaponStats" )
local dropTable = {
    { name="pistol", rate=weaponStats.pistol.rarity },
    { name="shotgun", rate=weaponStats.pistol.rarity + weaponStats.shotgun.rarity },
    { name="rifle", rate=weaponStats.pistol.rarity + weaponStats.shotgun.rarity + weaponStats.rifle.rarity }
}

local random = math.random
local atan2 = math.atan2
local cos = math.cos
local sin = math.sin
local pi2 = math.pi*2


function zombie.new( parent, ground, spawnDistance, filter, spriteListener, isFirstZombie )
    local angle = random()*pi2
    local spawnDistance = isFirstZombie and -120 or spawnDistance
    
    local x, y, r = (ground._width+spawnDistance)*cos(angle), (ground._height+spawnDistance*0.5)*sin(angle), random()
    
    local t
    if r < 0.7 then
        t = "normal"
    elseif r < 0.9 then
        t = "fast"
    else
        t = "tank"
    end
    local data = zombieType[t]
    local speed = data.speed
    
    local newZombie = display.newSprite( parent, zombieSheet[t], zombieAnimation[t] )
    newZombie.x, newZombie.y = ground.x+x, ground.y+y
    newZombie.anchorY = 1
    newZombie:addEventListener( "sprite", spriteListener )
    newZombie:setSequence( "walk" )
    newZombie:play()
    
    -- Just tossing drop rates for guns in here.
    if isFirstZombie or random() <= data.dropRate then
        r = random()
        
        local n = 1
        for i = 1, 3 do
            if r <= dropTable[i].rate then
                n = i
                break
            end
        end
        local drop = dropTable[n].name
        
        newZombie.weapon = display.newImage( parent, "assets/images/"..drop..".png" )
        newZombie.weapon.x, newZombie.weapon.y = newZombie.x, newZombie.y
        if drop == "pistol" then
            newZombie.weapon.yOffset = -newZombie.height*0.4
        else
            newZombie.weapon.yOffset = -newZombie.height*0.35
        end        
        newZombie.weapon.name = drop
        newZombie.weapon.isWeapon = true
        newZombie:toFront()
        
        newZombie.weapon.rotation = random( 60, 90 )
    end
    
    -- How many percent of zombie is feet.
    local feetRate = 0.25
    
    -- Manually adjust the shapes to account for transparent areas.
    local widthMultiplier = data.widthMultiplier
    local heightMultiplier = data.heightMultiplier
    
    local halfWidth = newZombie.width*0.5*widthMultiplier
    local torsoMinY = -newZombie.height*0.5*heightMultiplier
    local torsoMaxY = (newZombie.height*0.5 - newZombie.height*feetRate)*heightMultiplier
    local feetMinY = torsoMaxY
    local feetMaxY = newZombie.height*0.5*heightMultiplier
    
    local shapeTorso = { -halfWidth, torsoMinY, halfWidth, torsoMinY, halfWidth, torsoMaxY, -halfWidth, torsoMaxY }
    local shapeFeet = { -halfWidth, feetMinY, halfWidth, feetMinY, halfWidth, feetMaxY, -halfWidth, feetMaxY }
    
    physics.addBody( newZombie, "dynamic",
        { shape=shapeFeet, filter = filter },
        { shape=shapeTorso, isSensor = true, filter = filter }
    )
    newZombie.isFixedRotation = true
    newZombie.isZombie = true
    newZombie.hp = data.hp
    newZombie.damage = data.damage
    
    if not isFirstZombie then
        transition.from( newZombie, { time=data.revealTime, alpha=0 } )
        transition.from( newZombie.weapon, { time=data.revealTime, alpha=0 } )
    end
    
    local xDirPrev = 0
    
    function newZombie.move( target )
        if newZombie.isKilled then
            newZombie:setLinearVelocity( 0, 0 )
        else
            local vx, vy
            -- Move towards the target or wander arounda aimlessly.
            if target then
                vx, vy = target.x - newZombie.x, target.y - newZombie.y
            else
                vx, vy = random(-10,10), random(-10,10)
            end
            
            -- Keep track of current and previous direction.
            local xDir = vx < 0 and -1 or 1
            if xDir ~= xDirPrev then
                newZombie.xScale = xDir
                xDirPrev = xDir
            end
            
            if newZombie.weapon then
                newZombie.weapon.x, newZombie.weapon.y = newZombie.x, newZombie.y + newZombie.weapon.yOffset
            end
            
            local angle = atan2( vy, vx )
            newZombie:setLinearVelocity( cos(angle)*speed, sin(angle)*speed )
        end
    end
    
    return newZombie
end

return zombie