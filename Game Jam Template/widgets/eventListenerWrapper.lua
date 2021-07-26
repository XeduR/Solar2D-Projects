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
--  © 2021 Eetu Rantanen                    Last Updated: 27 June 2021 --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------

-- Just simple sanity wrappers to stop Solar2D from warning about "key"
-- events not being supported on iOS on Simulator, as well as to block
-- calls to add or remove "key" event listeners on actual iOS devices.

-- Finally, also show a "loud" warning on Simulator if adding a "mouse"
-- listener on iOS, because "mouse" events just don't work and there
-- are no warning messages about it on the Simulator.

-------------------------------------------------------------------------

local isSimulator = system.getInfo( "environment" ) == "simulator"
local platform = system.getInfo( "platform" )

local _addEventListener = Runtime.addEventListener
local _removeEventListener = Runtime.removeEventListener

-- Silently prevent adding "key" events on iOS (non-Simulator).
function Runtime.addEventListener( ... )
    local t = { ... }
    if not isSimulator and t[2] == "key" and platform == "ios" then
        return
    end
    _addEventListener( ... )
end

-- Silently prevent removing "key" events on iOS (non-Simulator).
function Runtime.removeEventListener( ... )
    local t = { ... }
    if not isSimulator and t[2] == "key" and platform == "ios" then
        return
    end
    _removeEventListener( ... )
end

-- Add extra wrappers only when running on the Solar2D Simulator.
if isSimulator then
    -- Scream bloody murder when trying to use "mouse" event listeners while simulating iOS.
    -- (Just ensuring that no time is wasted with figuring why "mouse" events are not firing.)
    local __addEventListener = Runtime.addEventListener
    function Runtime.addEventListener( ... )
        local t = { ... }
        if t[2] == "mouse" and platform == "ios" then
            print("")
            print("WARNING: Simulating an iOS device, so \"mouse\" events will not work." )
            print("WARNING: Simulating an iOS device, so \"mouse\" events will not work." )
            print("WARNING: Simulating an iOS device, so \"mouse\" events will not work." )
            print("")
        end
        __addEventListener( ... )
    end
    -- Don't show warnings about how "key" events don't work on real device, since we aren't on real device.
    -- (Since "key" events always work on Simulator and we already have a "key" wrapper, this warning isn't needed.)
    local _print = print
    function print(...)
        local t = {...}
        if t[1] == "WARNING: Runtime:addEventListener: real ios devices don't generate 'key' events" then
            return
        end
        _print(...)
    end
end
