local zombie = {}

local zombieType = {
    ["normal"] = {
        -- image = "",
        speed = 10,
        hp = 2,
    },
    ["fast"] = {
        -- image = "",
        speed = 35,
        hp = 1,
    },
    ["tank"] = {
        -- image = "",
        speed = 5,
        hp = 5,
    }
}

-- https://docs.coronalabs.com/api/library/graphics/newImageSheet.html
-- https://docs.coronalabs.com/api/library/display/newSprite.html

local random = math.random
local atan2 = math.atan2
local cos = math.cos
local sin = math.sin
local pi2 = math.pi*2

function zombie.new( parent, ground, spawnDistance, filter, onCollision, isFirstZombie )
    local angle = random()*pi2
    local x, y, r
    if isFirstZombie then
        x, y, r = random( -ground._width*0.5, ground._width*0.5 ), ground._height*0.5, 0
    else
        x, y, r = (ground._width+spawnDistance)*cos(angle), (ground._height+spawnDistance*0.5)*sin(angle), random()
    end
    
    local data
    if r < 0.75 then
        data = zombieType["normal"]
    elseif r < 0.9 then
        data = zombieType["fast"]
    else
        data = zombieType["tank"]
    end
    
    -- local newZombie = display.newSprite()
    local newZombie = display.newRect( parent, ground.x+x, ground.y+y, 40, 80 )
    newZombie.anchorY = 1
    newZombie:setFillColor(1,0,0)
    
    physics.addBody( newZombie, "dynamic", {
        box = { halfWidth=newZombie.width*0.5, halfHeight=newZombie.height*0.125, x=0, y=-newZombie.height*0.125 },
        filter = filter
    } )
    newZombie.isFixedRotation = true
    newZombie.isZombie = true
    newZombie.hp = data.hp
    
    transition.from( newZombie, { time=500, alpha=0 } )
    
    function newZombie.move( target )
        local vx, vy
        -- Move towards the target or wander arounda aimlessly.
        if target then
            vx, vy = target.x - newZombie.x, target.y - newZombie.y
        else
            vx, vy = random(-10,10), random(-10,10)
        end
        
        local angle = atan2( vy, vx )
        local speed = data.speed
        
        newZombie:setLinearVelocity( cos(angle)*speed, sin(angle)*speed )
    end
    
    return newZombie
end

return zombie