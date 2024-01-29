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
--  © 2021-2022 Eetu Rantanen                                          --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------
-- utils.lua is a simple and expanding Lua library of functions that I
-- regularly use in many of my various projects.

-- Some of these functions are added to a new global utils table, whereas
-- others are added to their respective global libraries, e.g. _G.table.
-------------------------------------------------------------------------

local M = {}

-- All functions with uncertain relations are stored in the utils table.
-- Other functions are added to their respective libraries, e.g. string.
_G.utils = {}

-- Localised global functions.
local getTimer = system.getTimer
local dRemove = display.remove
local random = math.random
local floor = math.floor
local reverse = string.reverse
local gmatch = string.gmatch
local format = string.format
local find = string.find
local gsub = string.gsub
local sub = string.sub
local len = string.len
local rep = string.rep
local tonumber = tonumber
local tostring = tostring
local pairs = pairs
local type = type

--------------------------------------------------------------------------------------------------
-- display
--------------------------------------------------------------------------------------------------

-- Add a power-of-two sized repeating texture fill to a target display object.
function display.addRepeatingFill( target, filename, textureSize, textureScale, textureWrapX, textureWrapY )
	display.setDefault( "textureWrapX", textureWrapX or "repeat" )
	display.setDefault( "textureWrapY", textureWrapY or "repeat" )

	target.fill = {
		type = "image",
		filename = filename,
	}
	target.fill.scaleX = (textureSize / target.width)*(textureScale or 1)
	target.fill.scaleY = (textureSize / target.height)*(textureScale or 1)

	display.setDefault( "textureWrapX", "clampToEdge" )
	display.setDefault( "textureWrapY", "clampToEdge" )
end


-- Scale factor is the value that Solar2D has used to scale all display objects.
function display.getScaleFactor()
	-- The scale factor depends on device orientation.
	if find( system.orientation, "portrait" ) then
		return display.pixelWidth / display.actualContentWidth
	else
		return display.pixelWidth / display.actualContentHeight
	end
end

-- Convert HEX to RGB, and return normalised (0 to 1) or standard RGB (0 to 255) values.
function display.hex2rgb( hex, dontNormalise )
	-- By default, we're returning normalised values (as Solar2D uses normalised values).
	local m = dontNormalise and 1 or 255
	hex = gsub( hex, "#", "" )
	if len(hex) == 3 then
		return tonumber("0x"..hex:sub(1,1))/m, tonumber("0x"..hex:sub(2,2))/m, tonumber("0x"..hex:sub(3,3))/m
	else
		return tonumber("0x"..hex:sub(1,2))/m, tonumber("0x"..hex:sub(3,4))/m, tonumber("0x"..hex:sub(5,6))/m
	end
end

-- Check that the object is a display object, i.e. a table, and check that its width and height
-- are not 0, i.e. that the display object rendered correctly. Optionally remove the it afterwards.
function display.isValid( object, remove )
	local isValid = false
	if type(object) == "table" and object.width ~= 0 and object.height ~= 0 then
		isValid = true
	end
	if remove then
		dRemove(object)
	end
	return isValid
end

-- Convert RGB to HEX, and handle normalised (0 to 1) or standard RGB (0 to 255) inputs.
function display.rgb2hex( r, g, b, notNormalised )
	-- By default, we're expecting the input to be normalised (as Solar2D uses normalised values).
	local m = notNormalised and 1 or 255
	local rgb = floor(r * m) * 0x10000 + floor(g * m) * 0x100 + floor(b * m)
	return format( "%x", rgb )
end

-- Scale a display object to the smallest possible size where it satisfies both
-- required width and height requirements without distorting the aspect ratio.
function display.scaleDisplayObject( target, requiredWidth, requiredHeight )
	local scale = math.max( requiredWidth/target.width, requiredHeight/target.height )
	target.xScale, target.yScale = scale, scale
end

--------------------------------------------------------------------------------------------------
-- math
--------------------------------------------------------------------------------------------------

-- Return a simple and reliable random seed.
function math.getseed()
	return math.floor(os.time() + getTimer()*10)
end

-- Overwrite and fix the existing math.randomseed function.
local _randomseed = math.randomseed
function math.randomseed( seed )
	if type(seed) ~= "number" then
		print( "WARNING: bad argument #1 to 'randomseed' (number expected, got " .. type(seed) .. ")." )
		return
	end
	-- Address the integer overflow issue with Lua 5.1 (affects Solar2D):
	-- Source: http://lua-users.org/lists/lua-l/2013-05/msg00290.html
	local bitsize = 32
	if seed >= 2^bitsize then
		seed = seed - math.floor(seed / 2^bitsize) * 2^bitsize
	end
	_randomseed(seed - 2^(bitsize-1))
end

--------------------------------------------------------------------------------------------------
-- string
--------------------------------------------------------------------------------------------------

-- Pass a string (s) and find how many times a character (or pattern) occurs in it.
function string.count( s, character )
	return select( 2, gsub( s, character, "") )
end

-- Pass a string (s) and find the last occurance of a specific character.
function string.findLast( s, character )
	local n = find( s, character.."[^"..character.."]*$" )
	return n
end

-- Format a number so that it the thousands are split from another using a separator (space by default).
-- i.e. input: 123456790 -> 1 234 567 890, or -1234.5678 -> -1 234.5678
function string.formatThousands( number, separator )
	if type(number) ~= "number" then
		print( "WARNING: bad argument #1 to 'formatThousands' (number expected, got " .. type(number) .. ")." )
		return number
	end
	separator = separator or " "
	-- Separate the integer from the possible minus and fraction.
	local minus, integer, fraction = select( 3, find( tostring(number), "([-]?)(%d+)([.]?%d*)" ) )
	-- Reverse the integer, add a thousands separator every 3 digits and restore the integer.
	integer = reverse( gsub( reverse(integer), "(%d%d%d)", "%1"..separator ))
	-- Remove the possible space from the start of the integer and merge the strings.
	if sub( integer, 1, 1 ) == " " then integer = sub( integer, 2 ) end
	return minus .. integer .. fraction
end

-- Pass a string (s) to split and character by which to split the string.
function string.split( s, character )
	local t = {}
	for _s in gmatch(s, "([^"..character.."]+)") do
		t[#t+1] = _s
	end
	return t
end

-- Pass a string (s) to split in two and an index from where to split.
function string.splitInTwo( s, index )
	return sub(s,1,index), sub(s,index+1)
end

--------------------------------------------------------------------------------------------------
-- system
--------------------------------------------------------------------------------------------------

-- Check if a given file exists or not.
function system.checkForFile( filename, directory )
	if type(filename) ~= "string" then
		print( "WARNING: bad argument #1 to 'checkForFile' (string expected, got " .. type(filename) .. ")." )
		return false
	end

	local path = system.pathForFile( filename, directory or system.ResourceDirectory )
	if path then
		local file = io.open( path, "r" )
		if file then
			file:close()
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------------------------
-- table
--------------------------------------------------------------------------------------------------

-- Create a deep copy of a table and all of its entries (doesn't copy metatables).
function table.copy( t )
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			v = table.copy(v)
		end
		copy[k] = v
	end
	return copy
end

-- Count the number of entries in a given table (non-recursive).
function table.count( t )
	local count = 0
	for i, v in pairs( t ) do
		count = count+1
	end
	return count
end

-- Returns the next entry in a numeric array and optionally
-- reshuffles the table upon reaching the final entry.
function table.getNext( t, shuffle )
	if not t._index then
		t._index = 1
	else
		t._index = t._index+1
	end

	if t._index > #t then
		if shuffle then
			table.shuffle( t )
		end
		t._index = 1
	end

	return t[t._index]
end

-- Returns a random entry from a given table (non-recursive, works with keys and indices).
function table.getRandom( t )
	local returnValue
	local rMax = 0
	for _, v in pairs( t ) do
		local r = random()
		if r >= rMax then
			rMax = r
			returnValue = v
		end
	end
	return returnValue
end

-- Print out all values within a table and its possible subtables (for debugging).
-- Original code from Solar2D Docs: https://docs.coronalabs.com/tutorial/data/outputTable
local function printSubtable( printCache, t, indent )
	if ( printCache[tostring(t)] ) then
		print( indent .. "*" .. tostring(t) )
	else
		printCache[tostring(t)] = true
		if ( type( t ) == "table" ) then
			for pos,val in pairs( t ) do
				local key = type(pos) == "string" and "[\"" .. pos .. "\"] = " or "[" .. pos .. "] = "
				if ( type(val) == "table" ) then
					print( indent .. key .. " {" )
					printSubtable( printCache, val, indent .. rep( " ", len(pos)+8 ) )
					print( indent .. rep( " ", len(pos)+6 ) .. "}" )
				elseif ( type(val) == "string" ) then
					print( indent .. key .. "\"" .. val .. "\"" )
				else
					print( indent .. key .. tostring(val) )
				end
			end
		else
			print( indent..tostring(t) )
		end
	end
end

-- Print the entire contents of a table. Optionally, provide the input table's variable name,
-- which will show up in the print. Otherwise the input table's pointer will be outputted.
function table.print( t, variableName )
	if type(t) == "table" then
		local printCache = {}

		print( (variableName or tostring(t)) .. " = {" )
		printSubtable( printCache, t, "  " )
		print( "}" )
	end
end

-- Perform a Fisher-Yates shuffle on a table. Optionally, don't shuffle the existing
-- table, but instead create a copy of the initial table, shuffle it and return it.
function table.shuffle( t, newTable )
	local target
	if newTable then
		target = {}
		for i = 1, #t do
			target[i] = t[i]
		end
	else
		target = t
	end
	for i = #target, 2, -1 do
		local j = random(i)
		target[i], target[j] = target[j], target[i]
	end
	return target
end

--------------------------------------------------------------------------------------------------
-- utils
--------------------------------------------------------------------------------------------------

-- Simple benchmarking: check how long it takes for a function, f1, to be run over n iterations.
-- If two functions are given, then check which is faster and by how much.
function utils.benchmark( f1, f2, iterations )
	if type(f1) ~= "function" then
		print( "WARNING: bad argument #1 to 'benchmark' (function expected, got " .. type(f1) .. ")." )
		return 0
	end

	-- Compare two functions.
	if type(f2) == "function" then
		iterations = tonumber(iterations) or 1
		local startTime = getTimer()

		for _ = 1, iterations do
			f1()
		end

		local time1 = getTimer() - startTime
		startTime = getTimer()

		for _ = 1, iterations do
			f2()
		end

		local time2 = getTimer() - startTime

		local absoluteDiff = math.abs( math.floor((time1-time2)/iterations*10000)*0.0001 )
		-- If the difference is less than one-ten-thousandth of a millisecond, count them as equal.
		if absoluteDiff < 0.0001 then
			print( "TIME: " .. time1 .. " - the functions are equally fast." )
		else
			local suffix1, suffix2 = "", ""
			if time1 < time2 then
				local relative = math.floor((1-time1/time2)*1000)*0.1
				suffix1 = " (~" ..  relative .. "% and " .. absoluteDiff .. "ms faster per iteration on average)"
			else
				local relative = math.floor((1-time2/time1)*1000)*0.1
				suffix2 = " (~" ..  relative .. "% and " .. absoluteDiff .. "ms faster per iteration on average)"
			end
			print( "TIME - f1: " .. time1 .. " ms" .. suffix1 )
			print( "TIME - f2: " .. time2 .. " ms" .. suffix2 )
		end

	-- Benchmark a single function.
	else
		iterations = tonumber(f2) or 1
		local startTime = getTimer()

		for _ = 1, iterations do
			f1()
		end

		local result = getTimer() - startTime
		print( "TIME: " .. result .. " ms" )
	end
end

-- Check if the input exists and isn't false, and return boolean.
function utils.getBoolean( var )
	return not not var
end

--------------------------------------------------------------------------------------------------

return M
