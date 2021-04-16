local composer = require( "composer" )
local scene = composer.newScene()
local screen = require( "scripts.screen" )

----------------------------------------------------------------------------------------------------------------
-- NB! editor.lua is uses the Autotile module to create the initial map, which is to be copied to the wall table below.
-- and after that, you draw the floor. Then you need to copy the resulting level table over the same wall table.
----------------------------------------------------------------------------------------------------------------
-- If someone were to continue this project, they'd need to create a much better level editor.
----------------------------------------------------------------------------------------------------------------

local wall = {
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,32,40,40,40,7,0,0,0,0,0},
	{0,0,0,32,40,40,40,40,40,40,40,7,0,0,0,0,0,34,0,0,0,34,0,0,0,0,0},
	{0,0,0,34,0,0,0,0,0,0,0,34,0,0,0,0,0,34,0,0,0,34,0,0,0,0,0},
	{0,0,0,34,0,0,0,0,0,0,0,34,0,0,0,0,0,34,0,0,0,34,0,0,0,0,0},
	{0,0,0,34,0,0,2,40,47,0,0,34,0,0,0,0,0,43,47,0,2,33,0,0,0,0,0},
	{0,0,0,34,0,0,0,0,0,0,0,35,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,34,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,34,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,34,0,0,2,40,47,0,0,34,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,34,0,0,0,0,0,0,0,34,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,34,0,0,0,0,0,0,0,34,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,43,40,40,40,40,40,40,40,33,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
}

local groupTile = display.newGroup()
local tile, grid = {}, {}
local tileSize = 32
groupTile.x, groupTile.y = groupTile.x+2*tileSize, groupTile.y+2*tileSize

local addObjects = type(wall[1][1]) == "string"

local mode = "guard"

local function addTile( event )
    if event.phase == "ended" then
        local target = event.target
        local row = target.row
        local column = target.column
        if not addObjects and grid[row][column]:sub(1,4) ~= "wall" then
            grid[row][column] = "floor"
            target:setFillColor(0.4,0.2,0)
        elseif addObjects then
            grid[row][column] = mode
            if mode == "guard" then
                target:setFillColor(0.9,0.1,0.1)
            elseif mode == "remove" then
                target:setFillColor(0,0,0,0)
            end
        end
    end
end

local function printToConsole( event )
    if event.phase == "ended" then
        local s = "\v{\v"
        for row = 1, #grid do
            local t = {}
            for column = 1, #grid[row] do
                t[column] = "\""..grid[row][column].."\"" or "0"
            end
            if #t > 0 then
                s = s.."\t{"..table.concat(t, ",").."},\v"
            end
        end
        s = s.."},"
        print(s)
    end
    return true
end

function scene:create( event )
    local sceneGroup = self.view
    
    local bg = display.newRect( sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
    bg:setFillColor( 0.1, 0.7, 0.2 )
    
    for row = 1, 16 do
        tile[row], grid[row] = {}, {}
        for column = 1, 26 do
            tile[row][column] = display.newRect( groupTile, tileSize*(column-1), tileSize*(row-1), tileSize, tileSize )
            tile[row][column].row, tile[row][column].column = row, column
            tile[row][column].anchorX, tile[row][column].anchorY = 0, 0
            tile[row][column].isHitTestable = true
            tile[row][column].strokeWidth = 1
            tile[row][column]:setStrokeColor( 0 )
            tile[row][column]:addEventListener( "touch", addTile )
            local val = wall[row][column]
            local isNumber = tonumber( val ) and val
            if (isNumber and val ~= 0) or (not isNumber and val ~= "empty") then
                if isNumber or val ~= "floor" then
                    tile[row][column]:setFillColor(0.3,0.3,0.8)
                else
                    tile[row][column]:setFillColor(0.4,0.2,0)
                end
                grid[row][column] = isNumber and "wall_"..val or val
            else
                tile[row][column]:setFillColor(0,0,0,0)
                grid[row][column] = "empty"
            end
        end
    end

    local buttonPrint = display.newRect( 24, 24, 40, 40 )
    buttonPrint:setFillColor( 0.8, 0.7, 0 )
    buttonPrint:addEventListener( "touch", printToConsole )

    sceneGroup:insert( groupTile )
end


scene:addEventListener( "create", scene )

return scene