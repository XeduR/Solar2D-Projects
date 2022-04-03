local controls = {}

local keyBindings = require("data.controls")

local moveSpeed = 180
local dashImpulse = 0.5
local dashDuration = 150
local dashCooldown = 500

local vxPrev, vyPrev = 0, 0
local holdingDown = {}
local key = {}
local player
local hasMoved

local atan2 = math.atan2
local cos = math.cos
local sin = math.sin

-- Read key bindings and revert the keys and values.
for k, v in pairs( keyBindings ) do
    -- print( k )
    for i = 1, #v do
        -- print( "\t"..v[i] )
        key[v[i]] = k
    end
end



local dirX, dirY

local function update()
    -- Normalised x and y movement vectors.
    local vx, vy = 0, 0
    
    if holdingDown.left then
        vx = -1
    end
    if holdingDown.right then
        vx = vx + 1
    end
    if holdingDown.down then
        vy = 1
    end
    if holdingDown.up then
        vy = vy - 1
    end
    
    if vx == 0 and vy == 0 then
        if hasMoved then
            hasMoved = false
            player:setLinearVelocity( 0, 0 )
            if vyPrev < 0 then
                player:setSequence( "upIdle" )
            else
                player:setSequence( "downIdle" )
            end
            player:play()
            player:pause()
            vxPrev, vyPrev = vx, vy
        end
        return
    end
    hasMoved = true
    
    local angle = atan2( vy, vx )
    player:setLinearVelocity( cos(angle)*moveSpeed, sin(angle)*moveSpeed )

    -- Player is moving horizontally and has changed direction?
    local xChange = (vx ~= 0 and vx ~= vxPrev)
    if xChange or (vy ~= 0 and vy ~= vyPrev) then
        if vy < 0 then
            player:setSequence( "upRun" )
        else
            player:setSequence( "downRun" )
        end
        player:play()
        if xChange then
            player.xScale = vx
        end
    end
    
    vxPrev, vyPrev = vx, vy
end


-- Track what buttons the player is holding down.
local function onKeyEvent( event )
    -- React only to specific key bindings.
    local keyName = key[event.keyName]
    if keyName then
        local isDown = event.phase == "down"
        if keyName == "dash" then
            if (vxPrev ~= 0 or vyPrev ~= 0) and isDown and player.canDash and player.bodyType then
                controls.stop()
                player.isDashing = true
                local angle = atan2( vyPrev, vxPrev )
                player:applyLinearImpulse( cos(angle)*dashImpulse, sin(angle)*dashImpulse, player.x, player.y )
                timer.performWithDelay( dashDuration, controls.start )
                player.dash( dashDuration+dashCooldown )
            end
        else
            holdingDown[keyName] = isDown
        end
    end
end


function controls.init( playerRef )
    player = playerRef
    Runtime:addEventListener( "key", onKeyEvent )
    return key -- Borrow the keys for game.
end


function controls.start()
    if not player.isKilled then
        hasMoved = false
        player.isDashing = false
        player:setLinearVelocity( 0, 0 )
        Runtime:addEventListener( "enterFrame", update )
        -- Runtime:addEventListener( "key", onKeyEvent )
    end
end


function controls.stop()
    Runtime:removeEventListener( "enterFrame", update )
    -- Runtime:removeEventListener( "key", onKeyEvent )
end


function controls.releaseKeys()
    for k, v in pairs( holdingDown ) do
        holdingDown[k] = false
    end
end

return controls