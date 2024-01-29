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


	local cover = display.newRect( sceneGroup, screen.centerX, screen.centerY, screen.width, screen.height )
	cover:setFillColor( 0 )


	local function invite()

		dialogue.new( "*Ring ring!*", "Thought", function()
			dialogue.new( "Oh no, someone is calling me again. This is twice in one week.", "Thought", function()
				dialogue.new( "*Existential dread spreads again.*", "Thought", function()
					dialogue.new( "Oh, it's Jo.", "Me", function()
						dialogue.new( "*Existential dread continues to spread.*", "Thought", function()
							dialogue.new( "Hi, Jo!", "Me", function()
								dialogue.new( "Me! How's it hanging!?", "Jo", function()
									dialogue.new( "...I'm fine.", "Me", function()
										dialogue.new( "Hey, wanna come play boardgames at the cafe?", "Jo", function()
											dialogue.new( "...", "Me", function()
												dialogue.new( "...um...", "Me", function()
													dialogue.new( "...yes, I guess.", "Me", function()
														dialogue.new( "Fantastic! See you there!", "Jo", function()
															dialogue.new( "Right away? This is a nightmare.", "Thought", function()
																dialogue.new( "I guess I better get going then...", "Thought", function()

																	-- Map: cafe
																	composer.gotoScene( "scenes.map", {params = {
																		player = "character_map",
																		destination = "cafe",
																		xStart = 340,
																		yStart = 144,
																		xDestination = 464,
																		yDestination = 260,
																		nextScene = "scene9_cafe"
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
				end )
			end )
		end )
	end


	dialogue.new( "- A bit over a week later -", "Time", function()

		transition.to( cover, {alpha = 0, time = 500, onComplete=function()

			dialogue.new( "*Ring ring!* *Ring ring!*", "Thought", function()
				dialogue.new( "Someone is calling me.", "Thought", function()
					dialogue.new( "Like a normal person, I'm overcome with existential dread.", "Thought", function()
						dialogue.new( "Hello?", "Me", function()
							dialogue.new( "GOOD EVENING!", "Telemarketer", function()
								dialogue.new( "I want to tell you about this fantastic new opportunity!", "Telemarketer", function()
									dialogue.new( "Have you heard of timeshares?!", "Telemarketer", function()
										dialogue.new( "Yes.", "Me", function()
											dialogue.new( "Fantastic! Tell me, have you ever thought of buying into one?", "Telemarketer", function()
												dialogue.new( "...", "Thought", function()
													dialogue.new( ".....", "Thought", function()
														dialogue.new( "...Yes?", "Me", function()
															dialogue.new( "That's wonderful! I have this location in the Alps. Might you be interested in that?", "Telemarketer", function()
																dialogue.new( "Yes?", "Me", function()
																	dialogue.new( "Um... I don't want to sound rude, but are you just saying yes to everything?", "Telemarketer", function()
																		dialogue.new( "Yes.", "Me", function()
																			dialogue.new( "Are you interested in buying or not?", "Telemarketer", function()
																				dialogue.new( "...yes?", "Me", function()
																					dialogue.new( "...", "Telemarketer", function()
																						dialogue.new( "*The telemarketer hangs up.*", "Thought", function()
																							transition.to( cover, {alpha = 1, time = 500, onComplete=function()
																								dialogue.new( "That was stressful...", "Thought", function()

																									dialogue.new( "- Several more days pass -", "Time", function()
																										transition.to( cover, {alpha = 0, time = 500, onComplete=invite } )
																									end )

																								end )
																							end } )
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
								end )
							end )
						end )
					end )
				end )
			end )
		end } )


	end )




	-- dialogue.new( "Oh that was quite a journey, wasn't it!?", "Oldman", function()
	-- 	dialogue.new( "...yes. Yes it was.", "Me", function()
	-- 		dialogue.new( "And to think it didn't take a more than 40 minutes.", "Oldman", function()
	-- 			dialogue.new( "Yeah, so, anyway...", "Me", function()
	-- 				dialogue.new( "You know, most youths these days wouldn't escort an old man like this. They just sit at home and play their video games.", "Oldman", function()
	-- 					dialogue.new( "*Me is spacing out.*", "Thought", function()
	-- 						dialogue.new( "When I was young, we used to take our elderly to the next town and back...", "Oldman", function()
	-- 							dialogue.new( "...I must be off now.", "Me", function()

	-- 								-- Map: cafe
	-- 								composer.gotoScene( "scenes.map", {params = {
	-- 									player = "character_map",
	-- 									destination = "cafe",
	-- 									xStart = 340,
	-- 									yStart = 144,
	-- 									xDestination = 464,
	-- 									yDestination = 260,
	-- 									nextScene = "scene9_cafe"
	-- 								}} )

	-- 							end )
	-- 						end )
	-- 					end )
	-- 				end )
	-- 			end )
	-- 		end )
	-- 	end )
	-- end )






	local player = display.newImage( sceneGroup, "assets/images/characters/player/mcleft1talkingphone.png", 580, 530 )
	player.anchorY = 1
	player.xScale, player.yScale = -1.5, 1.5

	if not dialogueScene then
		player = playerCharacter.new( sceneGroup, 400, 600, 1.5, "idle" )
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