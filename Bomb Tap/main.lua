display.setDefault( "background", 0.3 )
local physics = require("physics")
physics.start()
physics.pause() -- Physics are paused until the game starts.
local shiftTimer, started

-- Images used in this project are from Ponywolf's Sticker Knight Platformer, CCO, (source: https://github.com/ponywolf/Sticker-Knight-Platformer)
local platformTop = display.newImage( "assets/platformBase3.png", display.contentCenterX, display.contentCenterY - 150 )
physics.addBody( platformTop, "static" )
platformTop.xScale, platformTop.yScale = -1, -1 -- Flip the top platform over its x and y-axes.

local platformBottom = display.newImage( "assets/platformBase3.png", display.contentCenterX, display.contentCenterY + 150 )
physics.addBody( platformBottom, "static" )

local bomb = display.newImage( "assets/bombStroked.png", display.contentCenterX, display.contentCenterY )
physics.addBody( bomb, { shape={ -20,-10, 28,-10, 28,40, -20,40 } } )
bomb.isFixedRotation = true -- Prevent the bomb from spinning around its axis.

local instructions = display.newText( "Tap anywhere to Jump. Don't let the bomb get hit!", display.contentCenterX, 40, "assets/OpenSansRegular.ttf", 28 )
instructions:setFillColor( 1 )

local function shift() -- Shift the platforms up or down at random.
	local yTo = math.random( -150, 150 )
	transition.to( platformTop, { time=1000, y=display.contentCenterY-150+yTo } )
	transition.to( platformBottom, { time=1000, y=display.contentCenterY+150+yTo } )
end

local function jump( event )
	if event.phase == "began" then
		if not started then -- Starts the game if it hasn't started yet.
			started = true
			physics.start()
			shiftTimer = timer.performWithDelay( 750, shift, 0 )
			display.setDefault( "background", 0.3 ) -- Restore the background colour.
		end
		bomb:setLinearVelocity( 0, 0 )
		bomb:applyLinearImpulse( 0, -0.1 )
	end
end

local function collision( event ) -- If a collision begins, it means the game is over.
	if event.phase == "began" then
		display.setDefault( "background", 0.6, 0, 0 ) -- Make the background red to emphasise gameover.
		timer.cancel( shiftTimer )
		transition.cancel()
		physics.pause()
		timer.performWithDelay( 50, function()
			platformTop.y, platformBottom.y, bomb.y = display.contentCenterY-150, display.contentCenterY+150, display.contentCenterY
			started = false
		end )
	end
end

Runtime:addEventListener( "touch", jump )
Runtime:addEventListener( "collision", collision )