-- Create a convenient audio button that will be visible in all scenes.

local button = {}

---------------------------------------------------------------

local screen = require("classes.screen")
local loadsave = require("classes.loadsave")

local savedata = loadsave.load("data.json")
local audioOn

local audioButtonCreated = false

if not savedata then
	loadsave.save( { audio = true }, "data.json" )
	audioOn = true
else
	audioOn = savedata.audio
end

---------------------------------------------------------------

function button.create()
	if not audioButtonCreated then
		audioButtonCreated = true

		local audioButton = display.newRect( screen.maxX - 10, screen.minY + 10, 48, 48 )
		audioButton.anchorX, audioButton.anchorY = 1, 0

		audioButton.fillOn = {
			type = "image",
			filename = "assets/images/other/notegreen.png"
		}
		audioButton.fillOff = {
			type = "image",
			filename = "assets/images/other/notered.png"
		}

		if audioOn then
			audioButton.fill = audioButton.fillOn
			audio.setVolume( _G.masterVolume )
			audio.setVolume( _G.bgmVolume, { channel=1 } )
		else
			audioButton.fill = audioButton.fillOff
			audio.setVolume( 0 )
		end

		audioButton:addEventListener( "touch", function( event )
			if event.phase == "ended" then
				audioOn = not audioOn
				loadsave.save( { audio = audioOn }, "data.json" )

				if audioOn then
					audioButton.fill = audioButton.fillOn
					audio.setVolume( _G.masterVolume )
					audio.setVolume( _G.bgmVolume, { channel=1 } )
				else
					audioButton.fill = audioButton.fillOff
					audio.setVolume( 0 )
				end
			end
			return true
		end )

	end
end

---------------------------------------------------------------

return button