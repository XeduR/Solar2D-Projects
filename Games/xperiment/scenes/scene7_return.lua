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


	background = display.newImage( sceneGroup, "assets/images/backgrounds/map.png", screen.minX, screen.minY )
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

	local cover = display.newRect( sceneGroup, screen.centerX, screen.centerY, screen.width, screen.height )
	cover:setFillColor( 0, 0.75 )

	-- object[1] = display.newImage( sceneGroup, "assets/images/objects/ball_border.png", 100, 100 )
	-- object[1].id = "ball"

	-- object[2] = display.newImage( sceneGroup, "assets/images/objects/ball_border.png", 1200, 100 )
	-- object[2].id = "ball2"

	dialogue.new( "Oh that was quite a journey, wasn't it!?", "Oldman", function()
		dialogue.new( "...yes. Yes it was.", "Me", function()
			dialogue.new( "And to think it didn't take a more than 40 minutes.", "Oldman", function()
				dialogue.new( "Yeah, so, anyway...", "Me", function()
					dialogue.new( "You know, most youths these days wouldn't escort an old man like this. They just sit at home and play their video games.", "Oldman", function()
						dialogue.new( "*I'm spacing out.*", "Thought", function()
							dialogue.new( "When I was young, we used to take our elderly to the next town and back...", "Oldman", function()
								dialogue.new( "...I must be off now.", "Me", function()

									-- Map: home
									composer.gotoScene( "scenes.map", {params = {
										player = "character_map",
										destination = "destination",
										xStart = 824,
										yStart = 550,
										xDestination = 340,
										yDestination = 144,
										nextScene = "scene8_call_sales"
									}} )

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