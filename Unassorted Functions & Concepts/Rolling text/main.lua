-- Create a standard Solar2D newText display object and reveal it character by character.
local function newRollingText( text, x, y, font, fontSize, revealTime )
	if type( text ) == "string" then
		local length = text:len()
		if length > 0 then
			local object = display.newText( "", x or 0, y or 0, font or native.systemFont, fontSize or 18 )
			object.anchorX, object.anchorY = 0, 0
			
			local time = revealTime and revealTime/length
			if time then
				local n = 1
				timer.performWithDelay( time, function()
					object.text = text:sub(1,n)
					n = n+1
				end, length )
			else
				object.text = text
			end
			return object
		end
	end
end

local sampleText = newRollingText( "Here's a cool rolling text sample:\n\nHello world!", 40, 80, native.systemFont, 24, 1200 )