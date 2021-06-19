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

local composer = require( "composer" )
local screen = require( "scripts.screen" )
local settings = require( "data.settings" )
local sfx = require( "scripts.sfx" )

local sceneGroupRef

local groupUI = display.newGroup()
local groupBG = display.newGroup()

local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local monthNames = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local calendar = {}
local continue
local previousMonth = 0

-------------------------------------------------------------------------------

local function resetYear()
	for i = 1, 12 do
		for j = 1, daysInMonth[i] do
			calendar[i].days[j]:setFillColor( unpack( settings.colours.ground ) )
		end
		calendar[i].moneyMade.text = "$0"
	end
	previousMonth = 0
	-- composer.money = 0
	-- composer.month = 1
	-- G_money.text = "$0"
	-- G_month.text = "Month 1"
end

local function updateMonth( score, rate, skipped )
	if skipped then
		-- If player skipped working for a month, then just autofill the year instantly
		for i = 1, daysInMonth[rate] do
			calendar[rate].days[i]:setFillColor( unpack( settings.colours.b ) )
		end

		if rate == 12 then
			G_block.isHitTestable = false
			transition.blink( continue, {time=2000} )
		end
	else
		local days = daysInMonth[GLOBAL_FIX.month]
		local daysEmployed = math.ceil( days*rate )
		local delay = 25

		for i = 1, daysEmployed do
			timer.performWithDelay( delay*i, function()
				calendar[GLOBAL_FIX.month].days[i]:setFillColor( unpack( settings.colours.a ) )
			end )
		end

		if daysEmployed < days then
			for i = daysEmployed+1, days do
				timer.performWithDelay( delay*i, function()
					calendar[GLOBAL_FIX.month].days[i]:setFillColor( unpack( settings.colours.b ) )
				end )
			end
		end

		timer.performWithDelay( delay*(days+2), function()
			local monthlyScore = score * daysEmployed
			GLOBAL_FIX.money = GLOBAL_FIX.money + monthlyScore
			G_money.text = "$" .. GLOBAL_FIX.money
			calendar[GLOBAL_FIX.month].moneyMade.text = "$" .. monthlyScore
			previousMonth = GLOBAL_FIX.month
			GLOBAL_FIX.month = GLOBAL_FIX.month+1
			continue.isVisible = true
			G_block.isHitTestable = false
			transition.blink( continue, {time=2000} )
		end )
	end
end


local function nextScene( event )
	if event.phase == "ended" then
		sfx.play()
		G_block.isHitTestable = true
		G_performance.text = "$0 - 100%"
		G_performance.isVisible = false
		transition.cancel( continue )

		if GLOBAL_FIX.month >= 13 then
			G_month.text = "Month 12"
			composer.gotoScene( "scenes.hospital",  { effect = "slideUp", params = { gameover=true } } )
		else
			G_month.text = "Month " .. GLOBAL_FIX.month
			composer.gotoScene( "scenes.yard", { effect = "slideUp" } )
		end
	end
	return true
end

-------------------------------------------------------------------------------

local scene = composer.newScene()

function scene:create( event )
	local sceneGroup = self.view
	sceneGroupRef = sceneGroup

	local background = display.newRect( groupBG, screen.centreX, screen.centreY, screen.width, screen.height )
	background:setFillColor( unpack( settings.colours.sky ) )
	background:addEventListener( "touch", nextScene )

	continue = display.newText( groupBG, "Tap to Continue", screen.centreX, screen.maxY - 4, "fonts/Roboto-Black.ttf", 32 )
	continue.isVisible = false
	continue.anchorY = 1

	local x, y, xOffset, yOffset = 48, 180, 0, 0
	local monthWidth = 50
	local monthHeight = 240
	local monthPadding = 106
	local daySize = 20
	local cellOffset = monthWidth*0.5

	for i = 1, 12 do
		calendar[i] = display.newText( groupBG, monthNames[i], x+monthWidth*xOffset + monthPadding*xOffset, y+monthHeight*yOffset, "fonts/Roboto-Black.ttf", 40 )
		calendar[i].anchorY = 1
		calendar[i]:setFillColor( unpack( settings.colours.a ) )
		calendar[i].days = {}
		calendar[i].moneyMade = display.newText( groupBG, "$0", x+monthWidth*xOffset + monthPadding*xOffset - 26, calendar[i].y + 150, "fonts/Roboto-Regular.ttf", 26 )
		calendar[i].moneyMade.anchorX = 0

		local row, column = 1, 0
		local xStart, yStart = calendar[i].x - cellOffset, calendar[i].y
		for j = 1, daysInMonth[i] do
			calendar[i].days[j] = display.newRect( groupBG, xStart+daySize*column, yStart+daySize*row, daySize, daySize )
			calendar[i].days[j].anchorX, calendar[i].days[j].anchorY = 0, 0
			calendar[i].days[j]:setFillColor( unpack( settings.colours.ground ) )

			if j % 7 == 0 then
				row = row+1
				column = -1
			end
			column = column+1
		end

		if i == 6 then
			xOffset, yOffset = -1, 1
		end
		xOffset = xOffset+1
	end

	sceneGroup:insert( groupBG )
	sceneGroup:insert( groupUI )
end


function scene:show( event )
	if event.phase == "will" then
		for i = previousMonth+1, GLOBAL_FIX.month-1 do
			updateMonth( 0, i, true )
		end
	elseif event.phase == "did" then
		if event.params then
			updateMonth( event.params.score or 0, (event.params.rate and event.params.rate) or 0 )
		end
	end
end


function scene:hide( event )
	if event.phase == "did" then
		if GLOBAL_FIX.month == 13 then
			resetYear()
		end
	end
end

-------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

-------------------------------------------------------------------------------

return scene
