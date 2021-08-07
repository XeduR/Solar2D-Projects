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
--  © 2021 Eetu Rantanen                   Last Updated: 7 August 2021 --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------
-- A simple game template for game jams and other prototype projects   --
-- for Windows, MacOS and HTML5 platforms. This template is intended   --
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
    
    -- launchScreen.lua visual options --
    logoFilename = "assets/images/launchScreen/XeduR.png",
    logoWidth = 512,
    logoHeight = 256,
    logoOffsetX = 0,
    logoOffsetY = 0,
    logoAnchorX = 0.5,
    logoAnchorY = 0.5,
    
    text = "© 2021 Eetu Rantanen\nwww.xedur.com",
    font = native.systemFontBold,
    fontSize = 24,
    textAlign = "center",
    textWidth = 600,
    textOffsetX = 0,
    textOffsetY = -10,
    textAnchorX = 0.5,
    textAnchorY = 1,
    
    -- logo & text transition options  --
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
if launchParams.debugMode and system.getInfo("platform") == "html5" then
	local _print = print
    local _tostring = tostring
    local _concat = table.concat
    local _gsub = string.gsub
    
    local lfs = require("lfs")
    lfs.chdir( "widgets" )
	local printToBrowser = require("printToBrowser")
    local newPrint = printToBrowser.print
    
    -- Hijack the standard print function.
	local printList = {}
	function print( ... )
        for i = 1, arg.n do
            printList[i] = _tostring( arg[i] )
        end
		newPrint( _gsub( _concat( printList, "    " ), "\t", "    " ) )
	    -- Reduce, reuse and recycle.
	    for i = 1, arg.n do
	        printList[i] = nil
	    end
	end
    
    -- Release widgets folder from LFS' control and clean it up.
    lfs.chdir( system.pathForFile() )
    lfs = nil
    _G.package.loaded["lfs"] = nil
end

---------------------------------------------------------------------------

-- Initialize all core plugins, classes and libraries.
local screen = require("classes.screen")
local composer = require("composer")
local utils = require("libs.utils")
local sfx = require("classes.sfx")
sfx.loadSound("assets/audio")

---------------------------------------------------------------------------

if launchParams.usesSavedata then
    -- Create simple wrappers for the loadsave plugin that will automatically
    -- provide a simple, static salt to the save files (to keep things easy).
    local loadsave = require("classes.loadsave")
    loadsave.reportErrors = launchParams.debugMode

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

-- Handle a few annoying issues with simulated iOS devices.
if system.getInfo("environment") == "simulator" then
    require("widgets.eventListenerWrapper")
end

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
