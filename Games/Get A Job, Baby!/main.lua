display.setStatusBar( display.HiddenStatusBar )
local lfs = require( "lfs" )
local composer = require( "composer" )
local screen = require( "scripts.screen" )
local sfx = require( "scripts.sfx" )
sfx.setup()
math.randomseed( os.time() )


-- NB!	This version has the "GLOBAL_FIX" patch that was actually useless. It can be reverted back to
--		composer table. The issue was that when Solar2D builds for a device, it will move all of the
-- 		Lua files into a resource file, which means they can no longer be found via Lua file system.
GLOBAL_FIX = {}


-- NB!	If you want to skip directly to a specific gameMode and just play that, for testing purposes,
--		for instance, then uncomment the line below and change the scene name to your desired gameMode.
-- local skipToScene = "gamble"


local function block( event )
	return true
end

-- A few global display objects (to speed up programming)
G_block = display.newRect( screen.centreX, screen.centreY, screen.width, screen.height )
G_block.isVisible = false
G_block.isHitTestable = true
G_block:addEventListener( "touch", block )

G_month = display.newText( "Month 1", screen.minX + 10, screen.minY + 10, "fonts/Roboto-Black.ttf", 32 )
G_month.anchorX, G_month.anchorY = 0, 0
G_month:setFillColor(0)

G_money = display.newText( "$0", G_month.x, G_month.y + G_month.height + 20, "fonts/Roboto-Black.ttf", 32 )
G_money.anchorX, G_money.anchorY = 0, 0
G_money:setFillColor(0)

G_performance = display.newText( "$0 - 100%", screen.centreX, G_money.y, "fonts/Roboto-Black.ttf", 32 )
G_performance.anchorY = 0
G_performance:setFillColor(0)
G_performance.isVisible = false

local soundText = display.newText( "sound: on", screen.maxX-2, screen.minY - 2, "fonts/Roboto-Black.ttf", 30 )
soundText.anchorX, soundText.anchorY = 1, 0
soundText:setFillColor( 0 )

local function toggleSound( event )
	if event.phase == "ended" then
		local sound = sfx.toggle()
		if sound then
			sfx.play()
			soundText.text = "sound: on"
		else
			soundText.text = "sound: off"
		end
	end
	return true
end
soundText:addEventListener( "touch", toggleSound )

GLOBAL_FIX.month = 1
GLOBAL_FIX.money = 0

local screenDiameter = math.sqrt( screen.width^2 + screen.height^2 )
GLOBAL_FIX.scaleMaskTo = screenDiameter / 256 + 3

-- Dynamically load all .lua files from the scenes/games folder and add them to the game.
path = system.pathForFile( "scenes/games", system.ResourceDirectory )
GLOBAL_FIX.gameModes = {}

GLOBAL_FIX.gameModes[1] = "fisher"
GLOBAL_FIX.gameModes[2] = "gamble"
GLOBAL_FIX.gameModes[3] = "miner"
GLOBAL_FIX.gameModes[4] = "shepherd"
GLOBAL_FIX.gameModes[5] = "trader"

-- local job = 1

-- for file in lfs.dir( path ) do
-- 	if file:sub(-4) == ".lua" then
-- 		GLOBAL_FIX.gameModes[job] = file:sub(1,-5)
-- 		job = job+1
-- 	end
-- end

path = system.pathForFile( "scenes/traps", system.ResourceDirectory )
GLOBAL_FIX.traps = {}
GLOBAL_FIX.traps[1] = "socialworker"
GLOBAL_FIX.traps[2] = "newfamily"
-- local trap = 1
--
-- for file in lfs.dir( path ) do
-- 	if file:sub(-4) == ".lua" then
-- 		GLOBAL_FIX.traps[trap] = file:sub(1,-5)
-- 		trap = trap+1
-- 	end
-- end


-- Check that if the developer "skipToScene" is given that the scene actually exists.
local skip = 0
if skipToScene then
	local path = system.pathForFile( "scenes/games/" .. skipToScene .. ".lua", system.ResourceDirectory )
	if path then
		local file = io.open( path, "r" )
		if file then
			skip = 1
			io.close( file )
		end
	else
		local path = system.pathForFile( "scenes/traps/" .. skipToScene .. ".lua", system.ResourceDirectory )
		if path then
			local file = io.open( path, "r" )
			if file then
				skip = 2
				io.close( file )
			end
		end
	end
end


if skip ~= 0 then
	G_performance.isVisible = true
	if skip == 1 then
		composer.gotoScene( "scenes.games." .. skipToScene, { params = { repeatScene=true } } )
	else
		composer.gotoScene( "scenes.traps." .. skipToScene, { params = { repeatScene=true } } )
	end
else
	composer.gotoScene( "scenes.hospital", { params = { gameLaunched=true } } )
end
