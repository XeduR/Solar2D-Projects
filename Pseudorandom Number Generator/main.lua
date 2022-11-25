-------------------------------------------------------------------------
--                                                                     --
--    ooooooo  ooooo                 .o8              ooooooooo.       --
--     `8888    d8'                 "888              `888   `Y88.     --
--       Y888..8P     .ooooo.   .oooo888  oooo  oooo   888   .d88'     --
--        `8888'     d88' `88b d88' `888  `888  `888   888ooo88P'      --
--       .8PY888.    888ooo888 888   888   888   888   888`88b.        --
--      d8'  `888b   888    .o 888   888   888   888   888  `88b.      --
--    o888o  o88888o `Y8bod8P' `Y8bod88P"  `V88V"V8P' o888o  o888o     --
--                                                                     --
--  © 2022 Eetu Rantanen                Last Updated: 25 November 2022 --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------
-- This sample project is written for Solar2D, but the rng module itself
-- is written in pure Lua and doesn't require Solar2D to run.

-- There is also an interactive online tool with further info at:
-- https://www.xedur.com/demos/Pseudorandom%20Number%20Generator/
------------------------------------------------------------------------

display.setStatusBar( display.HiddenStatusBar )

local rng = require("rng")

------------------------------------------------------------------------
-- You can edit these values to change the grid size and random generation:

-- local randomseed = os.time() -- Use a dynamic randomseed
local randomseed = 5125161 -- Set a hardcoded randomseed

local desiredGridSize = 200 -- width and height in pixels.
local borderPadding = 20

------------------------------------------------------------------------

-- Localise functions.
local random = rng.random
local newRect = display.newRect

-- Cap the grid size so that it fits inside the screen with the appropriate border padding.
local gridSize = math.min(
	desiredGridSize,
	display.actualContentWidth-borderPadding*2,
	display.actualContentHeight-borderPadding*2
)
local xStart = math.floor(display.contentCenterX-gridSize*0.5)
local yStart = math.floor(display.contentCenterY-gridSize*0.5)
rng.randomseed( randomseed )

------------------------------------------------------------------------

-- Draw the grid.
local currentRow = 0
local function drawRow()
	for _ = 1, 10 do
		currentRow = currentRow+1
		for column = 1, gridSize do
			local dot = newRect( xStart+column, yStart+currentRow, 1, 1 )
			dot.anchorX, dot.anchorY = 0, 0
			dot:setFillColor( random() )
		end
	end
	if currentRow < gridSize then
		timer.performWithDelay( 1, drawRow )
	end
end
drawRow()

------------------------------------------------------------------------

-- Create UI texts.
local yMax = display.actualContentHeight - display.screenOriginY

local title = display.newText({
	text = "randomseed = " .. randomseed,
	x = display.contentCenterX,
	y = display.screenOriginY + yStart*0.5,
	font = native.systemFont,
	fontSize = 20
})

local dotCount = display.newText({
	text = "Number of random dots: " .. gridSize*gridSize,
	x = display.contentCenterX,
	y = yStart + gridSize + (yMax - (yStart + gridSize))*0.5,
	font = native.systemFont,
	fontSize = 20
})
