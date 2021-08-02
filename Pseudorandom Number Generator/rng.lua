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
--  © 2021 Eetu Rantanen                    Last Updated: 24 June 2021 --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------

-----------------------------------------------------------------------
-- Pseudorandom number generation using the linear congruential method:
-----------------------------------------------------------------------
-- An interactive online tool demonstrating the random distribution is available at:
-- https://www.xedur.com/demos/Pseudorandom%20Number%20Generator/
--
-- This module is intended to be used for when you need to generate
-- platform independent pseudorandom numbers in your Lua applications.
-- Lua's implementation of math.random() (at least for Lua 5.1, which
-- affects Solar2D) is platform specific and its outputs will depend
-- on what platform you are running it on.
--
-- rng.random() and rng.randomseed() are used exactly like their math
-- counterparts, but these functions run a bit slower. The difference,
-- however, is negligible unless you are calling rng.random() hundreds
-- or thousands of times per frame.
-----------------------------------------------------------------------
local rng = {}

-- Localised math functions.
local _abs = math.abs
local _floor = math.floor
local _type = type

-- Initial randomisation parameters (you can leave these as is).
local a = 1664525
local c = 1013904223
local m = 2^32
local seed = 12345

-- Set a new initial random seed.
function rng.randomseed(n)
    if _type(n) == "number" then
        seed = _floor(_abs(n+0.5))
    else
        print( "WARNING: bad argument to 'randomseed' (number expected, got ".._type(n)..")" )
    end
end

-- Generate a pseudorandom number.
function rng.random(x,y)
    seed = (a * seed + c) % m
    local r = seed / m
    -- With no arguments,  return a pseudorandom number (fraction) between 0 and 1.
    -- With one argument,  return a pseudorandom number (integer)  between 1 and x.
    -- With two arguments, return a pseudorandom number (integer)  between x and y.
    return _type(x) ~= "number" and r or _type(y) ~= "number" and _floor((x-1)*r+1.5) or _floor((y-x)*r+x+0.5)
end

return rng
