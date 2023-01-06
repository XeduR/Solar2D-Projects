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
--  © 2021-2022 Eetu Rantanen            Last Updated: 6 November 2022 --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------

-- Overwriting the built-in Solar2D Runtime methods to:
-- 1) Remove unnecessary warnings about key events on iOS (sim).
-- 2) Add a loud & useful warning for iOS (sim) about mouse events.

-------------------------------------------------------------------------

local needsHardwareSupport = { orientation=true, accelerometer=true, gyroscope=true, location=true, heading=true }

local isSimulator = system.getInfo( "environment" ) == "simulator"
local platform = system.getInfo( "platform" )

function Runtime:addEventListener( eventName, listener )
	if eventName == "key" and platform == "ios" then
		return
	end

	-- Ensure no developer time is wasted with figuring out why "mouse" events aren't firing.
	if isSimulator and eventName == "mouse" and platform == "ios" then
		print( "" )
		print( "WARNING: ios will not generate \"mouse\" events." )
		print( "WARNING: ios will not generate \"mouse\" events." )
		print( "WARNING: ios will not generate \"mouse\" events." )
		print( "" )
		return
	end

	local super = self._super
	local noListeners = not self:respondsToEvent( eventName )
	local wasAdded = super.addEventListener( self, eventName, listener )

	if ( noListeners ) then
		if ( needsHardwareSupport[ eventName ] ) then
			system.beginListener( eventName )
		end
	end
	return wasAdded or nil
end

function Runtime:removeEventListener( eventName, listener )
	if eventName == "key" and platform == "ios" then
		return
	end
	local super = self._super
	return super.removeEventListener( self, eventName, listener )
end
