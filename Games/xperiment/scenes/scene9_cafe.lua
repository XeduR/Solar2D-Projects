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
	{ 63, 614, 63, 562, 302, 407, 511, 406, 510, 495, 557, 535, 634, 552, 695, 558, 788, 556, 864, 544, 927, 527, 946, 473, 948, 413, 1157, 415, 1250, 617 },
}



---------------------------------------------------------------------------

-- Functions.



---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view

	dialogue.setParent( sceneGroup )


	background = display.newImage( sceneGroup, "assets/images/backgrounds/cafeinside.png", screen.minX, screen.minY )
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

	object[1] = display.newImage( sceneGroup, "assets/images/characters/friend/friendsitting.png", 620, 360 )
	-- object[1].id = "ball"

	object[2] = display.newImage( sceneGroup, "assets/images/characters/barista/barista_border.png", 1341, 185 )
	object[2].alpha = 0
	-- object[2].id = "ball2"

	object[3] = display.newImage( sceneGroup, "assets/images/objects/soda.png", 730, 325 )

	object[4] = display.newImage( sceneGroup, "assets/images/objects/game_no_border.png", 90, 325 )
	object[5] = display.newImage( sceneGroup, "assets/images/objects/game_border.png", object[4].x, object[4].y )
	object[5].alpha = 0

	object[6] = display.newRect( sceneGroup, 740, 355, 240, 200 )
	object[6].alpha = 0

	object[7] = display.newImage( sceneGroup, "assets/images/characters/friend/friendcleaning.png", 850, 334 )
	object[7].alpha = 0

	local cover = display.newRect( sceneGroup, screen.minX, screen.minY, background.width, background.height )
	cover.anchorX, cover.anchorY = 0, 0
	cover:setFillColor( 0 )

	dialogue.new( "Oh, come on! I can't believe I managed to step into the only puddle in the entire town...", "Thought", function()

		transition.to( cover, {alpha = 0, time = 500, onComplete=function()

			dialogue.new( "Hey, Me! Grab a game from the shelf and let's play!", "Jo", function()
				object[5].alpha = 1
				transition.to ( object[5], { time=1500, alpha=0, transition=easing.continuousLoop, iterations=0})

				object[5].callback = function()
					dialogue.new( "I guess this looks good.", "Thought", function()
						transition.cancel( object[5] )
						object[4].alpha = 0
						object[5].alpha = 0
						object[5].callback = nil

						dialogue.new( "Awesome! Bring it over!", "Jo", function()
							object[6].callback = function()
								object[6].callback = nil
								object[4].alpha = 1
								object[4].x, object[4].y = 740, 325

								transition.to( object[3], { time=1200, x=object[3].x - 150, y = object[3].y + 200, rotation=-420, transition=easing.outQuart, onComplete=function()
									dialogue.new( "Oh no!", "Me", function()
										dialogue.new( "I can't believe I just spilled Jo's drink all over the table!", "Thought", function()
											dialogue.new( "Don't worry about it, Em.", "Jo", function()
												dialogue.new( "Why don't you get us both new drinks while I clean this up?", "Jo", function()
													object[1].alpha = 0
													object[7].alpha = 1

													dialogue.new( "...sure.", "Me", function()
														object[2].alpha = 1
														transition.to ( object[2], { time=1500, alpha=0, transition=easing.continuousLoop, iterations=0})

														object[2].callback = function()
															object[2].callback = nil
															object[2].alpha = 0

															dialogue.new( "Um... could I get two drinks, please?", "Me", function()
																dialogue.new( "Coming right up.", "Me", function()

																	transition.to( cover, {alpha = 1, time = 350, onComplete=function()
																		transition.cancel( object[5] )
																		object[1].alpha = 1
																		object[3].alpha = 0
																		object[5].alpha = 0
																		object[7].alpha = 0

																		transition.to( cover, {alpha = 0, time = 250, onComplete=function()
																			dialogue.new( "Here you go.", "Me", function()
																				object[6].callback = function()
																					object[6].callback = nil

																					dialogue.new( "Alright! Ready to play?", "Jo", function()
																						dialogue.new( "Yes.", "Me", function()
																							composer.gotoScene( "scenes.scene10_therapy", { effect = "fade", time = 500 } )
																						end )
																					end )
																				end

																			end )
																		end } )
																	end } )

																end )
															end )
														end

													end )
												end )
											end )
										end )
									end )
								end } )
							end
						end )

					end )
				end
			end )
		end } )

	end )


	-- Map: therapy (end) [NOT USED]
	-- composer.gotoScene( "scenes.map", {params = {
	-- 	player = "character_map",
	-- 	destination = "therapy",
	-- 	xStart = 340,
	-- 	yStart = 144,
	-- 	xDestination = 660,
	-- 	yDestination = 490,
	-- 	nextScene = "scene10_therapy"
	-- }} )

	if not dialogueScene then
		player = playerCharacter.new( sceneGroup, 400, 600, 1.6, "idle" )
		player.xScale = -player.xScale
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