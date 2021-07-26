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
--  © 2021 Eetu Rantanen                    Last Updated: 25 July 2021 --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------
-- A simple game template for game jams and other prototype projects   --
-- for Windows, MacOS and HTML5 platforms.                             --
-------------------------------------------------------------------------

-- Initialize all core plugins, classes and libraries.
local screen = require("classes.screen")
local loadsave = require("classes.loadsave")
local composer = require("composer")
local utils = require("libs.utils")
local sfx = require("classes.sfx")
sfx.loadSound("assets/audio")

---------------------------------------------------------------------------

-- Create simple wrappers for the loadsave plugin that will automatically
-- provide a simple, static salt to the save files (to keep things easy).
local _save = loadsave.save
function loadsave.save( data, filename )
    _save( data, filename, "XeduR" )
end

local _load = loadsave.load
function loadsave.load( filename )
    _load( filename, "XeduR" )
end

-- Set up useful properties that are likely needed later.
transition.ignoreEmptyReference = true
math.randomseed( math.getseed() )

---------------------------------------------------------------------------

-- Require development widgets and move on to the next scene.
if system.getInfo( "environment" ) == "simulator" then
    local performance = require("widgets.performance")
    performance.start( false, {
        fontColor = { 1, 0.8 },
        bgColor = { 0, 0.8 },
        fontSize = 14,
        framesBetweenUpdate = 5
    })
    require("widgets.eventListenerWrapper")
    composer.gotoScene( "scenes.game" )
else
    composer.gotoScene( "scenes.launchScreen" )
end

---------------------------------------------------------------------------
