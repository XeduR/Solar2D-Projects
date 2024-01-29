local list = {{}}
local iteration = 1
local color = { math.random(), math.random(), math.random() }

local mouseEventBegan = false
local dontAddDot = false

-- Draw a boundary for the level by adding dots.
Runtime:addEventListener( "mouse", function( event )
	if event.type == "down" and not mouseEventBegan and not dontAddDot then
		if event.isPrimaryButtonDown or event.isSecondaryButtonDown or event.isMiddleButtonDown then
			mouseEventBegan = true

			local circle = display.newCircle( event.x, event.y, 10 )
			circle:setFillColor( color[1], color[2], color[3] )

			list[iteration][#list[iteration] + 1] = circle

			-- Create a connecting line between the two last dots.
			if #list[iteration] > 1 then
				circle.connector = display.newLine( list[iteration][#list[iteration] - 1].x, list[iteration][#list[iteration] - 1].y, circle.x, circle.y )
			end

			-- Create a connecting line between the first and last dot.
			if #list[iteration] > 2 then
				display.remove( list[iteration][1].connector )
				list[iteration][1].connector = display.newLine( list[iteration][1].x, list[iteration][1].y, circle.x, circle.y )
			end

			for i = 1, #list[iteration] do
				list[iteration][i]:toFront()
			end
		end

	elseif event.type == "up" and mouseEventBegan then
		mouseEventBegan = false

	end
end )



Runtime:addEventListener( "key", function( event )
	if event.phase == "down" then
		-- print( event.keyName )

		-- Output the boundaries to the console.
		if event.keyName == "space" then
			local output = "local boundary = {\v"

			for i = 1, #list do
				output = output .. "\t{"

				for j = 1, #list[i] do
					output = output .. " " .. list[i][j].x .. ", " .. list[i][j].y .. ","
				end

				output = output:sub( 1, -2 ) .. " },\v"
				output = output .. ""
			end
			output = output .. "}\v\v"
			print( output )

		-- Remove the last boundary.
		elseif event.keyName == "deleteBack" or event.keyName == "deleteForward" then
			if #list[iteration] > 0 then
				list[iteration][#list[iteration]]:removeSelf()
				list[iteration][#list[iteration]] = nil
			end

		elseif event.keyName == "q" then
			dontAddDot = true

		else
			-- Start a new boundary.
			if #list[iteration] > 0 then
				iteration = iteration + 1
				list[iteration] = {}
				color = { math.random(), math.random(), math.random() }
			end

		end
	elseif event.phase == "up" then
		if event.keyName == "q" then
			dontAddDot = false
		end
	end
end )
