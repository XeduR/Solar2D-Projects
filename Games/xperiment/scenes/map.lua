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
local physics = physics or require("physics")

---------------------------------------------------------------------------

-- Forward declarations & variables.
local touchTerminated = false
local background = nil
local player = nil
local nextScene = nil

local boundary = {
	{ 275, 54, 368, 43, 362, 119, 314, 117 },
	{ 246, 100, 267, 97, 272, 130, 245, 132 },
	{ 219, 90, 209, 110, 208, 130, 228, 131, 230, 105 },
	{ 49, 93, 101, 18, 165, 18, 94, 105, 111, 113, 188, 52, 212, 19, 497, 15, 527, 69, 525, 133, 680, 136, 806, 168, 913, 151, 944, 217, 938, 519, 911, 479, 853, 622, 131, 629, 66, 498, 40, 323, 102, 132, 81, 124, 22, 262, 15, 190 },
	{ 156, 155, 198, 156, 177, 259, 175, 374, 121, 368, 128, 257 },
	{ 124, 411, 178, 408, 178, 484, 134, 501 },
	{ 180, 500, 261, 619, 159, 620, 146, 599, 176, 588, 140, 516 },
	{ 193, 414, 266, 417, 265, 482, 198, 480 },
	{ 198, 497, 258, 499, 235, 557 },
	{ 244, 573, 279, 546, 301, 584, 268, 613 },
	{ 308, 538, 445, 536, 447, 615, 349, 617 },
	{ 294, 408, 336, 395, 359, 455, 360, 513, 293, 524 },
	{ 377, 459, 438, 441, 449, 512, 380, 516 },
	{ 448, 352, 510, 344, 522, 407, 576, 464, 598, 510, 485, 515, 481, 437 },
	{ 488, 540, 570, 537, 578, 617, 489, 614 },
	{ 627, 540, 672, 542, 674, 612, 628, 613 },
	{ 529, 343, 641, 352, 695, 393, 699, 434, 595, 446, 548, 407 },
	{ 757, 475, 813, 533, 843, 541, 862, 401, 871, 388, 839, 372, 810, 395, 813, 417, 785, 405, 779, 435, 796, 449 },
	{ 799, 376, 832, 350, 858, 347, 836, 301, 815, 319, 799, 312, 785, 301, 765, 312 },
	{ 750, 297, 784, 277, 820, 274, 793, 207, 734, 219, 706, 222, 696, 246, 730, 253 },
	{ 721, 169, 784, 182, 788, 191, 743, 199, 710, 210 },
	{ 648, 169, 606, 162, 605, 198, 648, 200 },
	{ 609, 219, 648, 216, 686, 220, 668, 235, 613, 247 },
	{ 611, 274, 646, 266, 652, 302, 612, 307 },
	{ 555, 271, 585, 271, 584, 298, 555, 299 },
	{ 531, 271, 541, 271, 540, 301, 531, 305 },
	{ 502, 269, 514, 272, 512, 306, 431, 320, 412, 274, 435, 273, 450, 301, 495, 298 },
	{ 452, 272, 484, 271, 480, 282, 456, 287 },
	{ 367, 273, 374, 273, 402, 329, 343, 354, 338, 343, 388, 318 },
	{ 362, 297, 367, 311, 348, 324, 346, 307 },
	{ 352, 278, 315, 294, 327, 328, 335, 327, 328, 307, 347, 288 },
	{ 214, 152, 286, 156, 277, 259, 294, 285, 325, 357, 272, 373, 198, 374, 197, 360, 249, 362, 248, 344, 222, 346, 220, 341, 270, 335, 276, 321, 221, 319, 218, 313, 269, 305, 268, 295, 196, 295, 206, 245, 220, 198 },
	{ 318, 152, 378, 158, 370, 207, 373, 256, 355, 258, 357, 242, 341, 228, 332, 239, 337, 259, 320, 276, 310, 226 },
	{ 402, 156, 508, 157, 512, 207, 516, 248, 445, 251, 464, 225, 436, 219, 425, 246, 402, 252, 401, 218 },
	{ 407, 44, 496, 53, 502, 82, 508, 123, 399, 125 },
	{ 529, 150, 588, 147, 586, 158, 533, 157 },
	{ 529, 175, 584, 177, 586, 245, 534, 251, 530, 205, 544, 203, 550, 189, 533, 191 },
	{ 795, 559, 826, 563, 814, 590, 801, 583, 797, 601, 784, 599 },
	{ 837, 565, 841, 569, 824, 618, 818, 617 },
}

-- Convert the boundary coordinates to be relative to the center of the screen.
for i = 1, #boundary do
	for j = 1, #boundary[i], 2 do
		boundary[i][j] = boundary[i][j] - 480
		boundary[i][j+1] = boundary[i][j+1] - 320
	end
end

---------------------------------------------------------------------------

-- Functions.
local function movePlayer( event )
	local phase = event.phase
	local stage = display.getCurrentStage()

	if phase == "began" then
		stage:setFocus( player.icon )
		player.isFocus = true
		player.tempJoint = physics.newJoint( "touch", player, player.x, player.y )

	elseif player.isFocus then
		if phase == "moved" then
			player.tempJoint:setTarget( event.x, event.y + player.icon.height*0.5 )

		else
			if not touchTerminated then
				stage:setFocus( nil )
				player.tempJoint:removeSelf()
				player.isFocus = false

				timer.performWithDelay( 1, function()
					if player then
						player:setLinearVelocity( 0, 0 )
					end
				end )
			end
		end
	end

	return true
end

local sceneOver = false

local function onCollision( self, event )
	if event.phase == "began" and event.other.isDestination and not sceneOver then
		touchTerminated = true
		sceneOver = true

		if player.tempJoint then
			local stage = display.getCurrentStage()
			stage:setFocus( nil )

			player.icon:removeEventListener( "touch", movePlayer )
			player.tempJoint:removeSelf()

			timer.performWithDelay( 1, function()
				if player then
					player:setLinearVelocity( 0, 0 )
				end
				composer.gotoScene( "scenes." .. nextScene )
			end )
		end
	end
end

---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view
	local sceneParams = event.params or {}
	sceneParams.player = sceneParams.player or "character_map"
	sceneParams.destination = sceneParams.destination or "destination"
	sceneParams.xStart = sceneParams.xStart or screen.centerX
	sceneParams.yStart = sceneParams.yStart or screen.centerY
	sceneParams.xDestination = sceneParams.xDestination or screen.centerX + 100
	sceneParams.yDestination = sceneParams.yDestination or screen.centerY + 100
	sceneParams.xDestinationText = sceneParams.xDestinationText or sceneParams.xDestination + 80
	sceneParams.yDestinationText = sceneParams.yDestinationText or sceneParams.yDestination - 80
	nextScene = sceneParams.nextScene or "scene1_therapy"

	---------------------------------------------------------------------------

	background = display.newImage( sceneGroup, "assets/images/backgrounds/map.png", screen.minX, screen.minY )
	background.anchorX, background.anchorY = 0, 0

	-- Draw physics boundaries for the map.
	local physicsBody = {}
	for i = 1, #boundary do
		physicsBody[i] = {
			chain = boundary[i],
			connectFirstAndLastChainVertex = true
		}
	end
	physics.addBody( background, "static", unpack( physicsBody ) )
	-- physics.setDrawMode( "hybrid" )

	---------------------------------------------------------------------------

	player = display.newGroup()
	sceneGroup:insert( player )
	player.x, player.y = sceneParams.xStart, sceneParams.yStart
	player.icon = display.newImage( player, "assets/images/map/" .. sceneParams.player .. ".png", 0, 0 )
	player.icon.anchorY = 1

	physics.addBody( player, "dynamic", { radius=2, bounce=0, friction=0, density=0 } )
	player.isFixedRotation = true
	player.collision = onCollision
	player:addEventListener( "collision" )

	---------------------------------------------------------------------------

	local destination = display.newImage( sceneGroup, "assets/images/map/marker.png", sceneParams.xDestination, sceneParams.yDestination )
	destination.anchorY = 1
	local destinationText = display.newImage( sceneGroup, "assets/images/map/" .. sceneParams.destination .. ".png", sceneParams.xDestinationText, sceneParams.yDestinationText )
	local destinationSensor = display.newCircle( sceneGroup, sceneParams.xDestination, sceneParams.yDestination, 20 )

	destinationSensor.isVisible = false
	physics.addBody( destinationSensor, "static", { radius=destinationSensor.width*0.5, isSensor=true } )
	destinationSensor.isDestination = true

	local instructions = display.newText({
		parent = sceneGroup,
		text = "Follow the roads. Use your mouse or finger to drag the character to their destination.",
		x = screen.centerX - 220,
		y = screen.centerY + 260,
		width = 440,
		font = "assets/fonts/JosefinSlab-Medium.ttf",
		fontSize = 22,
		align = "center"
	})

	local instructionsBG = display.newRect( sceneGroup, instructions.x, instructions.y, instructions.width + 20, instructions.height + 20 )
	instructionsBG:setFillColor( 0, 0.85 )
	instructions:toFront()

end

---------------------------------------------------------------------------

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		sceneOver = false

	elseif event.phase == "did" then
		player.icon:addEventListener( "touch", movePlayer )

	end
end

---------------------------------------------------------------------------

function scene:hide( event )
	if event.phase == "will" then

	end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

---------------------------------------------------------------------------

return scene