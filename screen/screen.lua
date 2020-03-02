-- A simple table containing fully dynamic coordinate and related values for
-- displays of any size and aspect ratio to simplify creating and managing UI.

-- Boundary, size and coordinate values for standard rectangular displays.
local screen = {
	minX = display.screenOriginX,
	maxX = (display.contentWidth-display.actualContentWidth)*0.5+display.actualContentWidth,
	minY = display.screenOriginY,
	maxY = (display.contentHeight-display.actualContentHeight)*0.5+display.actualContentHeight,
	width = display.actualContentWidth,
	height = display.actualContentHeight,
	centreX = display.contentCenterX,
	centreY = display.contentCenterY,
	diagonal = math.sqrt( display.actualContentWidth^2+ display.actualContentHeight^2)
}

-- "Safe area" boundary and size values for displays with rounded corners.
screen.safe = {
	minX = display.safeScreenOriginX,
	maxX = (display.contentWidth-display.safeActualContentWidth)*0.5+display.safeActualContentWidth,
	minY = display.safeScreenOriginY,
	maxY = (display.contentHeight-display.safeActualContentHeight)*0.5+display.safeActualContentHeight,
	width = display.safeActualContentWidth,
	height = display.safeActualContentHeight,
	diagonal = math.sqrt( display.safeActualContentWidth^2+ display.safeActualContentHeight^2)
}

return screen
