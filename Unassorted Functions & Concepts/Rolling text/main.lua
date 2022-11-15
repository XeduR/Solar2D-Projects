-- Create a standard Solar2D newText display object and reveal it character by character or word by word.
local function newRollingText( params )
	if type( params ) ~= "table" then
        print( "WARNING: bad argument #1 to 'newRollingText' (table expected, got nil)" )
    else
        local text = params.text or ""
        local x = params.x or 0
        local y = params.y or 0
        local font = params.font or native.systemFont
        local fontSize = params.fontSize or 18
        local reveal = params.reveal or "word"
        local length, word

        -- NB! With "word by word" separation, all hidden special characters,
        -- like line breaks, will be missed/ignored.
        if reveal == "word" then
            word = {}
            -- Split the string into words.
            for w in text:gmatch("%S+") do
                word[#word+1] = w
            end
            length = #word
        else
            length = text:len()
        end

		if length > 0 then
			local object = display.newText( "", x or 0, y or 0, font or native.systemFont, fontSize or 18 )
			object.anchorX, object.anchorY = 0, 0

            local time = (params.time or 1000)/length
			if time then
				local n = 1
				timer.performWithDelay( time, function()
                    if word then
                        object.text = object.text .. " " .. word[n]
                    else
                        object.text = text:sub(1,n)
                    end
					n = n+1
				end, length )
			else
				object.text = text
			end
			return object
		end
	end
end

local sampleText = newRollingText({
    text = "Here's a cool rolling text sample:\n\nHello world!",
    x = 40,
    y = 80,
    font = native.systemFont,
    fontSize = 24,
    reveal = "character",
    time = 1200
})