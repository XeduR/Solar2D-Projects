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
--  © 2021 Eetu Rantanen                                               --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------
-- Trigger the "propertyUpdate" event listener when updating existing  --
-- properties or adding new propeties to a display object/group.       --
-------------------------------------------------------------------------
--[[
    -- How to use:

    local propertyUpdate = require("propertyUpdate")
    local object = display.newRect( 100, 100, 100, 100 )

    object = propertyUpdate.getProxy( object )

    function object:propertyUpdate( event )
    	for i, v in pairs( event ) do
    		print( i, v )
    	end
    end
    object:addEventListener( "propertyUpdate" )

    object.x = 200
]]
-------------------------------------------------------------------------
-- NOTE: "object" is a proxy and not a display object/group, which means
-- it cannot be directly inserted into any display groups or be used as
-- an argument to Solar2D display API calls. In order to insert "object"
-- into a display group, you need to use: group:insert( object._raw ).
-------------------------------------------------------------------------

local propertyUpdate = {}

local unpack = unpack
local type = type

-- Create a proxy for a display object/group, which calls the "propertyUpdate" listener
-- when the parent's existing properties are updated or if new properties are added to it.
function propertyUpdate.getProxy( parent )
    local t = {}
    -- Add direct access to the "raw" properties directly, bypassing the metamethods.
    t._raw = parent
    
    -- See: Tracking Table Accesses - https://www.lua.org/pil/13.4.4.html
    local mt = {
        -- Accessing existing properties.
        __index = function( _t, k )
            -- Pass method/function calls to the display object/group.
            if type( parent[k] ) == "function" then
                return function( ... )
                    arg[1] = parent
                    parent[k]( unpack(arg) )
                end
            else
                return parent[k]
            end
        end,
        -- Creating new or updating existing properties.
        __newindex = function( _t, k, v )
            -- Dispatch an event to the "propertyUpdate" listener.
            parent:dispatchEvent({
                name = "propertyUpdate",
                target = _t,
                key = k,
                value = v
            })
            parent[k] = v
        end
    }
    setmetatable( t, mt )
    
    -- The parent is now only accessible via the proxy and it remains
    -- in memory via the references to it in the proxy's metamethods.
    return t
end

return propertyUpdate
