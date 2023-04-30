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
--  © 2022 Eetu Rantanen                Last Updated: 25 November 2022 --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------
-- Pseudorandom number generation using the linear congruential method:
--
-- Lua 5.1's math.random implementation is platform dependent, meaning
-- it may return different results on different platforms, even when
-- using the same randomseed.
--
-- This module's random function will generate consistent pseudorandom
-- numbers, but it is slightly slower than Lua's random function.
--
-- You can see the pseudorandom number genration in action over at:
-- https://www.xedur.com/demos/Pseudorandom%20Number%20Generator/
-------------------------------------------------------------------------

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

-------------------------------------------------------------------------

-- Set a new initial random seed.
function rng.randomseed(n)
	if _type(n) == "number" then
		seed = _floor(_abs(n+0.5))
	else
		print( "WARNING: bad argument to 'randomseed' (number expected, got ".._type(n)..")" )
	end
end

-- Generate a pseudorandom number using the linear congruential method.
function rng.random(x,y)
	seed = (a * seed + c) % m
	local r = seed / m
	-- With no arguments,  return a pseudorandom number (fraction) between 0 and 1.
	-- With one argument,  return a pseudorandom number (integer)  between 1 and x.
	-- With two arguments, return a pseudorandom number (integer)  between x and y.
	return _type(x) ~= "number" and r or _type(y) ~= "number" and _floor((x-1)*r+1.5) or _floor((y-x)*r+x+0.5)
end

-------------------------------------------------------------------------

return rng
