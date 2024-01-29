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

-- Dialogue scenes are scenes where the player character doesn't exist.
-- The entire scene is just a background image and series of dialogue.
local dialogueScene = true

local boundary = {
	-- { 19, 367, 100, 336, 201, 416, 294, 421, 543, 366, 898, 564, 897, 621, 24, 626 },
}



---------------------------------------------------------------------------

-- Functions.



---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view

	dialogue.setParent( sceneGroup )


	background = display.newImage( sceneGroup, "assets/images/backgrounds/home.png", screen.minX, screen.minY )
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

	-- object[1] = display.newImage( sceneGroup, "assets/images/objects/ball_border.png", 100, 100 )
	-- object[1].id = "ball"

	-- object[2] = display.newImage( sceneGroup, "assets/images/objects/ball_border.png", 1200, 100 )
	-- object[2].id = "ball2"

	local player = display.newImage( sceneGroup, "assets/images/characters/player/mcleft1phone.png", 510, 540 )
	player.anchorY = 1
	player.xScale, player.yScale = -1.5, 1.5


	local cover = display.newRect( sceneGroup, screen.minX, screen.minY, background.width, background.height )
	cover.anchorX, cover.anchorY = 0, 0
	cover:setFillColor( 0 )


	dialogue.new( "- Several days later -", "Time", function()

		transition.to( cover, {alpha = 0, time = 500, onComplete=function()

			dialogue.new( "Text from my mom.", "Thought", function()
				dialogue.new( "Hi!", "Mom", function()
					dialogue.new( "I forgot to buy a birthday greeting card for your sister.\nCould you go pick one up on your way here?", "Mom", function()
						dialogue.new( "Make sure it's not too distasteful.", "Mom", function()
							dialogue.new( "*Sigh*", "Thought", function()
								dialogue.new( "Yes. I'll go pick one up now.", "Me", function()
									dialogue.new( "Great! See you soon.", "Mom", function()
										dialogue.new( "I guess I'll head to the grocery store to pick up a card then...", "Thought", function()

											-- Map: grocery
											composer.gotoScene( "scenes.map", {params = {
												player = "character_map",
												destination = "shop",
												xStart = 340,
												yStart = 144,
												xDestination = 344,
												yDestination = 319,
												nextScene = "scene5_grocery"
											}} )

										end )
									end )
								end )
							end )
						end )
					end )
				end )
			end )

		end } )


	end )




	if not dialogueScene then
		player = playerCharacter.new( sceneGroup, 400, 600, 1.5, "idle" )
	end
end

---------------------------------------------------------------------------

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		if not dialogueScene and background.width > display.actualContentWidth then
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