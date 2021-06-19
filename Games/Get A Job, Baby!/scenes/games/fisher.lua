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
local physics = physics or require("physics")
local sfx = require( "scripts.sfx" )

local mask = graphics.newMask( "images/mask.png" )
local repeatScene = false
local sceneGroupRef, hasThrown, isLoading, throwStart, throwIndicator, throwStrength
local gameEnd, player, countdown, startTime, updateTimer, water, ground
local spearsThrown, spearsHit, gameScore = 0, 0, 0
local fish = {}

local groupUI = display.newGroup()
local groupGame = display.newGroup()
local groupBG = display.newGroup()

-------------------------------------------------------------------------------

local numberOfFish = 6
local countdownTime = 15000
local fishScoreMultiplier = 0.05
local throwTimeMax = 500

-------------------------------------------------------------------------------

local function newFish()
	local width, height = math.random(40,120), math.random(20,50)
	local fish = display.newRect( groupGame, math.random(water.contentBounds.xMin, ground.contentBounds.xMin), math.random(water.contentBounds.yMin,water.contentBounds.yMax), width, height )
	fish:setFillColor( unpack( settings.colours.b ) )
	fish.alpha = 0
	fish.type = "fish"
	fish.scoreValue = math.round( width*height*fishScoreMultiplier )

	function fish:move()
		if self and self.width then
			self.transition = transition.to( self, {
				time = math.random(4000,8000),
				x = math.random(water.contentBounds.xMin+self.width, ground.contentBounds.xMin-self.width),
				y = math.random(water.contentBounds.yMin+self.height, ground.contentBounds.yMax-self.height),
				onComplete = function( self ) self:move() end
			} )
		end
	end
	fish:move()

	transition.to( fish, {time=200,alpha=1,onComplete=function() physics.addBody( fish, "static", {isSensor=true} ) end })
end


local function gameStart()
	transition.to( sceneGroupRef, { delay=500, time=2000, maskScaleX=GLOBAL_FIX.scaleMaskTo, maskScaleY=GLOBAL_FIX.scaleMaskTo, transition=easing.outInBack, onComplete=function()
			G_block.isHitTestable = false
			physics.start()
			physics.addBody( ground, "static" )
			physics.addBody( bottomSensor, "static", {isSensor=true} )
			spearsThrown, spearsHit, throwStrength, gameScore = 0, 0, 0, 0

			for i = 1, numberOfFish do
				newFish()
			end

			sceneGroupRef:setMask( nil )

			startTime = system.getTimer()
			Runtime:addEventListener( "enterFrame", updateTimer )
		end
	})
end

function gameEnd()
	G_block.isHitTestable = true
	physics.removeBody( ground )
	physics.pause()

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

			spear.rotation = 0
			Runtime:removeEventListener( "enterFrame", charge )
			display.remove( throwIndicator )
			throwIndicator = nil

			if repeatScene then
				gameScore = 0
				G_performance.text = "$0 - 100%"
				gameStart()
			else
				local rate
				if spearsThrown == 0 then
					rate = 0
				else
					rate = spearsHit/spearsThrown
				end
				composer.gotoScene( "scenes.calendar", { params = { score=gameScore, rate=rate}} )
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


local function fishHit( self, event )
	if self.type == "spear" and event.selfElement == 2 and event.other.type == "fish" then
		transition.cancel( event.other.transition )
		spearsThrown = spearsThrown + 1
		spearsHit = spearsHit + 1
		gameScore = gameScore + event.other.scoreValue
		G_performance.text = "$" .. gameScore .. " - " .. math.round(spearsHit/spearsThrown*100) .. "%"

		display.remove( self )
		display.remove( event.other )
		newFish()

	elseif self.type == "spear" and event.other.type == "sensor" then
		spearsThrown = spearsThrown + 1
		display.remove( self )
		G_performance.text = "$" .. gameScore .. " - " .. math.round(spearsHit/spearsThrown*100) .. "%"

	end
end


local function charge()
	throwStrength = (system.getTimer() - throwStart) / throwTimeMax

	if throwStrength < 1 then
		spear.rotation = 15 * throwStrength
		throwIndicator.yScale = throwStrength
	else
		spear.rotation = 15
		throwIndicator.yScale = 1
		Runtime:removeEventListener( "enterFrame", charge )
	end
end


local function throw( event )
	if event.phase == "began" then
		if not isLoading then
			sfx.play()
			isLoading = true
			throwStrength = 0
			throwStart = system.getTimer()
			throwIndicator = display.newRect( groupUI, player.x, player.y - 30, 18, 50 )
			throwIndicator:setFillColor( unpack( settings.colours.b ) )
			throwIndicator.anchorY = 1
			Runtime:addEventListener( "enterFrame", charge )
		end

	elseif event.phase ~= "moved" then
		if isLoading and not hasThrown then
			hasThrown = true
			sfx.play()
			Runtime:removeEventListener( "enterFrame", charge )

			local projectile = display.newRect( groupGame, player.x, player.y, 50, 4 )
			projectile.type = "spear"
			projectile:setFillColor(0)
			projectile.rotation = spear.rotation
			spear.isVisible = false
			spear.rotation = 0

			physics.addBody( projectile, "dynamic",
				{density=1,friction=1,shape={-25,-2,25,-2,25,2,-25,2} },
				{density=4,friction=1,shape={-30,-4,-20,-4,-20,4,-30,4} }
			)
			projectile.collision = fishHit
			projectile:addEventListener( "collision" )

			local throwMultiplier = 240
			projectile:setLinearVelocity( -throwStrength*throwMultiplier, -math.cos( math.rad( projectile.rotation ) ) * throwStrength * throwMultiplier, projectile.x - projectile.width*0.5, projectile.y )
			projectile:applyAngularImpulse( -5 )

			display.remove( throwIndicator )
			throwIndicator = nil

			timer.performWithDelay( 250, function() spear.isVisible = true; isLoading = false; hasThrown = false end )
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


	local sky = display.newRect( groupBG, screen.centreX, screen.centreY, screen.width, screen.height )
	sky:setFillColor( unpack( settings.colours.sky ) )

	water = display.newRect( groupBG, screen.minX, screen.maxY, screen.width, 250 )
	water:setFillColor( unpack( settings.colours.a ) )
	water.anchorX, water.anchorY = 0, 1

	ground = display.newRect( groupBG, screen.maxX, screen.maxY, 200, 340 )
	ground:setFillColor( unpack( settings.colours.ground ) )
	ground.anchorX, ground.anchorY = 1, 1

	bottomSensor = display.newRect( groupBG, screen.centreX, screen.maxY, screen.width*2, 50 )
	bottomSensor.type = "sensor"
	bottomSensor.isVisible = false
	bottomSensor.anchorY = 0

	player = display.newRect( groupBG, ground.x - ground.width + 3, ground.y - ground.height - 10, 20, 20 )
	player:setFillColor( unpack( settings.colours.player ) )

	spear = display.newRect( groupBG, player.x, player.y, 50, 4 )
	spear:setFillColor( 0 )

	countdown = display.newRect( groupUI, screen.minX, screen.maxY, screen.width, 24 )
	countdown.anchorX, countdown.anchorY = 0, 1

	title = display.newText( groupUI, "Hold to charge. Release to throw.", screen.centreX, screen.minY + 4, "fonts/Roboto-Black.ttf", 40 )
	title.anchorY = 0
	title:setFillColor( unpack( settings.colours.b ) )

	local sensor = display.newRect( groupUI, screen.centreX, screen.centreY, screen.width, screen.height )
	sensor.isHitTestable = true
	sensor.isVisible = false
	sensor:addEventListener( "touch", throw )

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
