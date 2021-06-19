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

local sfx = {}

local sound = true

function sfx.setup( theme )
	for i = 1, 6 do
		sfx[i] = audio.loadSound( "sfx/tap" .. i .. ".wav" )
	end

	audio.setVolume( 1 )
	audio.reserveChannels( 1 )
end

function sfx.play()
	if sound then
		audio.play( sfx[math.random(1,6)] )
	end
end

function sfx.toggle()
	sound = not sound
	return sound
end

return sfx
