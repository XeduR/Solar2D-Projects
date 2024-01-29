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

	background = display.newImage( sceneGroup, "assets/images/backgrounds/therapy_start.png", screen.minX, screen.minY )
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


	dialogue.new( "We've been seeing each other for quite a while now, Me.", "Therapist", function()
		dialogue.new( "How about we try something different for a change? And experiment, if you will.", "Therapist", function()
			dialogue.new( "What's that?", "Me", function()
				dialogue.new( "Before our session next month, I want you to try something entirely different.", "Therapist", function()
					dialogue.new( "Most of us try to stay where it's familiar and not stressful, but by doing so, overtime we may close ourselves from the outside world.", "Therapist", function()
						dialogue.new( "For the next 30 days, I want you to try to say \"Yes\" to things you'd normally say \"no\" to.", "Therapist", function()
							dialogue.new( "Like in that movie?", "Me", function()
								dialogue.new( "Well, no. Not quite.", "Therapist", function()
									dialogue.new( "Let's not get ahead of ourselves. Try not to do anything too stressful.", "Therapist", function()
										dialogue.new( "I simply want you to try to do things, small things, that will test your boundaries a bit. I want you to try to say \"yes\" to small things.", "Therapist", function()
											dialogue.new( "Things that you normally might not do because it might require you to put yourself out there or interact with others outside of your home.", "Therapist", function()
												dialogue.new( "I... I guess I can give it a try.", "Me", function()
													dialogue.new( "Great! And remember, don't try to be too hard on yourself.", "Therapist", function()
														dialogue.new( "...I'll try.", "Me", function()
															composer.gotoScene( "scenes.scene2_home", { effect = "fade", time = 500 } )
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
		end )
	end )

	if not dialogueScene then
		player = playerCharacter.new( sceneGroup, 400, 600, 1, "idle" )
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