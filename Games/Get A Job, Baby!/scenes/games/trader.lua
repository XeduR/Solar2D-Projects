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

-- This template.lua can be copied and used to create new gameModes/jobs with ease.

local composer = require( "composer" )
local screen = require( "scripts.screen" )
local settings = require( "data.settings" )
local physics = physics or require("physics")
local sfx = require( "scripts.sfx" )

local mask = graphics.newMask( "images/mask.png" )
local repeatScene, sceneGroupRef = false
local gameEnd, player, countdown, startTime, updateTimer
local gameScore, miss, hit = 0, 1, 0

local buyOrSell, command, continue, switch = 1

local groupUI = display.newGroup()
local groupGame = display.newGroup()
local groupBG = display.newGroup()

-------------------------------------------------------------------------------

local switchTime = 850
local scorePerFrame = 1
local penaltyPerFrame = 0.8
local countdownTime = 15000

-------------------------------------------------------------------------------

local function ease( a, b, c, d ) return c+d*(((1-a/b)^2)-((1-a/b)^40))*1.25 end
local function reset( t ) t.xScale, t.yScale = 1, 1; if continue then switch() end end

local previous, multiplier = 1, 1
function switch()
	if math.random() > 0.5 then
		buyOrSell = 1
		command.text = "Buy!"
		command:setFillColor( unpack( settings.colours.a ) )
	else
		buyOrSell = 2
		command.text = "Sell!"
		command:setFillColor( unpack( settings.colours.b ) )
	end

	if buyOrSell ~= previous then
		multiplier = 1
		previous = buyOrSell
	end

	transition.to( command, { time=switchTime, xScale=1.25, yScale=1.25, transition=ease, onComplete=reset })
end

local activeButton = "none"
local function buyOrSellListener()
	multiplier = multiplier + 0.05

	if buyOrSell == 1 and activeButton == "buy" then
		hit = hit+1
		gameScore = gameScore + scorePerFrame * multiplier
	elseif buyOrSell == 2 and activeButton == "sell" then
		hit = hit+1
		gameScore = gameScore + scorePerFrame * multiplier
	else
		miss = miss+1
		gameScore = gameScore - penaltyPerFrame * multiplier
	end

	G_performance.text = "$" .. math.round(gameScore) .. " - " .. math.round((hit/(hit+miss))*100) .. "%"
end

local function buttonEvent( event )
	if event.phase == "began" then
		sfx.play()
        display.getCurrentStage():setFocus( event.target )
		activeButton = event.target.id
	elseif event.phase ~= "moved" then
		sfx.play()
        display.getCurrentStage():setFocus( nil )
		activeButton = "none"
	end
	return true
end

local function gameStart()
	transition.to( sceneGroupRef, { delay=500, time=2000, maskScaleX=GLOBAL_FIX.scaleMaskTo, maskScaleY=GLOBAL_FIX.scaleMaskTo, transition=easing.outInBack, onComplete=function()
			G_block.isHitTestable = false
			physics.start()
			gameScore = 0
			sceneGroupRef:setMask( nil )

			miss, hit = 1, 0
			continue = true
			switch()
			Runtime:addEventListener( "enterFrame", buyOrSellListener )

			startTime = system.getTimer()
			Runtime:addEventListener( "enterFrame", updateTimer )
		end
	})
end

function gameEnd()
	G_block.isHitTestable = true
	physics.pause()

	continue = false
	Runtime:removeEventListener( "enterFrame", buyOrSellListener )

	sceneGroupRef:setMask( mask )
	sceneGroupRef.maskX = player.x
	sceneGroupRef.maskY = player.y
	sceneGroupRef.maskScaleX = GLOBAL_FIX.scaleMaskTo
	sceneGroupRef.maskScaleY = GLOBAL_FIX.scaleMaskTo

	transition.to( sceneGroupRef, { delay=settings.mask.hideDelay, time=settings.mask.hideTime, transition=settings.mask.hideEasing, maskScaleX=0.01, maskScaleY=0.01, onComplete=function()
			for i = groupGame.numChildren, 1, -1 do
				display.remove( groupGame[i] )
				groupGame[i] = nil
			end

			if repeatScene then
				gameScore = 0
				G_performance.text = "$0 - 100%"
				gameStart()
			else
				local rate = hit/(hit+miss)
				composer.gotoScene( "scenes.calendar", { params = { score=math.round(gameScore), rate=rate}} )
			end
		end
	})
end


function updateTimer()
	local ratio = 1 - (system.getTimer() - startTime) / countdownTime

	if ratio > 0 then
		countdown.xScale = ratio
	else
		Runtime:removeEventListener( "enterFrame", updateTimer )
		gameEnd()
	end
end


-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

local scene = composer.newScene()

function scene:create( event )
	local sceneGroup = self.view
	sceneGroupRef = sceneGroup

	if event.params and event.params.repeatScene then
		repeatScene = true
	end

	local sky = display.newRect( groupBG, screen.centreX, screen.centreY, screen.width, screen.height )
	sky:setFillColor( unpack( settings.colours.sky ) )

	local monitor = display.newRect( groupBG, screen.centreX, screen.centreY, 680, 380 )
	monitor.strokeWidth = 20
	monitor:setStrokeColor( unpack( settings.colours.ground ) )

	local buy = display.newRect( groupBG, screen.centreX + 170, screen.centreY+120, 160, 80 )
	buy:setFillColor( unpack( settings.colours.b ) )
	buy.id = "buy"
	buy:addEventListener( "touch", buttonEvent )

	local buyText = display.newText( groupBG, "BUY", buy.x, buy.y, "fonts/Roboto-Black.ttf", 48 )
	buyText:setFillColor( unpack( settings.colours.a ) )

	local sell = display.newRect( groupBG, screen.centreX - 170, screen.centreY+120, 160, 80 )
	sell:setFillColor( unpack( settings.colours.b ) )
	sell.id = "sell"
	sell:addEventListener( "touch", buttonEvent )

	local sellText = display.newText( groupBG, "SELL", sell.x, sell.y, "fonts/Roboto-Black.ttf", 48 )
	sellText:setFillColor( unpack( settings.colours.a ) )

	command = display.newText( groupBG, "", screen.centreX, screen.centreY - 40, "fonts/Roboto-Black.ttf", 64 )

	player = display.newRect( groupBG, screen.centreX, screen.maxY - 100, 200, 200 )
	player:setFillColor( unpack( settings.colours.player ) )

	countdown = display.newRect( groupUI, screen.minX, screen.maxY, screen.width, 24 )
	countdown.anchorX, countdown.anchorY = 0, 1

	local title = display.newText( groupUI, "Hold down the right button!", screen.centreX, screen.minY + 4, "fonts/Roboto-Black.ttf", 40 )
	title.anchorY = 0
	title:setFillColor( unpack( settings.colours.b ) )

	sceneGroup:setMask( mask )
	sceneGroup.maskX = player.x
	sceneGroup.maskY = player.y
	sceneGroup.maskScaleX = 0.01
	sceneGroup.maskScaleY = 0.01

	sceneGroup:insert( groupBG )
	sceneGroup:insert( groupGame )
	sceneGroup:insert( groupUI )
end


function scene:show( event )
    if event.phase == "did" then
		gameStart()
	end
end

-------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

-------------------------------------------------------------------------------

return scene
