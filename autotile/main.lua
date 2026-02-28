display.setStatusBar( display.HiddenStatusBar )
display.setDefault( "minTextureFilter", "nearest" )
display.setDefault( "magTextureFilter", "nearest" )

-------------------------------------------------------------------

-- Tilemap properties:
local rowCount = 19
local columnCount = 19
local tileSize = 32
local useDebugTilemap = false

-------------------------------------------------------------------
-- Load autotile and set up tilesheets.
-------------------------------------------------------------------

local autotile = require( "spyric.autotile" )

local sheet4bit = graphics.newImageSheet( "images/4_directions" .. (useDebugTilemap and "_debug" or "") .. ".png", {
    width = tileSize,
    height = tileSize,
    numFrames = 16
} )

local sheet8bit = graphics.newImageSheet( "images/8_directions" .. (useDebugTilemap and "_debug" or "") .. ".png", {
    width = tileSize,
    height = tileSize,
    numFrames = 49
} )

-------------------------------------------------------------------
-- Prepare the display group and the tilemap data structures.
-------------------------------------------------------------------

local groupTile = display.newGroup()
local map, sensor = {}, {}

for row = 1, rowCount do
	map[row], sensor[row] = {}, {}

	for column = 1, columnCount do
		map[row][column] = 0
	end
end

-------------------------------------------------------------------
-- Functions for adding tiles and for handling sensor touch events.
-------------------------------------------------------------------

local directions, sheet = 8, sheet8bit
local mode = "add"
local prevSensor = nil

local function addTile( row, column, overwrite )
	local frame, bitmask = autotile.getFrameID( map, row, column, directions )

	local thisSensor = sensor[row][column]

	-- Prevent surrounding tiles from being updated unless their bitmask values change.
	if overwrite or bitmask ~= thisSensor.bitmask then
		map[row][column] = frame

		if thisSensor.tile then
			display.remove( thisSensor.tile )
		end

		thisSensor.tile = display.newImage( groupTile, sheet, frame, thisSensor.x, thisSensor.y )
		thisSensor.frame = frame
		thisSensor.bitmask = bitmask
	end
end

-- Handle touches to the tilemap's sensors.
local function sensorEvent( event )
	local target = event.target

	if event.phase == "ended" then
		target.touched = false
		prevSensor = nil

	else
		-- Prevent "moved" phase from trying to add a new tile at every move.
		if prevSensor and prevSensor ~= target then
			prevSensor.touched = false
		end

		if not target.touched then
			local row, column = target.row, target.column
			target.touched = true

			if mode == "add" then
				addTile( row, column, true )

			elseif mode == "remove" then
				if target.tile then
					display.remove( sensor[row][column].tile )
					sensor[row][column].tile = nil
                    sensor[row][column].frame = nil
                    sensor[row][column].bitmask = nil
					map[row][column] = 0
				end
			end

			-- Loop through and update the adjacent cells while ignoring the pressed center cell.
			for rowToCheck = row-1, row+1 do
				for columnToCheck = column-1, column+1 do

					-- Ignore the cell where the tile is being added.
					if rowToCheck ~= row or columnToCheck ~= column then
						-- Ensure the adjacent cells exist and have a non-zero value.
						local cellValue = map[rowToCheck] and map[rowToCheck][columnToCheck]

						if cellValue and cellValue ~= 0 then
							addTile( rowToCheck, columnToCheck, false )
						end
					end
				end
			end
		end

		prevSensor = target
	end
	return true
end

-------------------------------------------------------------------
-- Create touch sensors for adding and removing tiles.
-------------------------------------------------------------------

for row = 1, rowCount do
	for column = 1, columnCount do

		local x = tileSize*column
		local y = tileSize*row

		local newSensor = display.newRect( groupTile, x, y, tileSize, tileSize )
		newSensor:toBack()

		-- Alternate the sensors' colours to make recognising tile changes easy.
		if (row + column) % 2 == 0 then
			newSensor:setFillColor( 0.27, 0.6, 0.78 )
		else
			newSensor:setFillColor( 0.17, 0.5, 0.68 )
		end

		newSensor.row = row
		newSensor.column = column
		newSensor.touched = false
		newSensor:addEventListener( "touch", sensorEvent )

		sensor[row][column] = newSensor
    end
end

groupTile.x = display.contentCenterX - groupTile.width*0.5 - tileSize*0.5
groupTile.y = display.contentCenterY - groupTile.height*0.5 - tileSize*0.5

-------------------------------------------------------------------
-- Simple UI & functions for toggling different modes.
-------------------------------------------------------------------

local labelSwitch, buttonAdd, selected

-- timerSelect is used to time a print button pressing effect.
local timerSelect

-- Switch between "add" and "remove" modes.
local function switchMode( event )
    if event.phase == "ended" then
		if timerSelect then
			timer.cancel( timerSelect )
			timerSelect = nil
		end

		selected.y = event.target.y
		selected.yPrev = selected.y
		mode = event.target.id
	end
	return true
end

-- Switch tilemap styles and print to console (on simulator).
local function systemEvent( event )
    if event.phase == "ended" then
        local target = event.target
        local id = target.id

        ---------------------------------------

        -- Update the selected effect's position for a moment.
        if timerSelect then
            timer.cancel( timerSelect )
            timerSelect = nil
        end

        selected.y = event.target.y

        timer.performWithDelay( 50, function()
            selected.y = selected.yPrev
        end )

        ---------------------------------------

        -- Switch between 4-bit and 8-bit tilemaps.
        if id == "switch" then
            if directions == 4 then
                directions, sheet = 8, sheet8bit
                labelSwitch.text = "Using:\n8-bit map"

            else
                directions, sheet = 4, sheet4bit
                labelSwitch.text = "Using:\n4-bit map"

            end

            -- Wipe the entire map after switching:
            for row = 1, rowCount do
                for column = 1, columnCount do
                    display.remove( sensor[row][column].tile )
                    sensor[row][column].tile = nil
                    sensor[row][column].frame = nil
                    sensor[row][column].bitmask = nil
                    map[row][column] = 0
                end
            end

            -- Reset to "add" mode.
            selected.yPrev = buttonAdd.y
            mode = "add"

        -- Output the current map to console.
        elseif id == "export" then

            local s = "\v{\v"

            for row = 1, #map do
                local t = {}
                for column = 1, #map[row] do
                    t[column] = map[row][column] or 0
                end

                if #t > 0 then
                    s = s.."\t{"..table.concat(t, ",").."},\v"
                end
            end

            s = s.."},"
            print(s)
        end
    end
    return true
end

-------------------------------------------------------------------

labelSwitch = display.newText({
    text = "Using:\n8-bit map",
    x = 140,
    y = 20,
    font = "font/adventpro-bold.ttf",
    fontSize = 30,
    align = "right"
})
labelSwitch:setFillColor( 0.2, 0.5, 0.9 )
labelSwitch.anchorX, labelSwitch.anchorY = 1, 0

local buttonSwitch = display.newRect( labelSwitch.x - 30, labelSwitch.y + labelSwitch.height + 40, 48, 48 )
buttonSwitch:setFillColor( 0.2, 0.5, 0.9 )
buttonSwitch.id = "switch"
buttonSwitch:addEventListener( "touch", systemEvent )

local labelAdd = display.newText( "Add", labelSwitch.x, buttonSwitch.y + 60, "font/adventpro-bold.ttf", 30 )
labelAdd:setFillColor( 0, 0.7, 0 )
labelAdd.anchorX, labelAdd.anchorY = 1, 0

buttonAdd = display.newRect( labelAdd.x - 30, labelAdd.y + labelAdd.height + 40, 48, 48 )
buttonAdd:setFillColor( 0, 0.7, 0 )
buttonAdd.id = "add"
buttonAdd:addEventListener( "touch", switchMode )

local labelRemove = display.newText( "Remove", labelAdd.x, buttonAdd.y + 60, "font/adventpro-bold.ttf", 30 )
labelRemove:setFillColor( 0.7, 0, 0 )
labelRemove.anchorX, labelRemove.anchorY = 1, 0

local buttonRemove = display.newRect( buttonAdd.x, labelRemove.y + labelRemove.height + 40, 48, 48 )
buttonRemove:setFillColor( 0.7, 0, 0 )
buttonRemove.id = "remove"
buttonRemove:addEventListener( "touch", switchMode )

-- Show which button is selected.
selected = display.newRect( buttonAdd.x, buttonAdd.y, 56, 56 )
selected.yPrev = selected.y
selected:toBack()

local labelExport = display.newText( "Export to\nconsole", labelAdd.x, buttonRemove.y + 60, "font/adventpro-bold.ttf", 30 )
labelExport:setFillColor( 0.8, 0.7, 0 )
labelExport.anchorX, labelExport.anchorY = 1, 0

-------------------------------------------------------------------

-- Add a disclaimer about the print button for non-simulator builds instead of the button.
if system.getInfo( "environment" ) ~= "simulator" then

	labelExport.text = labelExport.text .. "*"

	local simOnly = display.newText( "(*simulator only)", labelAdd.x + 12, labelExport.y + labelExport.height + 10, "font/adventpro-bold.ttf", 20 )
	simOnly.anchorX, simOnly.anchorY = 1, 0

else

	local buttonExport = display.newRect( buttonAdd.x, labelExport.y + labelExport.height + 40, 48, 48 )
	buttonExport:setFillColor( 0.8, 0.7, 0 )
    buttonExport.id = "export"
	buttonExport:addEventListener( "touch", systemEvent )

end
