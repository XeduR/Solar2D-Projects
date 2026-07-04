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
--  © 2021-2026 Eetu Rantanen                                          --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------
-- utils.lua is a simple and expanding Lua library of functions that I
-- regularly use in many of my various projects.

-- Some of these functions are added to a new global utils table, whereas
-- others are added to their respective global libraries, e.g. _G.table.
-- All functions with uncertain relations are stored in the utils table.
-- Other functions are added to their respective libraries, e.g. string.

-- This library's purpose is to extend the built-in globals, so silence
--  luacheck about those errors.
-------------------------------------------------------------------------

-- luacheck: ignore 122 142 143

local utils = {}
_G.utils = utils

local lfs = require("lfs")

-- Localised global functions.
local pathForFile = system.pathForFile
local getTimer = system.getTimer
local remove = os.remove
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
	local wrapX, wrapY = display.getDefault( "textureWrapX" ), display.getDefault( "textureWrapY" )
	display.setDefault( "textureWrapX", textureWrapX or "repeat" )
	display.setDefault( "textureWrapY", textureWrapY or "repeat" )

	target.fill = {
		type = "image",
		filename = filename,
	}
	target.fill.scaleX = (textureSize / target.width)*(textureScale or 1)
	target.fill.scaleY = (textureSize / target.height)*(textureScale or 1)

	display.setDefault( "textureWrapX", wrapX )
	display.setDefault( "textureWrapY", wrapY )
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
		-- Expand the shorthand hex by duplicating each digit, e.g. "f2a" means "ff22aa".
		local red, green, blue = sub( hex, 1, 1 ), sub( hex, 2, 2 ), sub( hex, 3, 3 )
		return tonumber("0x"..red..red)/m, tonumber("0x"..green..green)/m, tonumber("0x"..blue..blue)/m
	else
		return tonumber("0x"..sub( hex, 1, 2 ))/m, tonumber("0x"..sub( hex, 3, 4 ))/m, tonumber("0x"..sub( hex, 5, 6 ))/m
	end
end

-- Convert RGB to HEX, and handle normalised (0 to 1) or standard RGB (0 to 255) inputs.
function display.rgb2hex( r, g, b, notNormalised )
	-- By default, we're expecting the input to be normalised (as Solar2D uses normalised values).
	local m = notNormalised and 1 or 255
	local rgb = floor(r * m + 0.5) * 0x10000 + floor(g * m + 0.5) * 0x100 + floor(b * m + 0.5)
	return format( "%06x", rgb )
end

-- Scale a display object to the smallest possible size where it satisfies both
-- required width and height requirements without distorting the aspect ratio.
function display.scaleDisplayObject( target, requiredWidth, requiredHeight )
	local scale = math.max( requiredWidth/target.width, requiredHeight/target.height )
	target.xScale, target.yScale = scale, scale

	return scale
end

--------------------------------------------------------------------------------------------------
-- math
--------------------------------------------------------------------------------------------------

-- Return a simple and reliable random seed.
function math.generateSeed()
	local timerStr = gsub( tostring( getTimer() ), "%.", math.random(9) )

	return floor(os.time() + tonumber(timerStr) )
end

-- Overwrite and fix the existing math.randomseed function (for Lua 5.1).
local _randomseed = math.randomseed
function math.randomseed( seed )
	if type(seed) ~= "number" then
		print( "WARNING: bad argument #1 to 'randomseed' (number expected, got " .. type(seed) .. ")." )
		return
	end

	-- Ensure the seed is a non-negative integer.
	seed = floor(math.abs(seed) + 0.5)

	-- Address the integer overflow issue with Lua 5.1 (affects Solar2D): wrap the seed to 32 bits
	-- and map the upper half to negative so the signed 32-bit cast inside srand can't overflow.
	-- Source: http://lua-users.org/lists/lua-l/2013-05/msg00290.html
	local bitsize = 32
	seed = seed % 2^bitsize

	if seed >= 2^(bitsize-1) then
		_randomseed(seed - 2^bitsize)
	else
		_randomseed(seed)
	end

	return seed
end

--------------------------------------------------------------------------------------------------
-- string
--------------------------------------------------------------------------------------------------

-- Pass a string (s) and find how many times a character (or pattern) occurs in it.
function string.count( s, character )
	return select( 2, gsub( s, character, "") )
end

-- Pass a string (s) and find the starting index of the last occurrence of a character (or substring).
function string.findLast( s, character )
	local n = find( reverse(s), reverse(character), 1, true )
	return n and len(s) - n - len(character) + 2
end

-- Format a number so that the thousands are separated from each other by a separator (space by default).
-- i.e. input: 1234567890 -> 1 234 567 890, or -1234.5678 -> -1 234.5678
function string.formatThousands( number, separator )
	if type(number) ~= "number" then
		print( "WARNING: bad argument #1 to 'formatThousands' (number expected, got " .. type(number) .. ")." )
		return number
	end
	separator = separator or " "

	-- Non-finite numbers (inf/nan) have no digits to format.
	if number ~= number or number == math.huge or number == -math.huge then
		return tostring(number)
	end

	local numberStr = tostring(number)
	if find( numberStr, "e", 1, true ) then
		if math.abs(number) < 1 then
			-- Tiny fractions like 1e-05 have no thousands to separate.
			return numberStr
		end
		-- tostring switches to exponent notation around 1e+15, so expand large numbers manually.
		numberStr = format( "%.0f", number )
	end

	-- Separate the integer from the possible minus and fraction.
	local minus, integer, fraction = select( 3, find( numberStr, "([-]?)(%d+)([.]?%d*)" ) )
	-- Reverse the integer and add a reversed separator after every 3 digits, then restore both.
	integer = reverse( gsub( reverse(integer), "(%d%d%d)", "%1"..reverse(separator) ))
	-- If the digit count is divisible by 3, then the gsub added one leading separator too many.
	if sub( integer, 1, len(separator) ) == separator then
		integer = sub( integer, len(separator)+1 )
	end

	return minus .. integer .. fraction
end

-- Pass a string (s) to split and character by which to split the string.
function string.split( s, character )
	-- Escape pattern magic characters so that any separator is treated as plain text.
	character = gsub( character, "(%W)", "%%%1" )
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

-- Return the true platform that the Solar2D Simulator or an app is running on.
function system.getTruePlatform()
	-- NOTE: "environment" on Linux doesn't seem to realise when it's on "simulator" vs "device".
	if system.getInfo( "environment" ) == "simulator" then
		local handle = io.open( "/Applications", "r" )
		if handle then
			handle:close()
			return "macos"
		end
		handle = io.open( "/proc/version", "r" )
		if handle then
			handle:close()
			return "linux"
		end
		return "win32"
	end
	-- NOTE: "platform" returns "Linux" instead of "linux".
	return system.getInfo( "platform" ):lower()
end

-- Check if a given file exists or not.
function system.checkForFile( filename, directory )
	if type(filename) ~= "string" then
		print( "WARNING: bad argument #1 to 'checkForFile' (string expected, got " .. type(filename) .. ")." )
		return false
	end

	-- Lua files in the resource directory may be compiled into the app binary, so check them via require.
	if sub( filename, -4 ) == ".lua" and (directory == nil or directory == system.ResourceDirectory) then
		local filepath = gsub( gsub( sub( filename, 1, -5 ), "%\\", "/"), "%/", "." )
		-- If the module is already loaded, then the file clearly exists.
		if _G.package.loaded[filepath] then
			return true
		end
		-- Otherwise, clean up the loaded module after checking that the file exists.
		local success = pcall( require, filepath )
		if success then
			_G.package.loaded[filepath] = nil
		end
		return success
	else
		local path = pathForFile( filename, directory or system.ResourceDirectory )
		if path then
			local file = io.open( path, "r" )
			if file then
				file:close()
				return true
			end
		end
	end
	return false
end

-- Remove all files and subfolders inside a given folder.
-- (NB! Be careful when using this function as it does exactly as advertised.)
function system.cleanupFolder( folder, directory, subfolder )
	if type(folder) ~= "string" then
		print( "WARNING: bad argument #1 to 'cleanupFolder' (string expected, got " .. type(folder) .. ")." )
		return
	end
	directory = directory or system.DocumentsDirectory

	local path = pathForFile( folder, directory )
	if not path or lfs.attributes( path, "mode" ) ~= "directory" then
		return
	end

	for file in lfs.dir( path ) do
		if file ~= "." and file ~= ".." then
			local filepath = path .. "/" .. file

			if lfs.attributes( filepath, "mode" ) == "directory" then
				system.cleanupFolder( (folder ~= "" and folder .. "/" or "") .. file, directory, true )
			else
				remove( filepath )
			end
		end
	end

	-- Don't remove the target folder itself.
	if subfolder then
		-- Change directory to ensure the OS isn't using (and locking) the folder being removed.
		lfs.chdir( pathForFile( "", system.DocumentsDirectory ) )
		-- os.remove doesn't work on folders on non-POSIX compliant OSes, i.e. Windows, but lfs.rmdir does.
		lfs.rmdir( path )
	end
end

-- Check if a folder exists in a given directory or create it (including any missing parent folders).
function system.createFolder( folder, directory )
	folder = gsub( folder, "%\\", "/" )
	directory = directory or system.DocumentsDirectory

	local path = pathForFile( folder, directory )
	if not path or lfs.attributes( path, "mode" ) ~= "directory" then
		local currentPath = pathForFile( "", directory )

		for segment in gmatch( folder, "[^/]+" ) do
			currentPath = currentPath .. "/" .. segment
			if lfs.attributes( currentPath, "mode" ) ~= "directory" and not lfs.mkdir( currentPath ) then
				return false
			end
		end
	end
	return true
end

--------------------------------------------------------------------------------------------------
-- table
--------------------------------------------------------------------------------------------------

-- Create a deep copy of a table and all of its entries (doesn't copy metatables).
-- Cyclic and shared subtables are copied once and their references are preserved.
function table.copy( t, copyCache )
	copyCache = copyCache or {}
	if copyCache[t] then
		return copyCache[t]
	end

	local copy = {}
	copyCache[t] = copy
	for k, v in pairs(t) do
		if type(v) == "table" then
			v = table.copy( v, copyCache )
		end
		copy[k] = v
	end
	return copy
end

-- Count the number of entries in a given table (non-recursive).
function table.count( t )
	local count = 0
	for _, _ in pairs( t ) do
		count = count+1
	end
	return count
end

-- Returns the next entry in a numeric array and optionally reshuffles the table
-- upon reaching the final entry. The iteration state is stored in t._index.
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
				local posStr = tostring(pos)
				local key = type(pos) == "string" and "[\"" .. posStr .. "\"] = " or "[" .. posStr .. "] = "
				if ( type(val) == "table" ) then
					print( indent .. key .. " {" )
					printSubtable( printCache, val, indent .. rep( " ", len(posStr)+8 ) )
					print( indent .. rep( " ", len(posStr)+6 ) .. "}" )
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
	else
		print( "WARNING: bad argument #1 to 'table.print' (table expected, got " .. type(t) .. ")." )
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
-- If two functions are given, then check which is faster and by how much. Note: only works on
-- synchronous functions, as it doesn't account for asynchronous operations.
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

return utils
