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
local dialogue = require( "data.dialogue" )
local newCharacter = require( "scripts.newCharacter" )
local physics = physics or require("physics")
local sfx = require( "scripts.sfx" )

local gameLaunched = false
local mask = graphics.newMask( "images/mask.png" )
local sceneGroupRef
local player, floor, title, countdown, ctTime, bounceTimer, getJobs
local speechBubble, speechBubblePiece, dialogueActive, speech, speechYes, speechNo
local job = {}

local groupUI = display.newGroup()
local groupGame = display.newGroup()
local groupBG = display.newGroup()

-------------------------------------------------------------------------------

local horizonOffset = 80

-------------------------------------------------------------------------------

local lastNotified = 1
local function notify()
	if not dialogueActive then
		local which = math.random(1,3)
		while which == lastNotified do
			which = math.random(1,3)
		end
		lastNotified = which
		job[which]:bounce()
	end
end


local function clearJobs()
	for i = 1, 3 do
		display.remove( job[i] )
		job[i] = nil
	end
end


local function clearDialogue()
	if speechBubble then
		dialogueActive = false
		display.remove( speechBubble )
		display.remove( speechBubblePiece )
		display.remove( speechYes )
		display.remove( speechNo )
		display.remove( speech )
		speechBubble = nil
		speechBubblePiece = nil
		speechYes = nil
		speechNo = nil
		speech = nil
	end
end


local bg, text, updateTimer, startTime
local function resume( event )
	if event.phase == "ended" then
		display.remove( bg )
		display.remove( text )
		bg = nil
		text = nil
		sfx.play()

		if GLOBAL_FIX.month >= 13 then
			G_block.isHitTestable = true
			timer.cancel( bounceTimer )
			Runtime:removeEventListener( "enterFrame", updateTimer )
			physics.pause()
			clearDialogue()
			clearJobs()

			display.remove( floor )
			floor = nil

			GLOBAL_FIX.gotoScene( "scenes.calendar" )
		else
			bounceTimer = timer.performWithDelay( 1250, notify, 0 )

			countdown.xScale = 1
			startTime = system.getTimer()
			Runtime:addEventListener( "enterFrame", updateTimer )
		end
	end
	return true
end


local function skipMonth()
	timer.cancel( bounceTimer )

	bg = display.newRect( groupUI, screen.centreX, screen.centreY, screen.width, screen.height )
	bg:addEventListener( "touch", resume )
	bg:setFillColor(0)

	clearDialogue()
	clearJobs()
	getJobs()

	ctTime = settings.countdownTime

	text = display.newText( groupUI, "You waited too long and you\ndidn't work at all this month!", screen.centreX, screen.centreY, "fonts/Roboto-Black.ttf", 48 )
	GLOBAL_FIX.month = GLOBAL_FIX.month + 1
	G_month.text = "Month " .. GLOBAL_FIX.month
end

function updateTimer()
	local ratio = 1 - (system.getTimer() - startTime) / ctTime

	if ratio > 0 then
		countdown.xScale = ratio
	else
		Runtime:removeEventListener( "enterFrame", updateTimer )
		skipMonth()
	end
end




local function goToGame( t, isTrap )
	G_block.isHitTestable = true
	timer.cancel( bounceTimer )
	Runtime:removeEventListener( "enterFrame", updateTimer )
	physics.pause()
	clearDialogue()

	display.remove( floor )
	floor = nil
	sfx.play()

	sceneGroupRef:setMask( mask )
	sceneGroupRef.maskX = player.x
	sceneGroupRef.maskY = player.y
	sceneGroupRef.maskScaleX = GLOBAL_FIX.scaleMaskTo
	sceneGroupRef.maskScaleY = GLOBAL_FIX.scaleMaskTo

	transition.to( sceneGroupRef, { delay=settings.mask.hideDelay, time=settings.mask.hideTime, transition=settings.mask.hideEasing, maskScaleX=0.01, maskScaleY=0.01, onComplete=function()
			clearJobs()

			if isTrap then
				composer.gotoScene( "scenes.traps." .. t.target )
			else
				G_performance.text = "$0 - 100%"
				G_performance.isVisible = true
				composer.gotoScene( "scenes.games." .. t.target )
			end
		end
	})
end


local function bgTouch( event )
	if event.phase == "began" then
		sfx.play()
		clearDialogue()
	end
end

local function dialogueFunction( event )
	if event.phase == "began" then
		clearDialogue()
		dialogueActive = true

		speechBubble = display.newRoundedRect( groupUI, event.target.x - event.target.width*0.5 - 10, event.target.y - event.target.height - 20, 400, 200, 16 )
		speechBubble.anchorX, speechBubble.anchorY = 1, 1

		speechBubblePiece = display.newRoundedRect( groupUI, speechBubble.x, speechBubble.y, 40, 20, 16 )
		speechBubblePiece.rotation = 45

		local options =
		{
		    text = dialogue.jobs[event.target.target][math.random(1,3)],
		    -- text = (dialogue.jobs[event.target.target] and dialogue.jobs[event.target.target][math.random(1,#dialogue.jobs[event.target.target])]) or "No text.",
		    x = speechBubble.x - speechBubble.width + 20,
		    y = speechBubble.y - speechBubble.height + 10,
		    width = speechBubble.width - 20,
		    font = "fonts/Roboto-Regular.ttf",
		    fontSize = 34,
		    align = "left"
		}

		speech = display.newText( options )
		speech.anchorX, speech.anchorY = 0, 0
		groupUI:insert( speech )
		speech:setFillColor( unpack( settings.colours.ground ) )

		speechYes = display.newText( groupUI, "Yes", speechBubble.x - 20, speechBubble.y - 10, "fonts/Roboto-Black.ttf", 40 )
		speechYes.anchorX, speechYes.anchorY = 1, 1
		speechYes:setFillColor( unpack( settings.colours.b ) )
		speechYes:addEventListener( "touch", function() goToGame( event.target, event.target.isTrap ) end )

		speechNo = display.newText( groupUI, "No", speechYes.x - speechYes.width - 60, speechYes.y, "fonts/Roboto-Black.ttf", 40 )
		speechNo.anchorX, speechNo.anchorY = 1, 1
		speechNo:setFillColor( unpack( settings.colours.b ) )
		speechNo:addEventListener( "touch", bgTouch )
	end
end

function getJobs()
	-- local firstJob = math.random( 1, #composer.gameModes )
	local firstJob = math.random( 1, 5 )

	local secondJob = firstJob
	while firstJob == secondJob do
		-- secondJob = math.random( 1, #composer.gameModes )
		secondJob = math.random( 1, 5 )
	end

	-- local trap = #composer.gameModes + math.random( 1, #composer.traps )
	local trap = #GLOBAL_FIX.gameModes + math.random( 1, 2 )

	local availableJobs = {}
	availableJobs[1] = firstJob
	availableJobs[2] = secondJob
	availableJobs[3] = trap

	-- for i = #availableJobs, 2, -1 do
	-- 	local j = math.random(0,i)
	-- 	availableJobs[i], availableJobs[j] = availableJobs[j], availableJobs[i]
	-- end

	for i = 1, 3 do
		job[#job+1] = newCharacter.add( groupGame, 320 + (#job+1)*160 + math.random( -20,20 ), screen.centreY+horizonOffset + math.random( 10, 30 ), 80 + math.random( -10,10 ), 80 + math.random( -10,10 ), availableJobs[i], dialogueFunction )
	end

end

-------------------------------------------------------------------------------

local scene = composer.newScene()

function scene:create( event )
	local sceneGroup = self.view
	sceneGroupRef = sceneGroup
	physics.start()
	physics.pause()

	local sky = display.newRect( groupBG, screen.centreX, screen.centreY+horizonOffset, screen.width, screen.height*0.5+horizonOffset )
	sky:setFillColor( unpack( settings.colours.sky ) )
	sky.anchorY = 1
	sky:addEventListener( "touch", bgTouch )

	local ground = display.newRect( groupBG, screen.centreX, screen.centreY+horizonOffset, screen.width, screen.height*0.5-horizonOffset )
	ground:setFillColor( unpack( settings.colours.ground ) )
	ground.anchorY = 0
	ground:addEventListener( "touch", bgTouch )

	player = display.newRect( groupGame, screen.minX - 120, 0, 20, 20 )
	player:setFillColor( unpack( settings.colours.player ) )
	physics.addBody( player, "dynamic", {density=7, bounce=0.4, friction=0.4 } )

	countdown = display.newRect( groupUI, screen.minX, screen.maxY, screen.width, 24 )
	countdown.anchorX, countdown.anchorY = 0, 1

	title = display.newText( groupUI, "Get A Job, Baby!", screen.centreX, screen.minY - 240, "fonts/Roboto-Black.ttf", 64 )
	title:setFillColor( unpack( settings.colours.b ) )

	sceneGroup:insert( groupBG )
	sceneGroup:insert( groupGame )
	sceneGroup:insert( groupUI )
end


function scene:show( event )
	if event.phase == "will" then
		G_performance.isVisible = false

		floor = display.newRect( groupUI, screen.centreX, screen.centreY+horizonOffset+100, screen.width*2, 20 )
		physics.addBody( floor, "static", { bounce=0.25, friction=0.4 } )
		floor.isVisible = false

		getJobs()
		if event.params and event.params.newGame then
			title.y = screen.minY - 240
		end

	elseif event.phase == "did" then
		physics.start()
		player.x = screen.minX - 120
		player:setLinearVelocity( 0, 0 )
		player.angularVelocity = 0
		sceneGroupRef:setMask( nil )

		if event.params and event.params.newGame then
			transition.to( title, { time=1000, y=screen.minY + title.height*0.5, transition=easing.inOutBack })

			player.y = screen.minY
			player:setLinearVelocity( 120 + math.random(0,20), -4 - math.random(0,10) )
			player.angularVelocity = 30 + math.random(-5,5)

			ctTime = settings.countdownTimeGameStarted
		else
			ctTime = settings.countdownTime
			player.y = floor.y - floor.height - 20
			player:setLinearVelocity( 370 + math.random(-20,20), -16 - math.random(0,10))
		end

		countdown.xScale = 1

		timer.performWithDelay( 500, function()
			G_block.isHitTestable = false
			bounceTimer = timer.performWithDelay( 1250, notify, 0 )
			startTime = system.getTimer()
			Runtime:addEventListener( "enterFrame", updateTimer )
		end)
	end
end

-------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

-------------------------------------------------------------------------------

return scene
