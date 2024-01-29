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
local dialogueScene = false

local boundary = {
	{ 21, 616, 25, 491, 1053, 495, 1035, 617 },
}



---------------------------------------------------------------------------

-- Functions.



---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view

	dialogue.setParent( sceneGroup )


	background = display.newImage( sceneGroup, "assets/images/backgrounds/walk.png", screen.minX, screen.minY )
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

	object[1] = display.newImage( sceneGroup, "assets/images/characters/oldman/oldman_no_border.png", 1200, 600 )
	object[1].anchorY = 1
	-- object[1].id = "oldman"

	object[2] = display.newImage( sceneGroup, "assets/images/characters/oldman/oldman_border.png", object[1].x, object[1].y )
	object[2].anchorY = 1
	transition.to ( object[2], { time=1500, alpha=0, transition=easing.continuousLoop, iterations=0})
	-- object[1].id = "oldman"

	object[1].callback = function()

		dialogue.new( "Excuse me, miss. Could I bother you for a second?", "Oldman", function()
			dialogue.new( "...yes, what's up?", "Me", function()
				dialogue.new( "I'm on my way to my friend's house, but I seem to have lost my way.", "Oldman", function()
					dialogue.new( "What's the address? I can check the route from my phone.", "Me", function()
						dialogue.new( "Oh, that would be wonderful.", "Oldman", function()
							dialogue.new( "*She shows him the map on her phone.*", "Thought", function()
								dialogue.new( "Oh, dear. I don't think I can remember all of that and I don't have a phone. Could you lead me there?", "Oldman", function()
									dialogue.new( "...", "Me", function()
										dialogue.new( "...yes.", "Me", function()
											dialogue.new( "Really!? Are you sure it won't be any trouble?", "Oldman", function()
												dialogue.new( "...yes, no trouble. Let's go.", "Me", function()
													dialogue.new( "Oh, wonderful!", "Oldman", function()

														-- Map: walk - bring oldman home
														composer.gotoScene( "scenes.map", {params = {
															player = "character_and_oldman",
															destination = "destination",
															xStart = 150,
															yStart = 130,
															xDestination = 824,
															yDestination = 550,
															nextScene = "scene7_return"
														}} )

													end )
												end )
											end )
										end )
									end )
								end )
							end )
						end )
					end )
				end )
			end )
		end )

	end




	if not dialogueScene then
		player = playerCharacter.new( sceneGroup, 140, 600, 1, "idle" )
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