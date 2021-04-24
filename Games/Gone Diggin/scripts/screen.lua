-- Calculate screen bounds.
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