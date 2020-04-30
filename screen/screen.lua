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

-- "Safe area" boundary and size values for displays with rounded corners.
local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

screen.safe = {
	minX = display.safeScreenOriginX,
	maxX = display.actualContentWidth - ( leftInset + rightInset ),
	minY = display.safeScreenOriginY,
	maxY = display.actualContentHeight - ( topInset + bottomInset ),
	width = display.safeActualContentWidth,
	height = display.safeActualContentHeight,
	diagonal = math.sqrt( display.safeActualContentWidth^2+ display.safeActualContentHeight^2)
}
screen.safe.centreX = (screen.safe.minX + screen.safe.maxX)*0.5
screen.safe.centreY = (screen.safe.minY + screen.safe.maxY)*0.5

-- Yankee proofing the table:
screen.centerX = screen.centreX
screen.centerY = screen.centreY
screen.safe.centerX = screen.safe.centreX
screen.safe.centerY = screen.safe.centreY

return screen
