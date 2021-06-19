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

local ceiling, ground, dig, digTimer

local timesDug, maxDigs = 0, 1

local groupUI = display.newGroup()
local groupGame = display.newGroup()
local groupBG = display.newGroup()

-------------------------------------------------------------------------------

local tapMaxSpeed = 100
local gemGoldCount = 7
local gemRarity = 0.15
local hitsPerGem = 5
local hitsPerGold = 3
local plusMinusHits = 1
local gemPricePerSquarePixel = 0.12
local goldPricePerSquarePixel = 0.025
local countdownTime = 15000

-------------------------------------------------------------------------------

local function digPerformance()
	maxDigs = maxDigs+1
	G_performance.text = "$" .. math.round(gameScore) .. " - " .. math.round(timesDug/maxDigs*100) .. "%"
end

local function generateCave()
	ceiling = display.newPolygon( groupBG, screen.minX, screen.minY, {
		0,0, screen.width,0, screen.width,260+math.random(-30,30), screen.centreX+math.random(80,120),180+math.random(-30,30), screen.centreX-math.random(80,120),240+math.random(-30,30), 0,240+math.random(-30,30)
	} )
	ceiling:setFillColor( unpack( settings.colours.ground ) )
	ceiling.anchorX, ceiling.anchorY = 0, 0

	ground = display.newPolygon( groupBG, screen.minX, screen.maxY, {
		screen.width,0, 0,0, 0,-160+math.random(-30,30), screen.centreX-math.random(80,120),-180+math.random(-30,30), screen.centreX+math.random(80,120),-240+math.random(-30,30), screen.width,-240+math.random(-30,30)
	} )
	ground:setFillColor( unpack( settings.colours.ground ) )
	ground.anchorX, ground.anchorY = 0, 1

	player.x, player.y = screen.centreX, screen.centreY

	physics.addBody( ceiling, "static", {friction=2} )
	physics.addBody( ground, "static", {friction=2} )
	physics.addBody( player, "dynamic", {density=10,friction=1.2,bounce=0.2} )
end

local function ease( a, b, c, d ) return c+d*(((1-a/b)^2)-((1-a/b)^40))*1.25 end
local function reset( t ) t.xScale, t.yScale = 1, 1; t.canTouch = true end


local function addMineral()
	local mineral = display.newRect( groupGame, math.random( screen.minX+150, screen.maxX-150 ), math.random( screen.minY+150, screen.maxY-150 ), math.random( 35,80 ), math.random( 40,75 ) )

	if math.random() <= gemRarity then
		mineral.hits = hitsPerGem + math.random(-plusMinusHits,plusMinusHits)
		mineral.scoreValue = mineral.width*mineral.height*gemPricePerSquarePixel
		mineral:setFillColor( unpack( settings.colours.b ) )
	else
		mineral.hits = hitsPerGold + math.random(-plusMinusHits,plusMinusHits)
		mineral.scoreValue = mineral.width*mineral.height*goldPricePerSquarePixel
		mineral:setFillColor( unpack( settings.colours.a ) )
	end

	mineral.rotation = math.random( 0, 360 )
	mineral.canTouch = true
	mineral:addEventListener( "touch", dig )
end


function dig( event )
	if event.phase == "began" and event.target.canTouch then
		sfx.play()
		event.target.canTouch = false
		event.target.hits = event.target.hits - 1
		timesDug = timesDug+1

		if event.target.hits > 0 then
			transition.to( event.target, { time=tapMaxSpeed, xScale=1.25, yScale=1.25, transition=ease, onComplete=reset })
		else
			gameScore = gameScore + math.round( event.target.scoreValue )
			display.remove( event.target )
			addMineral()

			G_performance.text = "$" .. math.round(gameScore) .. " - " .. math.round((timesDug/(maxDigs))*100) .. "%"
		end
	end
	return true
end


local function gameStart()
	transition.to( sceneGroupRef, { delay=500, time=2000, maskScaleX=composer.scaleMaskTo, maskScaleY=composer.scaleMaskTo, transition=easing.outInBack, onComplete=function()
			G_block.isHitTestable = false
			gameScore, timesDug, maxDigs = 0, 0, 1
			sceneGroupRef:setMask( nil )

			for i = 1, gemGoldCount do
				addMineral()
			end

			digTimer = timer.performWithDelay( tapMaxSpeed*1.5, digPerformance, 0 )
			startTime = system.getTimer()
			Runtime:addEventListener( "enterFrame", updateTimer )
		end
	})
end

function gameEnd()
	G_block.isHitTestable = true
	timer.cancel( digTimer )
	physics.pause()

	continue = false
	Runtime:removeEventListener( "enterFrame", buyOrSellListener )

	sceneGroupRef:setMask( mask )
	sceneGroupRef.maskX = player.x
	sceneGroupRef.maskY = player.y
	sceneGroupRef.maskScaleX = composer.scaleMaskTo
	sceneGroupRef.maskScaleY = composer.scaleMaskTo

	transition.to( sceneGroupRef, { delay=settings.mask.hideDelay, time=settings.mask.hideTime, transition=settings.mask.hideEasing, maskScaleX=0.01, maskScaleY=0.01, onComplete=function()
			for i = groupGame.numChildren, 1, -1 do
				display.remove( groupGame[i] )
				groupGame[i] = nil
			end

			physics.removeBody( ground )
			physics.removeBody( ceiling )
			physics.removeBody( player )

			display.remove( ceiling )
			display.remove( ground )
			ceiling = nil
			ground = nil

			if repeatScene then
				physics.start()
				generateCave()
				gameScore = 0
				G_performance.text = "$0 - 100%"
				gameStart()
			else
				local rate = timesDug/maxDigs
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

	local bg = display.newRect( groupBG, screen.centreX, screen.centreY, screen.width, screen.height )
	bg:setFillColor( unpack( settings.colours.sky ) )

	player = display.newRect( groupUI, screen.centreX, screen.centreY, 40, 40 )
	player:setFillColor( unpack( settings.colours.player ) )

	countdown = display.newRect( groupUI, screen.minX, screen.maxY, screen.width, 24 )
	countdown.anchorX, countdown.anchorY = 0, 1

	local title = display.newText( groupUI, "Tap to dig gold & gems!", screen.centreX, screen.minY + 4, "fonts/Roboto-Black.ttf", 40 )
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
	if event.phase == "will" then
		physics.start()
		generateCave()

    elseif event.phase == "did" then
		gameStart()
	end
end

-------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

-------------------------------------------------------------------------------

return scene
