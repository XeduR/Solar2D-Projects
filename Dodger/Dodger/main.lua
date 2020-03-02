display.setStatusBar( display.HiddenStatusBar )
display.setDefault( "fillColor", 0.7, 0.1, 0.1 )
display.setDefault( "background", 0.3 )
local physics = require("physics")
local shiftTimer, started
physics.start()
physics.pause()

local platformTop = display.newRect( display.contentCenterX, display.contentCenterY - 120, display.actualContentWidth, 60 )
physics.addBody( platformTop, "static" )
local platformBottom = display.newRect( display.contentCenterX, display.contentCenterY + 120, display.actualContentWidth, 60 )
physics.addBody( platformBottom, "static" )
local player = display.newCircle( display.contentCenterX, display.contentCenterY, 20 )
physics.addBody( player, {radius=20} )
player:setFillColor( 0.1, 0.7, 0.1 )
local text = display.newText( "Tap to Jump. Don't get hit!", display.contentCenterX, display.contentCenterY + 180, "assets/adventpro-bold.ttf", 28 )
text:setFillColor( 1 )

local function shift()
	local yTo = math.random( -100, 100 )
	transition.to( platformTop, { time=700, y=display.contentCenterY-120+yTo } )
	transition.to( platformBottom, { time=700, y=display.contentCenterY+120+yTo } )
end

local function jump( event )
	if event.phase == "began" then
		if not started then
			physics.start()
			started = true
			shiftTimer = timer.performWithDelay( 750, shift, 0 )
		end
		player:setLinearVelocity( 0, 0 )
		player:applyLinearImpulse( 0, -0.05 )
	end
end

local function collision( event )
	if event.phase == "began" then
		timer.cancel( shiftTimer )
		transition.cancel()
		physics.pause()
		timer.performWithDelay( 50, function()
			platformTop.y, platformBottom.y, player.y = display.contentCenterY - 120, display.contentCenterY + 120, display.contentCenterY
			started = false
		end )
	end
end

Runtime:addEventListener( "touch", jump )
Runtime:addEventListener( "collision", collision )
