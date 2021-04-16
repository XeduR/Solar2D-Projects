local screen = {
	xMin = display.screenOriginX,
	xMax = display.contentWidth - display.screenOriginX,
	yMin = display.screenOriginY,
	yMax = display.contentHeight - display.screenOriginY,
	width = display.actualContentWidth,
	height = display.actualContentHeight,
	xCenter = display.contentCenterX,
	yCenter = display.contentCenterY,
}

return screen