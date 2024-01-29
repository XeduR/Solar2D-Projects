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
	{ 19, 367, 100, 336, 201, 416, 294, 421, 543, 366, 898, 564, 897, 621, 24, 626 },
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

	object[1] = display.newImage( sceneGroup, "assets/images/objects/laptop_border.png", 801, 229 )
	-- object[1].id = "laptop"
	transition.to ( object[1], { time=1500, alpha=0, transition=easing.continuousLoop, iterations=0})

	local trash = display.newImage( sceneGroup, "assets/images/objects/trashbag.png", 240, 400 )

	object[2] = display.newImage( sceneGroup, "assets/images/objects/trashbag_border.png", trash.x, trash.y )
	-- object[2].id = "trash"
	object[2].alpha = 0

	if not dialogueScene then
		player = playerCharacter.new( sceneGroup, 400, 600, 1.5, "idle" )
	end


	object[1].callback = function()
		local computer = display.newImage( sceneGroup, "assets/images/backgrounds/reminder.png", screen.minX, screen.minY )
		computer.anchorX, computer.anchorY = 0, 0

		dialogue.new( "\"Remember to take out the trash.\"", "Thought", function()
			dialogue.new( "Sometimes I wonder why I set reminders for myself that I then have to remember.", "Thought", function()
				dialogue.new( "Well, better take out the trash then.", "Thought", function()
					transition.cancel( object[1] )
					object[1].alpha = 0
					object[1].callback = nil

					display.remove( computer )

					object[2].alpha = 1
					transition.to ( object[2], { time=1500, alpha=0, transition=easing.continuousLoop, iterations=0})

					object[2].callback = function()
						composer.gotoScene( "scenes.scene3_trash", { effect = "fade", time = 500 } )
					end
				end )
			end )
		end )
	end


	dialogue.new( "Finally. I'm back home.", "Thought", function()
		dialogue.new( "There was something I was supposed to do... what was it?", "Thought", function()
		end )
	end )

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