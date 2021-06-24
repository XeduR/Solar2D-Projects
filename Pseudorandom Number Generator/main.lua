local rng = require("rng")

-- This sample project is written for Solar2D, but the rng module itself is written in pure Lua and doesn't require Solar2D to run.

-- There is also an interactive online tool with further info at: https://www.xedur.com/demos/Pseudorandom%20Number%20Generator/

------------------------------------------------------------------------------------------------------------------------------------

-- You can edit these values to change the grid size and random generation:
local randomseed = 51251612123456
local borderPadding = 20
local desiredGridSize = 500

------------------------------------------------------------------------------------------------------------------------------------

-- Localise functions.
local random = rng.random
local newRect = display.newRect

-- Cap the grid size so that it fits inside the screen with the appropriate border padding.
local gridSize = math.min( desiredGridSize, display.actualContentWidth-borderPadding*2, display.actualContentHeight-borderPadding*2 )
local xStart = math.floor(display.contentCenterX-gridSize*0.5)
local yStart = math.floor(display.contentCenterY-gridSize*0.5)
rng.randomseed( randomseed )

------------------------------------------------------------------------------------------------------------------------------------

-- Draw the grid.
local currentRow = 0
local function drawRow()
    for i = 1, 10 do
        currentRow = currentRow+1
        for column = 1, gridSize do 
            local dot = newRect( xStart+column, yStart+currentRow, 1, 1 )
            dot.anchorX, dot.anchorY = 0, 0
            dot:setFillColor( random() )
        end
    end
    if currentRow < gridSize then
        timer.performWithDelay( 5, drawRow )
    end
end
drawRow()

------------------------------------------------------------------------------------------------------------------------------------

-- Create UI texts.
local yMax = display.actualContentHeight - display.screenOriginY
local title = display.newText( "randomseed = " .. randomseed, display.contentCenterX, display.screenOriginY + yStart*0.5, native.systemFont, 20 )
local dotCount = display.newText( "Number of random dots: " .. gridSize*gridSize, display.contentCenterX, yStart + gridSize + (yMax - (yStart + gridSize))*0.5, native.systemFont, 20 )
