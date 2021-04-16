local composer = require( "composer" )
local scene = composer.newScene()

local physics = require("physics")
physics.start()
physics.setGravity( 0, 0 )

local sfx = require( "scripts.sfx" )
local screen = require( "scripts.screen" )
local levelData = require( "data.levels" )
local clock = require( "scripts.clock" )

-------------------------------

local _cos = math.cos
local _sin = math.sin
local _rad = math.rad
local _max = math.max
local _min = math.min
local _sqrt = math.sqrt
local _floor = math.floor
local _dRemove = display.remove

-------------------------------

local moveSpeed = 2.5
local visionRange = 160
local alertRadius = 20
local playerRadius = 16
local raycastAngles = 60
local raycastAnglesH = raycastAngles*0.5
local caughtDistance = alertRadius+8

local halfW = screen.width*0.5
local halfH = screen.height*0.5
local moveSpeedDiagonal = _sqrt(moveSpeed)

-------------------------------

local groupGround = display.newGroup()
local groupObjects = display.newGroup()
local groupVision = display.newGroup()
local groupWalls = display.newGroup()
local snapshot = display.newSnapshot( groupVision, screen.width, screen.height )
snapshot:translate( halfW, halfH )
local groupUI = display.newGroup()

local overlay = display.newRect(0,0,screen.width, screen.height)
overlay:setFillColor(0)
snapshot.group:insert(overlay)

local whoCaught = display.newImage( groupUI, "images/caught.png", 0, 0 )
whoCaught.alpha = 0
whoCaught.anchorY = 1

local guard = {}
local camera = {}
local action = {}
local object = {}
local player
local lootText
local playerSeen = false
local blockTouch = true
local gotLoot = false
local canMove = false
local lootCount = 0
local totalLoot = 0
local gameClock
local buttonMenu
local visionBlock
local startTimer
local countdown
local gameover
transition.ignoreEmptyReference = true

local currentFrame = 0
local framesUntilSwap = 10

local function updateGuards()
    for i = 1, #guard do
        local t = guard[i]
        t:vision()
        -- Check if player is too close to the guard.
        if _sqrt((player.x-t.x)^2 + (player.y-t.y)^2) < caughtDistance then
            if not playerSeen then
                playerSeen = true
                whoCaught.x, whoCaught.y = t.x, t.y-10
                whoCaught.alpha = 1
                gameover("guard")
                Runtime:removeEventListener( "enterFrame", updateGuards )
            end
        end
        -- Update the guard's animation.
        if t.x ~= t.prevX or t.y ~= t.prevY then
            t.currentFrame = t.currentFrame+1
            if t.currentFrame == framesUntilSwap then
                t.currentFrame = 0
                t.usingFrame1 = not t.usingFrame1
                if t.usingFrame1 then
                    t.fill = t.frame1
                else
                    t.fill = t.frame2
                end
            end
        end
        t.prevX, t.prevY = t.x, t.y
    end
    for i = 1, #camera do
        local cam = camera[i]
        _dRemove(cam.scan)
        cam.scan = nil
        
        local angle = _rad(cam.rotation)
        local xStart = cam.x
        local yStart = cam.y
        local xEnd = cam.x+visionRange*_cos(angle)
        local yEnd = cam.x-visionRange*_sin(angle)
        local hits = physics.rayCast( xStart, yStart, xEnd, yEnd, "closest" )
        
        if ( hits ) then
            cam.scan = display.newLine( groupWalls, xStart, yStart, hits[1].position.x, hits[1].position.y )
            cam.scan:toBack()
            cam.scan.strokeWidth = 2
            cam.scan:setStrokeColor( 0.9, 0, 0 )
            
            if hits[1].object.isPlayer then
                playerSeen = true
                whoCaught.x, whoCaught.y = cam.x, cam.y-10
                whoCaught.alpha = 1
                gameover("camera")
                Runtime:removeEventListener( "enterFrame", updateGuards )
            end
        else
            cam.scan = display.newLine( groupWalls, xStart, yStart, xEnd, yEnd )
            cam.scan:toBack()
            cam.scan.strokeWidth = 2
            cam.scan:setStrokeColor( 0.9, 0, 0 )
        end
    end
end

local function movePlayer()
    if player then
        local rotation
        if action["a"] or action["left"] then
            if action["w"] or action["up"] then
                rotation = -135
        		player:translate( -moveSpeedDiagonal, -moveSpeedDiagonal )
            elseif action["s"] or action["down"] then
                rotation = 135
        		player:translate( -moveSpeedDiagonal, moveSpeedDiagonal )
            else
                rotation = 180
        		player:translate( -moveSpeed, 0 )
            end
        elseif action["d"] or action["right"] then
            if action["w"] or action["up"] then
                rotation = -45
        		player:translate( moveSpeedDiagonal, -moveSpeedDiagonal )
            elseif action["s"] or action["down"] then
                rotation = 45
        		player:translate( moveSpeedDiagonal, moveSpeedDiagonal )
            else
                rotation = 0
        		player:translate( moveSpeed, 0 )
            end
        else
            if action["w"] or action["up"] then
                rotation = -90
        		player:translate( 0, -moveSpeed )
            elseif action["s"] or action["down"] then
                rotation = 90
        		player:translate( 0, moveSpeed )
            end
        end
        if rotation then
            currentFrame = currentFrame+1
            if currentFrame == framesUntilSwap then
                currentFrame = 0
                player.usingFrame1 = not player.usingFrame1
                if player.usingFrame1 then
                    player.fill = player.frame1
                else
                    player.fill = player.frame2
                end
            end
            player.rotation = rotation
        end
        if gotLoot then
            if _sqrt((player.x-player.escapeRadius.x)^2+(player.y-player.escapeRadius.y)^2) <= player.escapeRadius.width*0.5 then
                gameover("won")
            end
        end
    end
end

local function onKeyEvent( event )
    if event.phase == "down" then
		action[event.keyName] = true
    else
		action[event.keyName] = false
    end
end


local function pickupLoot(loot)
    _dRemove(loot)
    loot = nil
    
    gotLoot = true
    lootCount = lootCount+1
    lootText.text = "Loot left: "..totalLoot-lootCount
    player.escapeRadius.alpha = 1
end

local function onCollision( self, event )
    if ( event.phase == "began" ) then
        if self.isPlayer  and event.other.isLoot and not event.other.taken then
            event.other.taken = true
            pickupLoot(event.other)
        end
    end
end
 

local function newGuard( input )
    local object = display.newRect( groupObjects, input.x, input.y, 20, 20 )
    object.fov = {}
    
    object.frame1 = {
        type = "image",
        filename = "images/guard_walk1.png"
    }
    object.frame2 = {
        type = "image",
        filename = "images/guard_walk2.png"
    }
    object.prevX, object.prevY = x or 0, y or 0
    object.currentFrame = 0
    object.usingFrame1 = true
    object.fill = object.frame1
    
    object.aura = display.newCircle( groupVision, object.x-halfW, object.y-halfH, alertRadius )
    snapshot.group:insert(object.aura)
        
    object.currentRoute = 0
    object.route = {}
    for i = 1, #input.route do
        local r = input.route[i]
        object.route[i] = { x=r.x, y=r.y, r=r.r, delay=r.delay, time=r.time }
    end
    
    function object:vision()
        if not playerSeen then
            
            self.aura.x, self.aura.y = self.x-halfW, self.y-halfH
            for i = 1, #self.fov do
                self.fov[i] = nil
            end
            self.fov[1], self.fov[2] = self.x, self.y
            
            for i = 1, raycastAngles do
                local xStart = self.x
                local yStart = self.y
                local xEnd = _floor(self.x+visionRange*_cos(_rad(self.rotation-raycastAnglesH+i))+0.5)
                local yEnd = _floor(self.y+visionRange*_sin(_rad(self.rotation-raycastAnglesH+i))+0.5)
                local hits = physics.rayCast( xStart, yStart, xEnd, yEnd, "closest" )
                if hits then
                    if hits[1].object.isPlayer then
                        if not playerSeen then
                            playerSeen = true
                            whoCaught.x, whoCaught.y = self.x, self.y-20
                            whoCaught.alpha = 1
                            gameover("guard")
                            Runtime:removeEventListener( "enterFrame", updateGuards )
                        end
                        local hits = physics.rayCast( xStart, yStart, xEnd, yEnd, "sorted" )
                        if hits and #hits > 1 then
                            xEnd, yEnd = _floor(hits[2].position.x+0.5), _floor(hits[2].position.y+0.5)
                        end
                    else
                        xEnd, yEnd = _floor(hits[1].position.x+0.5), _floor(hits[1].position.y+0.5)
                    end
                end
                if xEnd ~= self.fov[#self.fov-1] or yEnd ~= self.fov[#self.fov] then
                    self.fov[#self.fov+1], self.fov[#self.fov+2] = xEnd, yEnd
                end
            end
            _dRemove(self.sight)
            self.sight = nil
            
            -- TODO: The sight, i.e. field of vision, is a but bumpy. If time, then fix.
            self.sight = display.newPolygon( --groupVision,
                (_min( self.fov[1], self.fov[3], self.fov[#self.fov-1] )+_max( self.fov[1], self.fov[3], self.fov[#self.fov-1] ))*0.5-halfW,
                (_min( self.fov[2], self.fov[4], self.fov[#self.fov] )+_max( self.fov[2], self.fov[4], self.fov[#self.fov] ))*0.5-halfH,
                self.fov
            )
            snapshot.group:insert(self.sight)
        end
        snapshot:invalidate()
    end
    
    guard[#guard+1] = object
end

local function returnToMenu( event )
    if event.phase == "ended" then
        blockTouch = true
        if startTimer then
            timer.cancel( startTimer )
            startTimer = nil
        end
        composer.gotoScene( "scripts.menu", {
            time=500,
            effect="slideRight",
            params={}
        })
    end
    return true
end

function gameover( reason )
    transition.cancelAll()
    local delay = 1500
    if reason == "time" then
        countdown.text = "Time's up!"
    elseif reason == "guard" then
        countdown.text = "A guard saw you!"
    elseif reason == "camera" then
        countdown.text = "A camera saw you!"
    elseif reason == "won" then
        countdown.text = "Success!"
        delay = 0
        local temp = display.newText( "You collected "..lootCount.." out of "..totalLoot.." loot!", screen.xCenter, screen.yCenter+120, "fonts/Action_Man.ttf", 28 )
        temp.alpha = 0
        transition.to( temp, {time=500,alpha=1})
        timer.performWithDelay( 4000+delay, function()
            _dRemove(temp)
        end )
    end
    transition.to( countdown, {delay=delay,time=250,alpha=1,xScale=1,yScale=1} )
    transition.to( visionBlock, {delay=delay,time=250,alpha=1} )
    gameClock:stop()
    Runtime:removeEventListener( "enterFrame", movePlayer )
    Runtime:removeEventListener( "key", onKeyEvent )
    
    if not playerSeen then
        playerSeen = true
        Runtime:removeEventListener( "enterFrame", updateGuards )
    end
    
    startTimer = timer.performWithDelay( 4000+delay, function()
        returnToMenu({phase="ended"})
    end )
end

local function outOfTime()
    gameover("time")
end

local patrolTimePerPixel = 20
local function patrolRoute( guard )
    guard.currentRoute = guard.currentRoute+1
    if guard.currentRoute > #guard.route then
        guard.currentRoute = 1
    end
    transition.to( guard, {
        time = guard.route[guard.currentRoute].time or _sqrt((guard.x-(guard.route[guard.currentRoute].x or guard.x))^2+(guard.y-(guard.route[guard.currentRoute].y or guard.y))^2 )*patrolTimePerPixel,
        x = guard.route[guard.currentRoute].x,
        y = guard.route[guard.currentRoute].y,
        rotation = guard.route[guard.currentRoute].r,
        delay = guard.route[guard.currentRoute].delay,
        onComplete = function() patrolRoute(guard) end
    })
end

local function rotateCamera( cam )
    transition.to( cam, {
        time = cam.time,
        rotation = cam.returning and cam.r or cam.r+cam.angle,
        onComplete=function() rotateCamera(cam) end
    })
    cam.returning = not cam.returning
end

local function newCamera( cam )
    camera[#camera+1] = display.newImage( groupWalls,"images/camera.png", cam.x, cam.y )
    camera[#camera].rotation = cam.rotation or 0
    camera[#camera].r = cam.rotation or 60
    camera[#camera].time = cam.time or 1000
    camera[#camera].angle = cam.angle or 60
    camera[#camera].returning = false
end


local function startGame()
    lootCount = 0
    playerSeen = false
    startTimer = nil
    canMove = true
    gameClock:start(outOfTime)
    Runtime:addEventListener( "enterFrame", updateGuards )
    Runtime:addEventListener( "enterFrame", movePlayer )
    Runtime:addEventListener( "key", onKeyEvent )
    
    for i = 1, #guard do
        patrolRoute( guard[i] )
    end
    
    for i = 1, #camera do
        rotateCamera( camera[i] )
    end
    
    transition.to( player.escapeRadius, {time=750,xScale=1.1,yScale=1.1,transition=easing.continuousLoop,iterations=-1} )
end

local function updateCountdown()
    if countdown.value == 4 then
        countdown.alpha = 1
    end
    countdown.value = countdown.value-1
    countdown.text = countdown.value
    
    if countdown.value > 0 then
        transition.to( countdown, {time=250,xScale=1.5,yScale=1.5,transition=easing.continuousLoop} )
        startTimer = timer.performWithDelay( 980, updateCountdown )
    else
        transition.to( countdown, {time=250,alpha=0,xScale=1.5,yScale=1.5} )
        transition.to( visionBlock, {time=250,alpha=0} )
        startGame()
    end
end

local function resetCountdown()
    whoCaught.alpha = 0
    countdown.alpha = 0
    countdown.value = 4
    countdown.xScale, countdown.yScale = 1, 1
    visionBlock.alpha = 1
end

-------------------------------

function scene:create( event )
    local sceneGroup = self.view
    
    buttonMenu = display.newRect( screen.xMax+20, screen.yMin+20, 32, 32 )
    buttonMenu:addEventListener( "touch", returnToMenu )
    
    local background = display.newRect( groupGround, screen.xCenter, screen.yCenter, 960, 640 )
    display.setDefault( "textureWrapX", "repeat" )
    display.setDefault( "textureWrapY", "repeat" )
    background.fill = {
        type = "image",
        filename = "images/ground.png"
    }
    background.fill.scaleX = 32 / background.width
    background.fill.scaleY = 32 / background.height
    display.setDefault( "textureWrapX", "clampToEdge" )
    display.setDefault( "textureWrapY", "clampToEdge" )
    
    local clockImg = display.newImage( groupUI, "images/clock.png", screen.xMin+50, screen.yMin+52 )
    
    gameClock = clock.create( groupUI, screen.xMin+50, screen.yMin+61, "game" )
    
    lootText = display.newText( groupUI, "Loot left:", gameClock.x + 60, screen.yMin+30, "fonts/Action_Man.ttf", 28 )
    lootText.anchorX = 0

    visionBlock = display.newRect( groupUI, screen.xCenter, screen.yCenter, screen.width, screen.height)
    visionBlock:setFillColor(0)
    visionBlock.alpha = 0.9
    visionBlock:addEventListener( "touch", function(event) return true end )
    
    countdown = display.newText( groupUI, "3", screen.xCenter, screen.yCenter, "fonts/Action_Man.ttf", 76 )
    countdown.alpha = 0
    
    snapshot.alpha = 0.5
    snapshot.blendMode = "multiply"
    
    sceneGroup:insert(groupGround)
    sceneGroup:insert(groupObjects)
    sceneGroup:insert(groupVision)
    sceneGroup:insert(groupWalls)
    sceneGroup:insert(groupUI)
end


function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if phase == "will" then
        canMove = false
        gotLoot = false
        totalLoot = 0
        resetCountdown()
        transition.to( buttonMenu, {time=400,x=buttonMenu.x-40})
    
    elseif phase == "did" then
        
        -- Code here runs when the scene is first created but has not yet appeared on screen
        local data = levelData[event.params.level]
        local xStart, yStart = 64, 64
        
        for row = 1, #data.map do
            for column = 1, #data.map[row] do
                local t = data.map[row][column]
                local type = t:sub(1,4)
                if t ~= "empty" then
                    object[#object+1] = display.newImage( groupGround, "images/"..t..".png", xStart+32*(column-1), yStart+32*(row-1) )
                    if type == "wall" then
                        physics.addBody( object[#object], "static" )
                    end
                    -- if type == "wall" or type == "item" then
                    --     physics.addBody( object[#object], "static" )
                    --     if t == "item_loot" then
                    --         object.isLoot = true
                    --         totalLoot = totalLoot+1
                    --     elseif t == "item_plant" then
                    --         object.isPlant = true
                    --     end
                    -- end
                end
            end
        end
        lootText.text = "Loot left: "..totalLoot
        
        for i = 1, #data.guard do
            newGuard( data.guard[i] )
        end
        
        for i = 1, #data.camera do
            newCamera( data.camera[i] )
        end
        
        for i = 1, #data.loot do
            object[#object+1] = display.newImage( groupGround, "images/loot.png", data.loot[i].x, data.loot[i].y )
            object[#object].rotation = data.loot[i].r or 0
            physics.addBody( object[#object], "static" )
            object[#object].collision = onCollision
            object[#object]:addEventListener( "collision" )
            object[#object].isLoot = true
            totalLoot = totalLoot+1
        end
        
        player = display.newRect( groupObjects, data.player.x, data.player.y, 20, 20 )
        physics.addBody( player, "dynamic", {radius=10} )
        player.collision = onCollision
        player:addEventListener( "collision" )
        player.isPlayer = true
        player.gravityScale = 0
        
        player.frame1 = {
            type = "image",
            filename = "images/player_walk1.png"
        }
        player.frame2 = {
            type = "image",
            filename = "images/player_walk2.png"
        }
        player.usingFrame1 = true
        player.fill = player.frame1
        
        local plusOrMinus = math.random() > 0.5 and 1 or -1
        player.car = display.newImage( groupObjects, "images/car.png", player.x+plusOrMinus*math.random(80,120), player.y+plusOrMinus*math.random(20,40) )
        physics.addBody( player.car, "static" )
        if player.x < 480 then
            if player.y < 320 then
                player.car.rotation = math.random(-170,-150)
            else
                player.car.rotation = math.random(150,170)
            end
        else
            if player.y < 320 then
                player.car.rotation = math.random(-30,-10)
            else
                player.car.rotation = math.random(10,30)
            end
        end
        
        player.escapeRadius = display.newCircle( groupObjects, player.car.x, player.car.y, 60 )
        player.escapeRadius:toBack()
        player.escapeRadius:setFillColor(0.1,0.8,0.1,0.3)
        player.escapeRadius.alpha = 0
        
        blockTouch = false
        countdown.value = 0 -- uncomment to skip to game. 
        startTimer = timer.performWithDelay( 250, updateCountdown )
    end
end


function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase

    if phase == "will" then
        transition.to( buttonMenu, {time=400,x=buttonMenu.x+40})
        gameClock:stop()

    elseif phase == "did" then
        countdown.alpha = 0
        
        for i = 1, #guard do
            _dRemove(guard[i].aura)
            _dRemove(guard[i].sight)
            _dRemove(guard[i])
            guard[i] = nil
        end
        for i = 1, #camera do
            _dRemove(camera[i].scan)
            _dRemove(camera[i])
            camera[i] = nil
        end
        for i = 1, #object do
            _dRemove(object[i])
            object[i] = nil
        end
        for i, j in pairs(action) do
            action[i] = false
        end
        _dRemove(player.escapeRadius)
        _dRemove(player.car)
        _dRemove(player)
        player = nil
    end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

return scene