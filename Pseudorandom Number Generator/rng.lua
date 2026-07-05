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
--  © 2026 Eetu Rantanen                                               --
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
-- numbers, but it is slower than Lua's random function. This module is
-- intended for deterministic gameplay/simulation results. Its output is
-- predictable by design. Don't use it for anything that needs to be secure.
--
-- You can see the pseudorandom number genration in action over at:
-- https://www.xedur.com/demo/pseudorandom-number-generator/
-------------------------------------------------------------------------

local rng = {}

-- Localised functions for slight performance improvement.
local _floor = math.floor
local _abs = math.abs
local _type = type

-- Initial randomisation parameters (you can leave these as is).
local a = 1664525
local c = 1013904223
local m = 2^32
local seed = 12345

-------------------------------------------------------------------------

-- Set a new initial random seed.
function rng.randomseed(n)
	if _type(n) ~= "number" then
		print( "WARNING: bad argument #1 to 'randomseed' (number expected, got ".._type(n)..")" )
		return
	end
	-- Reject NaN (n ~= n) and infinities; either would poison every future result.
	if n ~= n or n == math.huge or n == -math.huge then
		print( "WARNING: bad argument #1 to 'randomseed' (finite number expected, got "..tostring(n)..")" )
		return
	end

	-- Ensure the seed is a positive integer.
	seed = _floor(_abs(n) + 0.5)
end

-- Get the current random seed. Useful for saving and restoring the state,
-- while wanting to generate the same sequence of pseudorandom numbers.
function rng.getSeed()
	return seed
end

-- Generate a pseudorandom number using the linear congruential method.
function rng.random(x,y)
	seed = (a * seed + c) % m
	local r = seed / m
	-- With no arguments,  return a pseudorandom number (fraction) between 0 and 1.
	-- With one argument,  return a pseudorandom number (integer)  between 1 and x.
	-- With two arguments, return a pseudorandom number (integer)  between x and y.
	return _type(x) ~= "number" and r
		or _type(y) ~= "number" and _floor(x*r) + 1
		or _floor((y-x+1)*r) + x
end

-------------------------------------------------------------------------

return rng
