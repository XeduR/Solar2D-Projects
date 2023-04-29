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
--  © 2021-2022 Eetu Rantanen           Last Updated: 25 November 2022 --
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
	-- debugMode sends prints to browser console on HTML5 platform, skips directly
	-- to game, toggles on loadsave's error reporting and loads performance meter.
	debugMode = true,
	-- Whether or not the project utilises persistent data via Spyric Loadsave.
	usesSavedata = false,
	-- Whether or not the project encodes and protects the save data or not.
	protectSavedata = true,
	-- Set master volume to zero.
	muteGame = true,

	-- launchScreen.lua contents and visual options:
	logoFilename = "assets/images/launchScreen/XeduR.png",
	logoWidth = 512,
	logoHeight = 256,
	logoOffsetX = 0,
	logoOffsetY = 0,
	logoAnchorX = 0.5,
	logoAnchorY = 0.5,

	text = "© 2022 Eetu Rantanen\nwww.xedur.com",
	font = native.systemFontBold,
	fontSize = 24,
	textAlign = "center",
	textWidth = 600,
	textOffsetX = 0,
	textOffsetY = -10,
	textAnchorX = 0.5,
	textAnchorY = 1,

	-- logo & text transition options:
	showDelay = 250,
	showTime = 500,
	showEasing = easing.inOut,
	hideDelay = 1250,
	hideTime = 250,
	hideEasing = easing.inOut,
	-------------------------------------
}

-------------------------------------------------------------------------

-- If debug mode is active and the project is running on the
-- HTML5 platform then send any prints to the browser console.
local platform = system.getInfo("platform")
if launchParams.debugMode and platform == "html5" then
	local _tostring = tostring
	local _concat = table.concat
	local _gsub = string.gsub

	-- Using lfs workaround to load JS modules outside of project root.
	local lfs = require("lfs")
	lfs.chdir( "widgets" )
	local printToBrowser = require("printToBrowser")
	local _print = printToBrowser.print

	-- Hijack the standard print function.
	local printList = {}
	function print( ... ) -- luacheck: ignore
		for i = 1, arg.n do
			printList[i] = _tostring( arg[i] )
		end
		_print( _gsub( _concat( printList, "    " ), "\t", "    " ) )
		-- Reduce, reuse and recycle.
		for i = 1, arg.n do
			printList[i] = nil
		end
	end

	-- Release widgets folder from LFS' control and clean up the library.
	lfs.chdir( system.pathForFile( "" ) )
	_G.package.loaded["lfs"] = nil
end

---------------------------------------------------------------------------

-- Initialize all core plugins, classes and libraries.
local composer = require("composer")
require("classes.screen")
require("libs.utils")

---------------------------------------------------------------------------
-- The sfx module overwrites parts of the standard audio library. If you wish
-- to use Solar2D's standard audio API, then comment out the two lines below.
require("classes.sfx")
audio.loadSFX("assets/audio")
---------------------------------------------------------------------------

if not launchParams.muteGame then
	audio.setVolume( 0 )
end

---------------------------------------------------------------------------

if launchParams.usesSavedata then
	-- Create simple wrappers for the loadsave plugin that will automatically
	-- provide a simple, static salt to the save files (to keep things easy).
	local loadsave = require("classes.loadsave")
	loadsave.debugMode( launchParams.debugMode )
	loadsave.protectData( launchParams.protectSavedata )

	local _save = loadsave.save
	function loadsave.save( data, filename )
		return _save( data, filename, "XeduR" )
	end

	local _load = loadsave.load
	function loadsave.load( filename )
		return _load( filename, "XeduR" )
	end
end

-- Set up useful properties that are likely needed later.
transition.ignoreEmptyReference = true
math.randomseed( math.getseed() )
require("widgets.eventListenerWrapper")

---------------------------------------------------------------------------

-- Skip past launch screen and start the performance meter plugin.
if launchParams.debugMode then
	local performance = require("widgets.performance")
	performance.start( false, {
		fontColor = { 1, 0.8 },
		bgColor = { 0, 0.8 },
		fontSize = 14,
		framesBetweenUpdate = 5
	})

	composer.gotoScene( "scenes.game", {params = {usesSavedata = launchParams.usesSavedata}} )
else
	-- Simply suppress error messages when not in debug mode.
	Runtime:addEventListener( "unhandledError", function()
		return true
	end )

	composer.gotoScene( "scenes.launchScreen", {params = launchParams} )
end

---------------------------------------------------------------------------
