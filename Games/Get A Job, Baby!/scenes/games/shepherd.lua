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
local sfx = require( "scripts.sfx" )

local mask = graphics.newMask( "images/mask.png" )
local repeatScene, sceneGroupRef = false
local gameEnd, player, countdown, startTime, updateTimer
local gameScore, miss, hit = 0, 1, 0

local ceiling, ground, callBack, sheepEscapeTimer, sheepAnimationTimer

local sheep = {}
local sheepN = 1

local sheepEscaped = 0

local groupUI = display.newGroup()
local groupGame = display.newGroup()
local groupBG = display.newGroup()

-------------------------------------------------------------------------------

local tapMaxSpeed = 100
local sheepAnimationFrequency = 200
local sheepSpawnSpeed = 350
local sheepCount = 32
local sheepEscapeTime = 1500
local sheepEscapeTimeVariance = 250
local sheepMinWidth = 40
local sheepMaxWidth = 80
local sheepMinHeight = 30
local sheepMaxHeight = 60
local sheepValuePerSquarePixel = 0.02
local countdownTime = 15000

-------------------------------------------------------------------------------

local function ease( a, b, c, d ) return c+d*(((1-a/b)^2)-((1-a/b)^40))*1.25 end
local function reset( t ) t.xScale, t.yScale = 1, 1; t.canTouch = true end

local function sheepAnimation()
	transition.to( sheep[math.random(1,sheepCount)], {time=120, xScale=1.5, yScale=1.5, transition=ease,onComplete=reset} )
end

local function newHerd()
	for i = 1, sheepCount do
		sheep[i] = display.newRect( groupGame, screen.centreX + math.random( -120, 120 ), screen.centreY + math.random( -60, 60 ), math.random( sheepMinWidth, sheepMaxWidth ), math.random( sheepMinHeight, sheepMaxHeight ) )
		if i % 2 == 0 then
			sheep[i]:setFillColor( unpack( settings.colours.b ) )
		else
			sheep[i]:setFillColor( unpack( settings.colours.a ) )
		end
	end
end


local function escapeSuccess( t )
	sheepEscaped = sheepEscaped + t.scoreValue
	G_performance.text = "$" .. math.round(gameScore) .. " - " .. math.round(gameScore/(sheepEscaped+gameScore)*100) .. "%"
end


local function launchEscape()
	sheep[sheepN] = display.newRect( groupGame, screen.centreX + math.random( 0, 100 ), screen.centreY + math.random( -60, 60 ), math.random( sheepMinWidth, sheepMaxWidth ), math.random( sheepMinHeight, sheepMaxHeight ) )
	if sheepN % 2 == 0 then
		sheep[sheepN]:setFillColor( unpack( settings.colours.b ) )
	else
		sheep[sheepN]:setFillColor( unpack( settings.colours.a ) )
	end
	sheep[sheepN].scoreValue = sheep[sheepN].width*sheep[sheepN].height*sheepValuePerSquarePixel
	sheep[sheepN].move = transition.to( sheep[sheepN], {
		time = sheepEscapeTime + math.random(-sheepEscapeTimeVariance,sheepEscapeTimeVariance),
		x = screen.maxX + sheep[sheepN].width*0.5,
		y = math.random(screen.centreY-80, screen.maxY),
		onComplete = function( self ) escapeSuccess( self ) end
	})
	sheep.id = sheepN

	local n = sheepN
	sheepN = sheepN+1

	timer.performWithDelay( 150, function()
		sheep[n].canTouch = true
		sheep[n]:addEventListener( "touch", callBack )
	end )
end


function callBack( event )
	if event.phase == "began" and event.target.canTouch then
		event.target.canTouch = false
		sfx.play()

		transition.cancel( event.target )
		display.remove( event.target )
		sheep.id = nil

		gameScore = gameScore + math.round( event.target.scoreValue )
		G_performance.text = "$" .. math.round(gameScore) .. " - " .. math.round(gameScore/(sheepEscaped+gameScore)*100) .. "%"
	end
	return true
end


local function gameStart()
	transition.to( sceneGroupRef, { delay=500, time=2000, maskScaleX=GLOBAL_FIX.scaleMaskTo, maskScaleY=GLOBAL_FIX.scaleMaskTo, transition=easing.outInBack, onComplete=function()
			G_block.isHitTestable = false
			gameScore, sheepEscaped = 0, 0
			sceneGroupRef:setMask( nil )

			sheepN = sheepCount+1
			sheepEscapeTimer = timer.performWithDelay( sheepSpawnSpeed, launchEscape, 0 )
			sheepAnimationTimer = timer.performWithDelay( sheepAnimationFrequency, sheepAnimation, 0 )

			startTime = system.getTimer()
			Runtime:addEventListener( "enterFrame", updateTimer )
		end
	})
end

function gameEnd()
	G_block.isHitTestable = true
	timer.cancel( sheepEscapeTimer )
	timer.cancel( sheepAnimationTimer )
	transition.cancel()

	sceneGroupRef:setMask( mask )
	sceneGroupRef.maskX = player.x
	sceneGroupRef.maskY = player.y
	sceneGroupRef.maskScaleX = GLOBAL_FIX.scaleMaskTo
	sceneGroupRef.maskScaleY = GLOBAL_FIX.scaleMaskTo

	transition.to( sceneGroupRef, { delay=settings.mask.hideDelay, time=settings.mask.hideTime, transition=settings.mask.hideEasing, maskScaleX=0.01, maskScaleY=0.01, onComplete=function()

			for i = #sheep, 1, -1 do
				display.remove( sheep[i] )
				sheep[i] = nil
			end

			if repeatScene then
				gameScore = 0
				G_performance.text = "$0 - 100%"
				newHerd()
				gameStart()
			else
				local rate = gameScore/(sheepEscaped+gameScore)
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

	local ground = display.newRect( groupBG, screen.centreX, screen.centreY - 120, screen.width, screen.height )
	ground:setFillColor( unpack( settings.colours.ground ) )
	ground.anchorY = 0

	player = display.newRect( groupBG, screen.centreX - 400, screen.centreY - 80, 20, 20 )
	player:setFillColor( unpack( settings.colours.player ) )

	countdown = display.newRect( groupUI, screen.minX, screen.maxY, screen.width, 24 )
	countdown.anchorX, countdown.anchorY = 0, 1

	local title = display.newText( groupUI, "Keep the sheep inside their pen!", screen.centreX, screen.minY + 4, "fonts/Roboto-Black.ttf", 40 )
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
		newHerd()

	elseif event.phase == "did" then
		gameStart()
	end
end

-------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

-------------------------------------------------------------------------------

return scene
