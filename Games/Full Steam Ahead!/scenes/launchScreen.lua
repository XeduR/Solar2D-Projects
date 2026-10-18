-- Fades the logo and copyright text from main.lua's launchParams in and out, then opens the game scene.

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local composer = require( "composer" )
local screen = require( "classes.screen" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local launchParams = {}
local logoGroup = display.newGroup()
logoGroup.alpha = 0

--------------------------------------------------------------------------------------
-- Functions

local function gotoGame( effect, time )
	composer.gotoScene( "scenes.game", {
		effect = effect,
		time = time,
		params = {
			usesSavedata = launchParams.usesSavedata,
			muteGame = launchParams.muteGame,
		},
	} )
end

local function newLogo()
	local width = launchParams.logoWidth or launchParams.logoHeight or 100
	local height = launchParams.logoHeight or width

	local logo = display.newImageRect( logoGroup, launchParams.logoFilename, width, height )
	logo.x = screen.centerX + ( launchParams.logoOffsetX or 0 )
	logo.y = screen.centerY + ( launchParams.logoOffsetY or 0 )
	logo.anchorX = launchParams.logoAnchorX or 0.5
	logo.anchorY = launchParams.logoAnchorY or 0.5
end

local function newCopyrightText()
	local copyrightText = display.newText( {
		parent = logoGroup,
		text = launchParams.text,
		x = screen.centerX + ( launchParams.textOffsetX or 0 ),
		y = screen.maxY + ( launchParams.textOffsetY or 0 ),
		width = launchParams.textWidth or screen.width,
		font = launchParams.font or native.systemFont,
		fontSize = launchParams.fontSize or 20,
		align = launchParams.textAlign or "right",
	} )

	copyrightText.anchorX = launchParams.textAnchorX or 0.5
	copyrightText.anchorY = launchParams.textAnchorY or 0.5
end

local function hideLogo()
	transition.to( logoGroup, {
		delay = launchParams.hideDelay or 1250,
		time = launchParams.hideTime or 250,
		alpha = 0,
		transition = launchParams.hideEasing or easing.inOut,
		onComplete = function()
			gotoGame( launchParams.sceneEffect, launchParams.sceneEffectTime )
		end,
	} )
end

local function showLogo()
	transition.to( logoGroup, {
		delay = launchParams.showDelay or 250,
		time = launchParams.showTime or 500,
		alpha = 1,
		transition = launchParams.showEasing or easing.inOut,
		onComplete = hideLogo,
	} )
end

--------------------------------------------------------------------------------------
-- Scene functions

local scene = composer.newScene()

function scene:create( event )
	local sceneGroup = self.view
	sceneGroup:insert( logoGroup )

	if event.params then
		for key, value in pairs( event.params ) do
			launchParams[key] = value
		end
	end

	if launchParams.logoFilename then
		newLogo()
	end

	if launchParams.text then
		newCopyrightText()
	end
end

function scene:show( event )
	if event.phase == "did" then
		if launchParams.logoFilename or launchParams.text then
			showLogo()
		else
			gotoGame()
		end
	end
end

--------------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

return scene
