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

local settings = {

	countdownTime = 10000,
	countdownTimeGameStarted = 30000,

	colours = {
		sky = { 0.55, 0.83, 0.71 },
		ground = { 0.29, 0.43, 0.42 },
		player = { 0.95, 0.49, 0.22 },
		a = { 0.97, 0.85, 0.32 },
		b = { 0.86, 0.24, 0.24 },
	},

	mask = {
		revealDelay = 500,
		revealTime = 1500,
		revealEasing = easing.outInBack,
		hideDelay = 0,
		hideTime = 500,
		hideEasing = easing.outInBack,
	}

}

return settings
