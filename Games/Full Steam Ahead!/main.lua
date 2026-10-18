-------------------------------------------------------------------------
--                                                                     --
--    ooooooo  ooooo                 .o8              ooooooooo.       --
--     `8888    d8'                 "888              `888   `Y88.     --
--       Y888..8P     .ooooo.   .oooo888  oooo  oooo   888   .d88'     --
--        `8888'     d88' `88b d88' `888  `888  `888   888ooo88P'      --
--       .8PY888.    888ooo888 888   888   888   888   888`88b.        --
--      d8'  `888b   888    .o 888   888   888   888   888  `88b.      --
--    o888o  o88888o `Y8bod8P' `Y8bod88P"  `V88V"V8P' o888o  o888o     --
--                                                                     --
--  © 2021-2026 Eetu Rantanen                                          --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------
-- A simple game template for game jams and other prototype projects   --
-- for all platforms supported by Solar2D. This template is intended   --
-- to be used with small projects that require only a single composer  --
-- scene, game.lua, and it has been set up with that in mind. However, --
-- you are free to customise this game template as you see fit.        --
-------------------------------------------------------------------------

local launchParams = {
	-------------------------------------
	-- Prints go to the browser console on HTML5, the launch screen is skipped, loadsave reports errors and the performance meter shows.
	debugMode = true,

	usesSavedata = true,

	-- Encodes the save file and adds a hash, so loading rejects a file that was edited by hand.
	protectSavedata = true,

	-- Salt for that hash; changing it makes existing save files fail to load.
	savedataSalt = "XeduR",

	-- Starts the game at zero master volume, ignoring the saved master volume until the volume slider moves.
	muteGame = false,

	-- Launch screen logo; the offsets are from the screen's centre.
	logoFilename = "assets/images/launchScreen/XeduR.png",
	logoWidth = 512,
	logoHeight = 256,
	logoOffsetX = 0,
	logoOffsetY = 0,
	logoAnchorX = 0.5,
	logoAnchorY = 0.5,

	-- Launch screen copyright text; the offsets are from the bottom centre of the screen.
	text = "© 2026 Eetu Rantanen\nwww.xedur.com",
	font = native.systemFontBold,
	fontSize = 24,
	textAlign = "center",
	textWidth = 600,
	textOffsetX = 0,
	textOffsetY = -10,
	textAnchorX = 0.5,
	textAnchorY = 1,

	-- Fade in and out of the logo and text, in milliseconds.
	showDelay = 250,
	showTime = 500,
	showEasing = easing.inOut,
	hideDelay = 1250,
	hideTime = 250,
	hideEasing = easing.inOut,

	-- Scene change from the launch screen to the game, in milliseconds.
	sceneEffect = "fade",
	sceneEffectTime = 100,
	-------------------------------------
}

-------------------------------------------------------------------------

local platform = system.getInfo( "platform" )

if launchParams.debugMode and platform == "html5" then
	local _tostring = tostring
	local _concat = table.concat
	local _gsub = string.gsub

	-- JS modules load only from the current directory, so lfs switches into widgets/ for this require.
	local lfs = require( "lfs" )
	lfs.chdir( "widgets" )
	local printToBrowser = require( "printToBrowser" )
	local _print = printToBrowser.print

	-- A global print override sends every print in the game to the browser console.
	local printList = {}

	function _G.print( ... ) -- luacheck: ignore
		for i = 1, arg.n do
			printList[i] = _tostring( arg[i] )
		end

		_print( _gsub( _concat( printList, "    " ), "\t", "    " ) )

		-- The list is emptied and reused so print never allocates a new table.
		for i = 1, arg.n do
			printList[i] = nil
		end
	end

	lfs.chdir( system.pathForFile( "" ) )
	_G.package.loaded["lfs"] = nil
end

---------------------------------------------------------------------------

local composer = require( "composer" )
require( "classes.screen" )

---------------------------------------------------------------------------

if launchParams.usesSavedata then
	local loadsave = require( "classes.loadsave" )
	loadsave.debugMode( launchParams.debugMode )
	loadsave.protectData( launchParams.protectSavedata )

	-- Wrap save and load so every call passes the fixed salt.
	local _save = loadsave.save

	function loadsave.save( data, filename )
		return _save( data, filename, launchParams.savedataSalt )
	end

	local _load = loadsave.load

	function loadsave.load( filename )
		return _load( filename, launchParams.savedataSalt )
	end
end

transition.ignoreEmptyReference = true
math.randomseed( os.time() )

---------------------------------------------------------------------------

if launchParams.debugMode then
	local performance = require( "widgets.performance" )

	performance.start( false, {
		fontColor = { 1, 0.8 },
		bgColor = { 0, 0.8 },
		fontSize = 14,
		framesBetweenUpdate = 5,
	} )

	composer.gotoScene( "scenes.game", { params = { usesSavedata = launchParams.usesSavedata, muteGame = launchParams.muteGame } } )
else
	-- Outside debug mode, runtime errors are swallowed so players never see an error dialog.
	Runtime:addEventListener( "unhandledError", function()
		return true
	end )

	composer.gotoScene( "scenes.launchScreen", { params = launchParams } )
end
