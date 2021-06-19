--[[
	"Get A Job, Baby!" is a game written by Eetu Rantanen for Ludum Dare 45

	Copyright (C) 2019 - Spyric Entertainment

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--

-- local composer = require( "composer" )
local settings = require( "data.settings" )
local sfx = require( "scripts.sfx" )

local mod = {}

local function ease( a, b, c, d ) return c+d*(((1-a/b)^2)-((1-a/b)^40))*1.23 end
local function reset( t ) t.xScale, t.yScale = 1, 1; t.canTouch=true end

function mod.add( group, x, y, width, height, whichEvent, dialogueFunction )
	local character = display.newRect( group, x, y, width, height )
	character:setFillColor( unpack( settings.colours.a ) )
	character.anchorY = 1

	if whichEvent then
		if whichEvent > #GLOBAL_FIX.gameModes then
			character.isTrap = true
			character.target = GLOBAL_FIX.traps[whichEvent-#GLOBAL_FIX.gameModes]
		else
			character.target = GLOBAL_FIX.gameModes[whichEvent]
		end

		character.canTouch = true
		function character:touch( event )
			if event.phase == "began" and event.target.canTouch then
				event.target.canTouch = false
				sfx.play()
				dialogueFunction( event )
				transition.to( self, { time=300, xScale=1.2, yScale=1.2, transition=ease, onComplete=reset })
			end
			return true
		end
		character:addEventListener( "touch" )
	end

	function character:bounce()
		local exclamation = display.newText( "!", self.x, self.y - self.height - 10, "fonts/Roboto-Black.ttf", 64 )
		exclamation:setFillColor( unpack( settings.colours.b ) )
		exclamation.anchorY = 1

		transition.to( self, { time=300, xScale=1.2, yScale=1.2, transition=ease, onComplete=reset })
		transition.to( exclamation, { time=500, alpha=0, y=exclamation.y-4, onComplete=function() display.remove( exclamation ) exclamation = nil end })
	end

	return character
end

return mod
