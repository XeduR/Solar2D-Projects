local controls = {}

local keyBindings = require("data.controls")

local moveSpeed = 180
local dashImpulse = 1
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



local function update()
    -- Normalised x and y movement vectors.
    local vx, vy = 0, 0
    
    if holdingDown.left then
        vx = 1
    end
    if holdingDown.right then
        vx = vx - 1
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
            vxPrev, vyPrev = vx, vy
            player:setLinearVelocity( 0, 0 )
            -- player:stop()
        end
        return
    end
    hasMoved = true
    
    local angle = atan2( vx, vy )
    player:setLinearVelocity( -sin(angle)*moveSpeed, cos(angle)*moveSpeed )

    -- Player is moving horizontally and has changed direction?
    if vx ~= 0 and vx ~= vxPrev then
        -- Animation wasn't running before.
        if vxPrev == 0 and vyPrev == 0 then
            -- player:setSequence( "run" )
            -- player:play()
        end
        player.xScale = vx
    end
    -- Player is moving vertically, but animation isn't active?
    if vy ~= 0 and vy ~= vyPrev and vx == 0 then
        -- player:play()
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
            if (vxPrev ~= 0 or vyPrev ~= 0) and isDown and player.canDash then
                local angle = atan2( vxPrev, vyPrev )
                player:applyLinearImpulse( -sin(angle)*dashImpulse, cos(angle)*dashImpulse, player.x, player.y )
                player.dash( dashCooldown )
            end
        else
            holdingDown[keyName] = isDown
        end
    end
end


function controls.init( playerRef )
    player = playerRef
end


function controls.start()
    hasMoved = false
    Runtime:addEventListener( "enterFrame", update )
    Runtime:addEventListener( "key", onKeyEvent )
end


function controls.stop()
    Runtime:removeEventListener( "enterFrame", update )
    Runtime:removeEventListener( "key", onKeyEvent )
end


return controls