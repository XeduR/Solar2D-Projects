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

-- a simple table containing any and all possible coordinate values
local screen = {
	minX = display.screenOriginX,
	maxX = (display.contentWidth-display.actualContentWidth)*0.5+display.actualContentWidth,
	minY = display.screenOriginY,
	maxY = (display.contentHeight-display.actualContentHeight)*0.5+display.actualContentHeight,
	width = display.actualContentWidth,
	height = display.actualContentHeight,
	centreX = display.contentCenterX,
	centreY = display.contentCenterY,
	diagonal = math.sqrt( display.actualContentWidth^2+ display.actualContentHeight^2)
}

-- safe screen coordinate values
screen.safe = {
	minX = display.safeScreenOriginX,
	maxX = (display.contentWidth-display.safeActualContentWidth)*0.5+display.safeActualContentWidth,
	minY = display.safeScreenOriginY,
	maxY = (display.contentHeight-display.safeActualContentHeight)*0.5+display.safeActualContentHeight,
	width = display.safeActualContentWidth,
	height = display.safeActualContentHeight
}

return screen
