-- A simple table containing fully dynamic coordinate and related values for
-- displays of any size and aspect ratio to simplify creating and managing UI.

-- Boundary, size and coordinate values for standard rectangular displays.
local screen = {
	minX = display.screenOriginX,
	maxX = display.contentWidth - display.screenOriginX,
	minY = display.screenOriginY,
	maxY = display.contentHeight - display.screenOriginY,
	width = display.actualContentWidth,
	height = display.actualContentHeight,
	centreX = display.contentCenterX,
	centreY = display.contentCenterY,
	diagonal = math.sqrt( display.actualContentWidth^2+ display.actualContentHeight^2)
}

return screen
