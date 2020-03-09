display.setStatusBar( display.HiddenStatusBar )
local tileLoader = require( "spyric.autotile" )

local map, sensor = {}, {}
local maxRows = 18
local maxColumns = 20
local sensorSize = 32 -- Same as frame size.
local mode = "add"
local prevSensor

tileLoader.init( map, maxRows, maxColumns )

local options = {
    width = 32,
    height = 32,
    numFrames = 49
}

local sheet = graphics.newImageSheet( "tilemapLayout.png", options )

local tileGroup = display.newGroup()


local function addTile( r, c, overwrite )
    local frame, bitmask = tileLoader.getFrameID( r, c, sensor[r][c].frame )
    -- Prevent surrounding tiles from being updated unless the tiles' bitmasks change.
    if overwrite or bitmask ~= sensor[r][c].bitmask then
        map[r][c] = frame

        if sensor[r][c].tile then
            display.remove( sensor[r][c].tile )
        end
        sensor[r][c].tile = display.newImage( tileGroup, sheet, frame, sensor[r][c].x, sensor[r][c].y )
        sensor[r][c].frame = frame
        sensor[r][c].bitmask = bitmask
    end
end


local function sensorEvent( event )
    if event.phase == "ended" then
        event.target.touched = false
        prevSensor = nil
    else
        if prevSensor and prevSensor ~= event.target then
            prevSensor.touched = false
        end

        if not event.target.touched then
            local r, c = event.target.row, event.target.column
            event.target.touched = true

            if mode == "add" then
                addTile( r, c, true )
            else
                if event.target.tile then
                    display.remove( sensor[r][c].tile )
                    sensor[r][c].tile = nil
                    map[r][c] = 0
                end
            end

            -- Update the surrounding tiles.
            for i = r-1, r+1 do
                for j = c-1, c+1 do
                    if map[i][j] ~= 0 and (i ~= r or j ~= c) then
                        addTile( i, j, false )
                    end
                end
            end
        end
        prevSensor = event.target
    end
    return true
end

----------------------------------------------------------------
-- Start from 0 and add to rows/columns+1 to create "empty tile borders".
for i = 0, maxRows+1 do
    map[i] = {}
    sensor[i] = {}
    for j = 0, maxColumns+1 do
        map[i][j] = 0
        if i > 0 and i <= maxRows and j > 0 and j <= maxColumns then
            sensor[i][j] = display.newRect( tileGroup, sensorSize*j, sensorSize*i, sensorSize, sensorSize )
            sensor[i][j]:setFillColor( 0.27, 0.6, 0.78 )
            sensor[i][j].strokeWidth = 1
            sensor[i][j]:setStrokeColor( 0.2, 0.2 )
            sensor[i][j].row = i
            sensor[i][j].column = j
            sensor[i][j].touched = false
            sensor[i][j]:addEventListener( "touch", sensorEvent )
        end
    end
end

tileGroup.x = tileGroup.x + (display.contentCenterX - tileGroup.width*0.5) - sensorSize*0.5
tileGroup.y = tileGroup.y + (display.contentCenterY - tileGroup.height*0.5) - sensorSize*0.5

----------------------------------------------------------------
-- Simple UI for toggling between adding and removing tiles.

local selected = display.newRect( 110, 70, 56, 56 )

local function updateMode( event )
    if event.phase == "ended" then
        mode = event.target.id
        selected.y = event.target.y
    end
end

local labelAdd = display.newText( "Add", 140, 50, "font/adventpro-bold.ttf", 30 )
labelAdd:setFillColor( 0, 0.7, 0 )
labelAdd.anchorX = 1

local buttonAdd = display.newRect( 110, labelAdd.y + labelAdd.height + 20, 48, 48 )
buttonAdd:setFillColor( 0, 0.7, 0 )
buttonAdd.id = "add"
buttonAdd:addEventListener( "touch", updateMode )

local labelRemove = display.newText( "Remove", 140, 160, "font/adventpro-bold.ttf", 30 )
labelRemove:setFillColor( 0.7, 0, 0 )
labelRemove.anchorX = 1

local buttonRemove = display.newRect( 110, labelRemove.y + labelRemove.height + 20, 48, 48 )
buttonRemove:setFillColor( 0.7, 0, 0 )
buttonRemove.id = "remove"
buttonRemove:addEventListener( "touch", updateMode )

selected.y = buttonAdd.y
