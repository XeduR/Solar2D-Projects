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

local mask = graphics.newMask( "images/mask.png" )
local sceneGroupRef

local playerA, playerB, father, mother, nurse

local speechBubble, speechBubblePiece, dialogueActive, speech

local groupUI = display.newGroup()
local groupGame = display.newGroup()
local groupBG = display.newGroup()

-------------------------------------------------------------------------------

local horizonOffset = 80

-------------------------------------------------------------------------------


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


local function goToGame( t, isTrap )
	physics.pause()
	G_block.isHitTestable = true

	composer.gotoScene( "scenes.yard", { params = { newGame = true, repeating = true } } )
end


local function dialogueFunction( target, text )
	clearDialogue()
	dialogueActive = true

	speechBubble = display.newRoundedRect( groupUI, target.x + target.width*0.5 + 10, target.y - target.height - 20, 400, 200, 16 )
	speechBubble.anchorX, speechBubble.anchorY = 0, 1

	speechBubblePiece = display.newRoundedRect( groupUI, speechBubble.x, speechBubble.y, 40, 20, 16 )
	speechBubblePiece.rotation = -45

	local options =
	{
	    text = text,
	    x = speechBubble.x + 20,
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
end


local function catapultBaby( reset )
	if reset then
		GLOBAL_FIX.money = 0
		GLOBAL_FIX.month = 1
		G_money.text = "$0"
		G_month.text = "Month 1"
	end
	clearDialogue()
	physics.start()
	sfx.play()
	playerA:applyLinearImpulse( 80, -25 )
	timer.performWithDelay( 1000, goToGame )
end


local function dadDialogueBirth()
	father:bounce()
	sfx.play()
	-- dialogueFunction( father, dialogue.father.birth.start[math.random(1,#dialogue.father.birth.start)] )
	dialogueFunction( father, dialogue.father.birth.start[math.random(1,3)] )
	timer.performWithDelay( 4000, function()
		father:bounce()
		sfx.play()
		dialogueFunction( father, "Everybody starts from nothing and there is no better time to start than now, so go get a job!" )
		timer.performWithDelay( 3000, catapultBaby )
	end )
end


local function newGame( newRound )
	if not newRound then
		timer.performWithDelay( 500, function()
			nurse:bounce()
			sfx.play()
			dialogueFunction( nurse, "Congratulations! It's a..." )
			transition.to( playerA, {time=2500, x=playerA.x + 70, onComplete=dadDialogueBirth })
		end )
	else

	end
end


local function talkToNewBaby()
	playerA:bounce()
	sfx.play()

	timer.performWithDelay( 3500, function()
		father:bounce()
		sfx.play()
		dialogueFunction( father, "Don't let me down like you older sibling did! Now, go get a a job!" )
		transition.to( playerA, {time=2500, x=playerA.x + 70, onComplete=function() catapultBaby( true ) end  })
	end )
end


local function checkScore()
	playerB:bounce()
	father:bounce()
	sfx.play()
	dialogueFunction( father, "So, you managed to earn $" .. GLOBAL_FIX.money .. " in by the time you were 12 months old..." )

	timer.performWithDelay( 2500, function()
		playerB:bounce()
		father:bounce()
		sfx.play()
		-- dialogueFunction( father, dialogue.father.gameover.finish[math.random(1,#dialogue.father.gameover.finish)] )
		dialogueFunction( father, dialogue.father.gameover.finish[math.random(1,3)] )
		timer.performWithDelay( 2000, talkToNewBaby )
	end )
end



local function gameover()
	playerB:bounce()
	sfx.play()

	timer.performWithDelay( 500, function()
		playerB:bounce()
		father:bounce()
		sfx.play()
		dialogueFunction( father, dialogue.father.gameover.start[math.random(1,3)] )
		-- dialogueFunction( father, dialogue.father.gameover.start[math.random(1,#dialogue.father.gameover.start)] )
		timer.performWithDelay( 2500, checkScore )
	end )
end


-------------------------------------------------------------------------------

local scene = composer.newScene()

function scene:create( event )
	local sceneGroup = self.view
	sceneGroupRef = sceneGroup
	physics.start()
	physics.pause()

	father = newCharacter.add( groupGame, 410, 410, 80, 80 )
	mother = newCharacter.add( groupGame, 260, 410, 60, 70 )
	nurse = newCharacter.add( groupGame, 320, 410, 60, 60 )
	nurse:setFillColor( unpack( settings.colours.b ) )

	playerA = newCharacter.add( groupGame, screen.centreX - 80, screen.centreY, 20, 20 )
	playerA:setFillColor( unpack( settings.colours.player ) )
	physics.addBody( playerA, "dynamic", {density=7, bounce=0.4, friction=0.4 } )

	local sky = display.newRect( groupBG, screen.centreX, screen.centreY, screen.width, screen.height )
	sky:setFillColor( unpack( settings.colours.sky ) )

	local building = display.newRect( groupBG, playerA.x, playerA.y, 420, screen.height*2 )
	building:setFillColor( 0 )

	local window1 = display.newRect( groupBG, playerA.x + 120, playerA.y + 200, 120, 80 )
	window1:setFillColor( 0.63, 0.85, 0.92, 0.5 )

	local window2 = display.newRect( groupBG, playerA.x - 120, playerA.y + 200, 120, 80 )
	window2:setFillColor( 0.63, 0.85, 0.92, 0.5 )

	local window1 = display.newRect( groupBG, playerA.x + 120, playerA.y - 240, 120, 80 )
	window1:setFillColor( 0.63, 0.85, 0.92, 0.5 )

	local window2 = display.newRect( groupBG, playerA.x - 120, playerA.y - 240, 120, 80 )
	window2:setFillColor( 0.63, 0.85, 0.92, 0.5 )

	local wall = display.newRect( groupBG, playerA.x, playerA.y, 400, 220 )
	wall:setFillColor( unpack( settings.colours.ground ) )

	local door = display.newRect( groupBG, playerA.x + 80, playerA.y + 40, 100, 120 )
	door:setFillColor( 0, 0, 0, 0.7 )

	playerB = newCharacter.add( groupGame, door.x, door.y + door.height*0.5 - 10, 24, 24 )
	playerB:setFillColor( unpack( settings.colours.player ) )

	local ceiling = display.newRect( groupBG, playerA.x, playerA.y - 100, 400, 20 )
	ceiling:setFillColor(0)

	local floor = display.newRect( groupBG, playerA.x, playerA.y + 100, 400, 20 )
	floor:setFillColor(0)

	local wallLeft = display.newRect( groupBG, playerA.x - 200, playerA.y, 20, 240 )
	wallLeft:setFillColor(0)

	local wallRight = display.newRect( groupBG, playerA.x + 200, playerA.y, 20, 240 )
	wallRight:setFillColor(0)

	local window = display.newRect( groupBG, playerA.x + 200, playerA.y - 10, 20, 80 )
	window:setFillColor( unpack( settings.colours.sky ) )

	sceneGroup:insert( groupBG )
	sceneGroup:insert( groupGame )
	sceneGroup:insert( groupUI )
end


function scene:show( event )
	if event.phase == "will" then
		G_performance.isVisible = false

		if event.params and event.params.gameLaunched then
			playerB.isVisible = false
		else
			playerB.isVisible = true
		end
		playerA.x, playerA.y = screen.centreX - 180, screen.centreY + 70

	elseif event.phase == "did" then
		if event.params and event.params.gameLaunched then
			newGame()
		else
			playerA.y = playerA.y - 15
			playerA:setLinearVelocity( 0, 0 )
			playerA.angularVelocity = 0
			gameover()
		end
	end
end

-------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

-------------------------------------------------------------------------------

return scene
