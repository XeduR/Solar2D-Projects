local zombie = {}

local zombieType = {
    ["normal"] = {
        animWalkSpeed = 500,
        animDeathSpeed = 250,
        revealTime = 1000,
        dropRate = 0.25,
        speed = 30,
        damage = 2,
        hp = 2,
        -- physics shape properties:
        widthMultiplier = 0.9,
        heightMultiplier = 0.9
    },
    ["fast"] = {
        animWalkSpeed = 250,
        animDeathSpeed = 250,
        revealTime = 500,
        dropRate = 0.5,
        speed = 60,
        damage = 1,
        hp = 1,
        -- physics shape properties:
        widthMultiplier = 0.9,
        heightMultiplier = 0.9
    },
    ["tank"] = {
        animWalkSpeed = 1000,
        animDeathSpeed = 500,
        revealTime = 3000,
        dropRate = 0.25,
        speed = 10,
        damage = 5,
        hp = 5,
        -- physics shape properties:
        widthMultiplier = 0.9,
        heightMultiplier = 0.9
    }
}

local zombieAnimation = {
    ["normal"] = {
        { name="downRun", frames={ 2,3,4 }, time=zombieType["normal"].animWalkSpeed },
        { name="upRun", frames={ 6,7,8 }, time=zombieType["normal"].animWalkSpeed },
        { name="death", frames={ 9,10,11,12 }, loopCount=1, time=zombieType["normal"].animDeathSpeed },
    },
    ["fast"] = {
        { name="downRun", frames={ 2,3,4 }, time=zombieType["fast"].animWalkSpeed },
        { name="upRun", frames={ 6,7,8 }, time=zombieType["fast"].animWalkSpeed },
        { name="death", frames={ 9,10,11,12 }, loopCount=1, time=zombieType["fast"].animDeathSpeed },
    },
    ["tank"] = {
        { name="downRun", frames={ 2,3,4 }, time=zombieType["tank"].animWalkSpeed },
        { name="upRun", frames={ 6,7,8 }, time=zombieType["tank"].animWalkSpeed },
        { name="death", frames={ 9,10,11,12 }, loopCount=1, time=zombieType["tank"].animDeathSpeed },
    },
}

local zombieSheet = {
    ["normal"] = graphics.newImageSheet( "assets/images/zombieNormal.png", {
        width = 64,
        height = 128,
        numFrames = 12
    }),
    ["fast"] = graphics.newImageSheet( "assets/images/zombieFast.png", {
        width = 64,
        height = 128,
        numFrames = 12
    }),
    ["tank"] = graphics.newImageSheet( "assets/images/zombieTank.png", {
        width = 64,
        height = 128,
        numFrames = 12
    }),
}

local random = math.random
local atan2 = math.atan2
local cos = math.cos
local sin = math.sin
local pi2 = math.pi*2

function zombie.new( parent, ground, spawnDistance, filter, spriteListener )
    local angle = random()*pi2
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
    newZombie:setFillColor(1,0,0)
    newZombie:addEventListener( "sprite", spriteListener )
    
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
    
    transition.from( newZombie, { time=data.revealTime, alpha=0 } )
    
    local xDirPrev, yDirPrev = 0, 0
    
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
            
            -- Keep track of current and previous directions.
            local xDir, yDir = vx < 0 and -1 or 1, vy < 0 and -1 or 1
            if xDir ~= xDirPrev or yDir ~= yDirPrev then
                if yDir < 0 then
                    newZombie:setSequence( "upRun" )
                else
                    newZombie:setSequence( "downRun" )
                end
                newZombie:play()
                newZombie.xScale = xDir
                xDirPrev, yDirPrev = xDir, yDir
            end
            
            local angle = atan2( vy, vx )
            newZombie:setLinearVelocity( cos(angle)*speed, sin(angle)*speed )
        end
    end
    
    return newZombie
end

return zombie