---------------------------------------------------------------------------
--     _____                  _         ______                           --
--    / ___/____  __  _______(_)____   / ____/___ _____ ___  ___  _____  --
--    \__ \/ __ \/ / / / ___/ / ___/  / / __/ __ `/ __ `__ \/ _ \/ ___/  --
--   ___/ / /_/ / /_/ / /  / / /__   / /_/ / /_/ / / / / / /  __(__  )   --
--  /____/ .___/\__, /_/  /_/\___/   \____/\__,_/_/ /_/ /_/\___/____/    --
--      /_/    /____/                                                    --
--                                                                       --
--  © 2020-2021 Spyric Games Ltd.             Last Updated: 24 June 2021 --
---------------------------------------------------------------------------
--  License: MIT                                                         --
---------------------------------------------------------------------------

-- A simple module with easy to use & descriptive display properties for
-- creating dynamically/statically positioned display objects in Solar2D.

---------------------------------------------------------------------------

-- NB! On Android, the "immersiveSticky" mode is problematic. Even though
-- all Android devices from 4.4 onwards support it, this doesn't mean that
-- all devices actually use it. Many Android devices still use the physical
-- navbar and you can't (at least currently) determine whether a device has
-- a physical or a software navbar by just using the Solar2D API.

-- While there are ways of finding out if the screen size has changed, none
-- of them are particularly graceful. However, toggling the "immersiveSticky"
-- mode should be completed within a fraction of a second in most cases. This
-- means that if your app has a splash or a launch screen that is shown when
-- your app launches, like your game or company's logo, then this will allow
-- the plugin (and the Solar2D API) more than enough time to update.

-- If you just require this plugin and, without waiting, begin to create
-- display objects, then they will likely not be positioned correctly if
-- you are positioning them based on the screen dimensions.

-- These issues do not exist on any other platform.

---------------------------------------------------------------------------

local screen = {}
screen.safe = {}

-- Add/update screen table's properties.
local function update()
	screen.minX = display.screenOriginX
	screen.maxX = display.contentWidth - display.screenOriginX
	screen.minY = display.screenOriginY
	screen.maxY = display.contentHeight - display.screenOriginY
	screen.width = display.actualContentWidth
	screen.height = display.actualContentHeight
	screen.centerX = display.contentCenterX
	screen.centerY = display.contentCenterY
	screen.diagonal = math.sqrt( display.actualContentWidth^2+ display.actualContentHeight^2)

	screen.safe.minX = display.safeScreenOriginX
	screen.safe.maxX = display.safeScreenOriginX + display.safeActualContentWidth
	screen.safe.minY = display.safeScreenOriginY
	screen.safe.maxY = display.safeScreenOriginY + display.safeActualContentHeight
	screen.safe.width = display.safeActualContentWidth
	screen.safe.height = display.safeActualContentHeight
	screen.safe.centerX = (screen.safe.minX + screen.safe.maxX)*0.5
	screen.safe.centerY = (screen.safe.minY + screen.safe.maxY)*0.5

	if screen.callback then
		screen.callback()
		screen.callbackCalled = true
	end
end
-- Create the initial screen properties.
update()

-- Manually update screen properties.
function screen.update()
	update()
end

-- Set a callback function to call when update has finished.
function screen.setCallback( f )
	if type( f ) == "function" then
		screen.callback = f
	end
end

---------------------------------------------------------------------------

-- Automatically hide the Android navbar & iOS status bar on system events.
local androidAPI
if system.getInfo("platform") == "android" then
    androidAPI = system.getInfo( "androidApiLevel" )
end

local function toggleSystemUI()
    display.setStatusBar( display.HiddenStatusBar )
	update()
    if androidAPI then
        -- Android 4.4 KitKat (API 19): first version to support immersive navbar.
        if androidAPI >= 19 then
            native.setProperty( "androidSystemUiVisibility", "immersiveSticky" )
        else
            native.setProperty( "androidSystemUiVisibility", "lowProfile" )
        end
    end
end

local function onSystemEvent(event)
    if event.type == "applicationStart" then
        toggleSystemUI()
    elseif event.type == "applicationResume" then
        toggleSystemUI()
    end
end

Runtime:addEventListener( "resize", update )
Runtime:addEventListener( "system", onSystemEvent )

---------------------------------------------------------------------------

return screen
