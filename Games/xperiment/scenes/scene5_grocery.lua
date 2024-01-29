local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Developer only: require only when creating boundaries for scenes.
if system.getInfo( "environment" ) == "simulator" then
	-- require( "widgets.devBoundaryTool" )
end

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local playerAction = require("classes.playerAction")
local playerCharacter = require("classes.playerCharacter")
local camera = require("classes.camera")
local dialogue = require("classes.dialogue")

---------------------------------------------------------------------------

-- Forward declarations & variables.
local background = nil
local player = nil
local object = {} -- Table containing all interactable objects in the scene.
local card = {}
local chosenCard = nil

-- Dialogue scenes are scenes where the player character doesn't exist.
-- The entire scene is just a background image and series of dialogue.
local dialogueScene = false

local boundary = {
	{ 15, 589, 679, 584, 699, 605, 937, 598, 953, 645, 5, 645 },
}



---------------------------------------------------------------------------

-- Functions.
local function gotoScene()
	dialogue.remove()

	-- Map: walk - return home
	composer.gotoScene( "scenes.map", {params = {
		player = "character_map",
		destination = "destination",
		xStart = 344,
		yStart = 319,
		xDestination = 340,
		yDestination = 144,
		nextScene = "scene5_call_mom2",
	}} )
end

local function selectCard( event )
	if event.phase == "ended" then
		dialogue.remove()

		if chosenCard then
			for i = 1, 3 do
				card[i]:removeEventListener( "touch", selectCard )
			end

			-- dialogue.remove()

			if event.target.id == chosenCard then
				dialogue.new( "Yes. This is it.", "Thought", function()
					dialogue.remove()
					gotoScene()
				end )
			else
				dialogue.new( "Yes. I'll take the first one I thought of.", "Thought", function()
					dialogue.remove()
					gotoScene()
				end )
			end

		else
			for i = 1, 3 do
				if card[i].id ~= event.target.id then
					card[i].alpha = 0.5
				else
					chosenCard = i
				end
			end

			dialogue.new( "Are you sure this is the right card for your sister?", "Thought", function()
				dialogue.remove()
			end )

			local yes = display.newText({
				parent = scene.view,
				text = "\"Yes!\"",
				x = card[chosenCard].x,
				y = card[chosenCard].y + card[chosenCard].height*0.4,
				width = 200,
				font = "assets/fonts/JosefinSlab-Bold.ttf",
				fontSize = 48,
				align = "center"
			})

			transition.to( yes, { time=750, xScale=1.25, yScale=1.25, transition=easing.continuousLoop, iterations=0})
		end
	end
	return true
end

---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view

	dialogue.setParent( sceneGroup )


	background = display.newImage( sceneGroup, "assets/images/backgrounds/grocery.png", screen.minX, screen.minY )
	background.anchorX, background.anchorY = 0, 0

	-- Draw debug boundaries, if used.
	if boundary and system.getInfo( "environment" ) == "simulator" then
		for i = 1, #boundary do
			for j = 1, #boundary[i] - 2, 2 do
				local line = display.newLine( sceneGroup, boundary[i][j], boundary[i][j + 1], boundary[i][j + 2], boundary[i][j + 3] )
				line:setStrokeColor( 1, 0.35 )
			end

			-- Connect the start and end.
			local line = display.newLine( sceneGroup, boundary[i][1], boundary[i][2], boundary[i][#boundary[i]-1], boundary[i][#boundary[i]] )
			line:setStrokeColor( 1, 0.35 )
		end

	end

	object[1] = display.newImage( sceneGroup, "assets/images/objects/cardstand_border.png", 790, 453 )
	object[1].id = "cardstand"
	transition.to ( object[1], { time=1500, alpha=0, transition=easing.continuousLoop, iterations=0})


	dialogue.new( "Alright, now to pick up that card.", "Thought", function()
		-- dialogue.new( "Hi!", "Mom", function()
		-- 	dialogue.new( "I forgot to buy a birthday greeting card for your sister.\nCould you go pick one up on your way here?", "Mom", function()
		-- 		dialogue.new( "Make sure it's not too distasteful.", "Mom", function()
		-- 			dialogue.new( "*Sigh*", "Thought", function()
		-- 				dialogue.new( "Yes. I'll go pick one up now.", "Me", function()
		-- 					dialogue.new( "Great! See you soon.", "Mom", function()
		-- 						dialogue.new( "I guess I'll head to the grocery store to pick up a card then...", "Thought", function()

		-- 							-- Map: grocery
		-- 							composer.gotoScene( "scenes.map", {params = {
		-- 								player = "character_map",
		-- 								destination = "shop",
		-- 								xStart = 340,
		-- 								yStart = 144,
		-- 								xDestination = 344,
		-- 								yDestination = 319,
		-- 								nextScene = "scene5_grocery"
		-- 							}} )

		-- 						end )
		-- 					end )
		-- 				end )
		-- 			end )
		-- 		end )
		-- 	end )
		-- end )
	end )

	object[1].callback = function()
		playerAction.stop()

		local cover = display.newRect( sceneGroup, screen.centerX, screen.centerY, screen.width, screen.height )
		cover:setFillColor( 0, 0.85 )


		for i = 1, 3 do
			card[i] = display.newImage( sceneGroup, "assets/images/objects/bdaycard" .. i ..".png", 220 + (i-1)*260, screen.centerY )
			card[i]:addEventListener( "touch", selectCard )
			card[i].id = i
		end

		dialogue.new( "Let's see... which one should I pick?", "Thought", function()

		end )
	end

	if not dialogueScene then
		player = playerCharacter.new( sceneGroup, 560, 630, 1.75, "idle" )
		player.xScale = -1*player.xScale
	end
end

---------------------------------------------------------------------------

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		if  not dialogueScene and background.width > display.actualContentWidth then
			camera.start( player, sceneGroup, background )
		end

	elseif event.phase == "did" then
		if not dialogueScene then
			playerAction.start( player, object, sceneGroup, boundary )
		end

	end
end

---------------------------------------------------------------------------

function scene:hide( event )
	if event.phase == "will" then
		playerAction.stop()
		camera.stop()

	end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

---------------------------------------------------------------------------

return scene