local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")

---------------------------------------------------------------------------

-- Forward declarations & variables.
local audioButton = require( "widgets.audioButton" )
local button = {}

---------------------------------------------------------------------------

-- Functions.


---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view

	audioButton.create()

	local bg = display.newImage( sceneGroup, "assets/images/backgrounds/walk.png", screen.centerX, screen.centerY )

	local widget = require("widget")

	local function buttonEvent( event )
		local id = event.target.id

		for _, v in pairs( button ) do
			v:setEnabled( false )
		end

		if id == "start" then
			composer.gotoScene( "scenes.scene1_therapy" )
		elseif id == "exit" then
			native.requestExit()
		end
	end

	local logo = display.newImage( sceneGroup, "assets/images/launchScreen/logo.png", screen.minX + 180, screen.minY + 240 )

	button.start = widget.newButton(
		{
			x = 700,
			y = 247,
			id = "start",
			label = "Start",
			labelAlign = "center",
			labelColor = { default={ 0.9 }, over={ 1 } },
			onRelease = buttonEvent,
			fontSize = 64,
			width = 200,
			height = 72,
			font = "assets/fonts/JosefinSlab-Medium.ttf",
			shape = "rect",
			fillColor = { default={ 0, 0.7 }, over={ 0, 0.9 } },
			isEnabled = false,
		}
	)

	button.exit = widget.newButton(
		{
			x = 700,
			y = 347,
			id = "exit",
			label = "Exit",
			labelAlign = "center",
			labelColor = { default={ 0.9 }, over={ 1 } },
			onRelease = buttonEvent,
			fontSize = 64,
			width = 200,
			height = 72,
			font = "assets/fonts/JosefinSlab-Medium.ttf",
			shape = "rect",
			fillColor = { default={ 0, 0.7 }, over={ 0, 0.9 } },
			isEnabled = false,
		}
	)

	for _, v in pairs( button ) do
		sceneGroup:insert( v )
	end

	local credits = display.newText({
		parent = sceneGroup,
		text = "Design & Story by Emma Julkunen & Eetu Rantanen.\nArt by Emma Julkunen & programming by Eetu Rantanen.",
		x = screen.centerX,
		y = screen.maxY - 120,
		width = 860,
		font = "assets/fonts/JosefinSlab-Medium.ttf",
		fontSize = 24,
		align = "center",
	})
	credits.anchorY = 1

	local creditsBGM = display.newText({
		parent = sceneGroup,
		text = "BGM: \"Bittersweet\" Kevin MacLeod (incompetech.com) Licensed under Creative Commons: By Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/.",
		x = screen.centerX,
		y = screen.maxY - 60,
		width = 720,
		font = "assets/fonts/JosefinSlab-Medium.ttf",
		fontSize = 18,
		align = "center",
	})
	credits.anchorY = 1

	local padding = 20
	local creditsBG = display.newRect( sceneGroup, screen.centerX, screen.maxY - 30, 960, 160 )
	creditsBG.anchorY = 1
	creditsBG:setFillColor( 0, 0.8 )
	credits:toFront()
	creditsBGM:toFront()


	local ggj = display.newText({
		parent = sceneGroup,
		text = "Created as a part of Global Game Jam 2024.",
		x = screen.centerX,
		y = screen.minY + 46,
		width = 860,
		font = "assets/fonts/JosefinSlab-Bold.ttf",
		fontSize = 28,
		align = "center",
	})
	credits.anchorY = 1

	-- Requiring and starting physics here so it doesn't need to be started in every map scene.
	local physics = require("physics")
	physics.start()
	physics.setGravity( 0, 0 )
end

---------------------------------------------------------------------------

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		-- If coming from launchScreen scene, then start by removing it.
		if composer._previousScene == "scenes.launchScreen" then
			composer.removeScene( "scenes.launchScreen" )
		end

		-- Lazy hack to prevent the audio from starting again if the player completes the game
		-- and returns to the menu scene.
		if not _G.audioPlaying then
			_G.audioPlaying = true

			-- Quick and dirty fix to some weird audio issues in the browser,
			-- where audio doesn't play at all if it's started too early.
			local delay = 0
			if system.getInfo( "environment" ) == "browser" then
				delay = 2500
			end

			timer.performWithDelay( delay, function()
				_G.audioPlaying = true


				local options =
				{
					fadein = 1500,
					channel = 1,
					loops = -1,
				}

				-- local backgroundMusic = audio.loadStream( "assets/audio/Bittersweet.mp3" )
				audio.play( "assets/audio/Bittersweet_stream.mp3", options )
			end )
		end

	elseif event.phase == "did" then
		for _, v in pairs( button ) do
			v:setEnabled( true )
		end
	end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene