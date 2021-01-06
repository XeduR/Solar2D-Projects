-----------------------------------------------------------------------
-- Pseudorandom number generation using the linear congruential method:
-----------------------------------------------------------------------
-- This module is intended to be used for when you need to generate
-- platform independent pseudorandom numbers in your Lua applications.
-- Lua's implementation of math.random() is platform specific and its
-- outputs will depend on what platform you are running it on.
--
-- rng.random() and rng.randomseed() are used exactly like their math
-- counterparts, but these functions run a bit slower. The difference,
-- however, is negligible unless you are calling rng.random() hundreds
-- or thousands of times per frame.
-----------------------------------------------------------------------
local rng = {}

local _floor = math.floor

-- Initial randomisation parameters (you can leave these as is).
local a = 1664525
local c = 1013904223
local m = 2^32
local seed = 12345

-- Set a new initial random seed.
function rng.randomseed(n)
    if (type(n) == "number") then
        seed = _floor(n+0.5)
    else
        print( "WARNING: bad argument to 'randomseed' (number expected, got "..type(n)..")" )
    end
end

-- If only one arguments is passed, then x >= 1. If two arguments are passed, then y >= x.
function rng.random(x,y)
    seed = (a * seed + c) % m
    local r = seed / m
    -- With no arguments, return a random number between 0 and 1.
    -- With one argument, return a random number between it and 1.
    -- With two arguments, return a random number between them.
    return not x and r or not y and _floor((x-1)*r+1.5) or _floor((y-x)*r+x+0.5)
end

return rng
