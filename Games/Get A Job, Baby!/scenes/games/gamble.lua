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

local cardA, cardB, moneyAtStart
local freeze, gameInProgress = false, false

local groupUI = display.newGroup()
local groupGame = display.newGroup()
local groupBG = display.newGroup()

-------------------------------------------------------------------------------

local countdownTime = 15000

-------------------------------------------------------------------------------

local function gameStart()
	transition.to( sceneGroupRef, { delay=500, time=2000, maskScaleX=GLOBAL_FIX.scaleMaskTo, maskScaleY=GLOBAL_FIX.scaleMaskTo, transition=easing.outInBack, onComplete=function()
			G_block.isHitTestable = false
			sceneGroupRef:setMask( nil )
			gameInProgress, freeze = false, false
			moneyAtStart = GLOBAL_FIX.money

			startTime = system.getTimer()
			Runtime:addEventListener( "enterFrame", updateTimer )
		end
	})
end

function gameEnd()
	G_block.isHitTestable = true

	sceneGroupRef:setMask( mask )
	sceneGroupRef.maskX = player.x
	sceneGroupRef.maskY = player.y
	sceneGroupRef.maskScaleX = GLOBAL_FIX.scaleMaskTo
	sceneGroupRef.maskScaleY = GLOBAL_FIX.scaleMaskTo

	transition.to( sceneGroupRef, { delay=settings.mask.hideDelay, time=settings.mask.hideTime, transition=settings.mask.hideEasing, maskScaleX=0.01, maskScaleY=0.01, onComplete=function()
			if repeatScene then
				gameStart()
			else
				composer.gotoScene( "scenes.calendar", { params = { score=GLOBAL_FIX.money - moneyAtStart, rate=0.01}} )
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
		freeze = true
		if not gameInProgress then
			gameEnd()
		end
	end
end


local function winOrLose( win, bet )
	gameInProgress = false
	sfx.play()
	if win then
		GLOBAL_FIX.money = GLOBAL_FIX.money + bet*2
		G_money.text = "$" .. GLOBAL_FIX.money
	end
	if freeze then
		timer.performWithDelay( 1000, gameEnd )
	end
end

local function betting( event )
	if event.phase == "ended" and not freeze and not gameInProgress then
		if GLOBAL_FIX.money ~= 0 then
			gameInProgress = true
			sfx.play()
			local bet = math.floor( GLOBAL_FIX.money * 0.01 * event.target.id )
			GLOBAL_FIX.money = GLOBAL_FIX.money - bet
			G_money.text = "$" .. GLOBAL_FIX.money

			cardA.y = -300
			cardB.y = -300

			local playerCard = math.random( 1, 13 )
			cardA.number.text = playerCard
			local dealerCard = math.random( 1, 13 )
			cardB.number.text = dealerCard
			local win = false

			if playerCard > dealerCard then
				win = true
			end

			transition.to( cardA, {time=500, y=0, transition=easing.inOutBack} )
			transition.to( cardB, {time=500, y=0, transition=easing.inOutBack, onComplete=function() winOrLose( win, bet ) end } )
		end
	end
	return true
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

	local bg = display.newRect( groupBG, screen.centreX, screen.centreY, screen.width, screen.height )
	bg:setFillColor( unpack( settings.colours.sky ) )

	local ground = display.newRect( groupBG, screen.centreX, screen.centreY-40, screen.width, screen.height )
	ground:setFillColor( unpack( settings.colours.ground ) )
	ground.anchorY = 0

	player = display.newRect( groupBG, screen.maxX - 160, screen.maxY - 120, 120, 120 )
	player:setFillColor( unpack( settings.colours.player ) )

	countdown = display.newRect( groupUI, screen.minX, screen.maxY, screen.width, 24 )
	countdown.anchorX, countdown.anchorY = 0, 1

	local title = display.newText( groupUI, "Place your bets!", screen.centreX, screen.minY + 4, "fonts/Roboto-Black.ttf", 40 )
	title.anchorY = 0
	title:setFillColor( unpack( settings.colours.b ) )

	local text = display.newText( groupUI, "Bet 25%, 50% or 100% of your money.\nIf your card is higher than the dealer's\nthen you double your bet.", screen.centreX, screen.centreY, "fonts/Roboto-Black.ttf", 36 )
	text.anchorY = 0

	local bet25 = display.newRect( groupBG, screen.centreX - 140, screen.centreY+220, 120, 80 )
	bet25:setFillColor( unpack( settings.colours.b ) )
	bet25.id = "25"
	bet25:addEventListener( "touch", betting )

	local bet25Text = display.newText( groupBG, "25%", bet25.x, bet25.y, "fonts/Roboto-Black.ttf", 48 )
	bet25Text:setFillColor( unpack( settings.colours.a ) )

	local bet50 = display.newRect( groupBG, screen.centreX, screen.centreY+220, 120, 80 )
	bet50:setFillColor( unpack( settings.colours.b ) )
	bet50.id = "50"
	bet50:addEventListener( "touch", betting )

	local bet50Text = display.newText( groupBG, "50%", bet50.x, bet50.y, "fonts/Roboto-Black.ttf", 48 )
	bet50Text:setFillColor( unpack( settings.colours.a ) )

	local bet100 = display.newRect( groupBG, screen.centreX + 140, screen.centreY+220, 120, 80 )
	bet100:setFillColor( unpack( settings.colours.b ) )
	bet100.id = "25"
	bet100:addEventListener( "touch", betting )

	local bet100Text = display.newText( groupBG, "100%", bet100.x, bet100.y, "fonts/Roboto-Black.ttf", 48 )
	bet100Text:setFillColor( unpack( settings.colours.a ) )

	cardA = display.newGroup()
	cardA.y = -300
	cardA.base = display.newRect( cardA, screen.centreX - 90, screen.centreY-152, 140, 200 )
	cardA.base:setFillColor( unpack( settings.colours.b ) )
	cardA.number = display.newText( cardA, "13", cardA.base.x, cardA.base.y, "fonts/Roboto-Black.ttf", 60 )
	cardA.number:setFillColor( unpack( settings.colours.a ) )
	cardA.text = display.newText( cardA, "YOU", cardA.base.x, cardA.base.y + cardA.base.height*0.5 - 20, "fonts/Roboto-Black.ttf", 32 )
	groupGame:insert( cardA )

	cardB = display.newGroup()
	cardB.y = -300
	cardB.base = display.newRect( cardB, screen.centreX + 90, screen.centreY-152, 140, 200 )
	cardB.base:setFillColor( unpack( settings.colours.b ) )
	cardB.number = display.newText( cardB, "13", cardB.base.x, cardB.base.y, "fonts/Roboto-Black.ttf", 60 )
	cardB.number:setFillColor( unpack( settings.colours.a ) )
	cardB.text = display.newText( cardB, "DEALER", cardB.base.x, cardB.base.y + cardB.base.height*0.5 - 20, "fonts/Roboto-Black.ttf", 32 )
	groupGame:insert( cardB )


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
		G_performance.isVisible = false
		gameStart()
	end
end

-------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

-------------------------------------------------------------------------------

return scene
