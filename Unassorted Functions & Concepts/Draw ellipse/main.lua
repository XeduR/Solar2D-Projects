local tempShape
local r,g,b

local function drawEllipse( xStart, yStart, x, y, isFinal )
	local width = xStart-x
	local height = yStart-y
	display.remove( tempShape )
	tempShape = nil
	local anchorX, anchorY = 1, 1
	-- Negative width or height means the anchor needs to be flipped.
	if width < 0 then
		anchorX = 0
		width = -width
	end
	if height < 0 then
		anchorY = 0
		height = -height
	end
	
	local maxDistance = math.max( width, height )
	local xScale = width/maxDistance
	local yScale = height/maxDistance
	
	if xScale ~= 0 and yScale ~= 0 then -- If either scale is 0, then the object is invalid.
		local ellipse = display.newCircle( xStart, yStart, maxDistance*0.5 )
		ellipse.anchorX, ellipse.anchorY = anchorX, anchorY
		ellipse.xScale, ellipse.yScale = xScale, yScale
		ellipse:setFillColor( r, g, b )

		-- If the touchListener event hasn't ended, then it's just a temporary ellipse.
		if isFinal then
			return ellipse
		else
			tempShape = ellipse
		end
	end
end

local function touchListener( event )
	local phase = event.phase
	if phase == "began" then
		-- Randomly set the colour of every new ellipse to make them easier to see.
		r, g, b = math.random(), math.random(), math.random()
	else
		drawEllipse( event.xStart, event.yStart, event.x, event.y, phase == "ended" )
	end
	return true
end

Runtime:addEventListener( "touch", touchListener )