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
	{ 28, 615, 25, 442, 163, 418, 388, 408, 395, 467, 434, 471, 450, 436, 784, 436, 791, 459, 1950, 500, 1950, 614 },
}

local options =
{
    width = 129,
    height = 194,
    numFrames = 5
}

local imageSheet = graphics.newImageSheet( "assets/images/characters/child/child.png", options )

local sequenceData = {
    {
        name = "idle",
        frames = { 1 },
        time = 400,
        loopCount = 0,
        loopDirection = "forward"
    },
    {
        name = "bounce",
        frames = { 2, 3 },
        time = 400,
        loopCount = 0,
        loopDirection = "forward"
    },
    {
        name = "cry",
        frames = { 4, 5 },
        time = 400,
        loopCount = 0,
        loopDirection = "forward"
    },
}


---------------------------------------------------------------------------

-- Functions.



---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view

	dialogue.setParent( sceneGroup )


	background = display.newImage( sceneGroup, "assets/images/backgrounds/outside.png", screen.minX, screen.minY )
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


	object[1] = display.newSprite( sceneGroup, imageSheet, sequenceData )
	object[1]:setSequence( "bounce" )
	-- object[1].id = "child1"
	object[1]:play()
	object[1].x = 110
	object[1].y = 400
	object[1].xScale, object[1].yScale = 0.75, 0.75

	object[2] = display.newImage( sceneGroup, "assets/images/objects/ball_no_border.png", object[1].x + 25, object[1].y + 20 )
	-- object[2].id = "ball"
	object[2].xScale, object[2].yScale = 0.5, 0.5

	transition.to( object[2], { delay=150, time=400, y=object[2].y - 10, iterations=0, transition=easing.continuousLoop } )

	object[3] = display.newImage( sceneGroup, "assets/images/objects/brush_no_border.png", 810, 368 )
	object[3].xScale, object[3].yScale = 0.5, 1
	object[5] = display.newImage( sceneGroup, "assets/images/objects/brush_border.png", object[3].x, object[3].y )
	object[5].xScale, object[5].yScale = object[3].xScale, object[3].yScale
	object[5].alpha = 0

	object[4] = display.newRect( sceneGroup, 640, 350, 220, 140 )
	object[4].isVisible = false

	-- object[4].id = "bin"
	object[4].callback = function()
		player.suffix = ""
		player.stop()
		object[4].callback = nil

		timer.performWithDelay( 250, function()

			transition.cancel( object[2] )
			transition.to( object[2], { time=400, y=20, transition=easing.outQuart, onComplete=function()
				object[1]:setSequence( "cry" )
				object[1]:play()
				transition.to( object[2], { time=200, y=object[2].y + 118 } )
			end} )
			transition.to( object[2], { time=600, x=object[2].x + 600 } )

			timer.performWithDelay( 600, function()
				dialogue.new( "MY BALL!", "Child", function()
					dialogue.new( "*LOUD CRYING*", "Child", function()
						dialogue.new( "CAN YOU HELP ME GET MY BALL BACK?!", "Child", function()
							dialogue.new( "*MORE LOUD CRYING*", "Child", function()
								dialogue.new( "...", "Thought", function()
									dialogue.new( "... Yes.", "Me", function()
										dialogue.new( "Give me a second to figure this out.", "Me", function()

											object[1].callback = function()
												dialogue.new( "I should really help the kid get his ball back.", "Thought", function()

												end )
											end

											object[5].alpha = 1
											transition.to ( object[5], { time=1500, alpha=0, transition=easing.continuousLoop, iterations=0})

											object[3].callback = function()
												object[3].callback = nil

												dialogue.new( "I should be able to get the ball down with this.", "Thought", function()
													transition.cancel( object[5] )
													object[5].alpha = 0
													object[3].alpha = 0


													object[6] = display.newImage( sceneGroup, "assets/images/objects/ball_border.png", object[2].x, object[2].y )
													object[6].xScale, object[6].yScale = object[2].xScale, object[2].yScale
													transition.to ( object[6], { time=1500, alpha=0, transition=easing.continuousLoop, iterations=0})

													object[2].callback = function()
														object[2].callback = nil

														transition.cancel( object[6] )
														object[6].alpha = 0

														object[3]:toFront()

														object[3].alpha = 1
														object[3].x = object[2].x - 130
														object[3].y = object[2].y + 60
														object[3].anchorX, object[3].anchorY = 0, 0
														object[3].rotation = -90

														transition.to ( object[3], { time=500, rotation=-160, transition=easing.continuousLoop, iterations=4, onComplete=function()
															object[3].alpha = 0
															transition.to( object[2], { time=500, alpha=0, y=object[2].y + 30, transition=easing.inOutBack, onComplete=function()
																dialogue.new( "AARGH! MY BALL! IT'S GONE! YOU LOST MY BALL!", "Child", function()
																	dialogue.new( "Oops!", "Thought", function()
																		dialogue.new( "Umm... sorry about that...", "Me", function()
																			dialogue.new( "I better leave quick.", "Thought", function()
																				composer.gotoScene( "scenes.scene4_call_mom", { effect = "fade", time = 500 } )
																			end )
																		end )
																	end )
																end )
															end } )
														end })

													end
												end )
											end

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

	local roof = display.newImage( sceneGroup, "assets/images/objects/roof.png", 544, 119 )

	if not dialogueScene then
		player = playerCharacter.new( sceneGroup, 1720, 540, 1, "trash" )
		player.stop()
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