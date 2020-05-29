local t = {}
t["electric dance llc"] = { name = "Electric Dance LLC", id = 1 }
t["electrics supreme"] = { name = "Electrics Supreme Inc.", id = 2 }
t["electronics n' stuff"] = { name = "Electronics n' Stuff", id = 3 }
t["elections for all"] = { name = "Elections for All", id = 4 }

local defaultField = native.newTextField( display.contentCenterX, display.contentCenterY, display.actualContentWidth*0.5, 64 )
local topResult = display.newText( "", display.contentCenterX, display.contentCenterY+80, native.systemFont, 32 )

local _lower = string.lower
local _len = string.len

-- See if the text input matches any of the entries in the list.
local function textListener( event )
	if ( event.phase == "editing" ) then
		local input = _lower( event.text )
		local matchFound = false
		-- print( "\n----------------\npossible matches:" )
		for i, j in pairs( t ) do
			if i:sub( 1, _len(input) ) == input then
				topResult.text = "\"" .. j.name .. "\"" .. " - id = " .. j.id
				-- print( "\"" .. j.name .. "\"" .. " - id = " .. j.id )
				matchFound = true
				break
			end
		end
		if not matchFound then
			topResult.text = ""
			-- print( "0 matches found" )
		elseif _len(input) == 0 then
			topResult.text = ""
		end
	end
end

defaultField:addEventListener( "userInput", textListener )