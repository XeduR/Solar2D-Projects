local screen = {}
screen.safe = {}

local isMonitoringOrientation = false
local isMonitoringResize = false

local type = type

-- Update the screen coordinates table on orientation/resize events.
local function update()
	screen.minX = display.screenOriginX
	screen.maxX = display.contentWidth - display.screenOriginX
	screen.minY = display.screenOriginY
	screen.maxY = display.contentHeight - display.screenOriginY
	screen.width = display.actualContentWidth
	screen.height = display.actualContentHeight
	screen.centerX = display.contentCenterX
	screen.centerY = display.contentCenterY
	screen.diagonal = math.sqrt( display.actualContentWidth^2+ display.actualContentHeight^2)
	
	-- TODO: check the equations and add safe area entries
	-- local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()
	-- screen.safe.minX = display.safeScreenOriginX
	-- screen.safe.maxX = display.actualContentWidth - ( leftInset + rightInset )
	-- screen.safe.minY = display.safeScreenOriginY
	-- screen.safe.maxY = display.actualContentHeight - ( topInset + bottomInset )
	-- screen.safe.width = display.safeActualContentWidth
	-- screen.safe.height = display.safeActualContentHeight
	-- screen.safe.diagonal = math.sqrt( display.safeActualContentWidth^2+ display.safeActualContentHeight^2)
	-- screen.safe.centerX = (screen.safe.minX + screen.safe.maxX)*0.5
	-- screen.safe.centerY = (screen.safe.minY + screen.safe.maxY)*0.5
end
update()

-- Start or stop automatic monitoring for resize events.
function screen.monitorResize( state )
	if type( state ) == "boolean" then
		if state and not isMonitoringResize then
			isMonitoringResize = true
			Runtime:addEventListener( "resize", update )
		elseif not state and isMonitoringResize then
			isMonitoringResize = false
			Runtime:removeEventListener( "resize", update )
		end
	end
end

-- Start or stop automatic monitoring for orientation events.
function screen.monitorOrientation( state )
	if type( state ) == "boolean" then
		if state and not isMonitoringOrientation then
			isMonitoringOrientation = true
			Runtime:addEventListener( "orientation", update )
		elseif not state and isMonitoringOrientation then
			isMonitoringOrientation = false
			Runtime:removeEventListener( "orientation", update )
		end
	end
end

function screen.update()
	update()
end

return screen
