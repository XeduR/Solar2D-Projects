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

--[[
	utils.lua is a simple and expanding Lua library of functions that I
	regularly use in many of my various projects.
	
	Some of these functions are added to the utils table, whereas others
	are added straight to their respective global library, e.g. _G.table.
	
	CHANGE LOG:
	-----------
    
	[1.4.5] - 8 March 2022
			-	Add the following new functions:
				utils.getScaleFactor()
                
	[1.4.4] - 21 November 2021
			-	Add the following new functions:
				utils.addRepeatingFill( target, filename, textureSize, textureScale, textureWrapX, textureWrapY )
				utils.scaleDisplayObject( target, requiredWidth, requiredHeight )
    
	[1.4.3] - 11 August 2021
			-	Add the following new functions:
				string.count( s, character )
            -   Removed dummy variables via select()
    
	[1.4.2] - 8 August 2021
			-	Add the following new functions:
				string.findLast( s, character )
	
	[1.4.1] - 24 June 2021
			-	Add the following new functions:
				string.formatThousands( number, separator )
				math.getseed()
			-	Overwrite the functionality of the following function:
				math.randomseed( seed )
				
	[1.4] - 24 June 2021
			-	Add the following new functions:
				utils.checkForFile( filename, directory )
				utils.getBoolean( var )
	
	[1.3] - 19 June 2021
			-	Add the following new functions:
				utils.benchmark( f, iterations )
				
	[1.2] - 19 June 2021
			-	Add the following new functions:
				table.getRandom( t )
				table.count( t )
	
	[1.1] - 17 June 2021
			-	Add two new string functions:
				string.split( s, character )
				string.splitInTwo( s, index )
	
	[1.0] - 1 June 2021
			-	Initial release containing the following functions:
				utils.timer( printResult )
				display.isValid( object, remove )
				table.copy( t )
				table.getNext( t, shuffle )
				table.shuffle( t, newTable )
				table.print( t )
]]--

local utils = {}

-- Localised global functions.
local getTimer = system.getTimer
local dRemove = display.remove
local random = math.random
local reverse = string.reverse
local gmatch = string.gmatch
local find = string.find
local gsub = string.gsub
local sub = string.sub
local len = string.len
local rep = string.rep
local tostring = tostring
local pairs = pairs
local type = type

--------------------------------------------------------------------------------------------------
-- utils
--------------------------------------------------------------------------------------------------

-- Add a power-of-two sized repeating texture fill to a target display object.
function utils.addRepeatingFill( target, filename, textureSize, textureScale, textureWrapX, textureWrapY )
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

-- Scale a display object to the smallest possible size where it satisfies both  
-- required width and height requirements without distorting the aspect ratio.
function utils.scaleDisplayObject( target, requiredWidth, requiredHeight )
    local scale = math.max( requiredWidth/target.width, requiredHeight/target.height )
    target.xScale, target.yScale = scale, scale
end

-- Check if a given file exists or not.
function utils.checkForFile( filename, directory )
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

-- Check if the input exists and isn't false, and return boolean.
function utils.getBoolean( var )
	return not not var
end

-- Calculate how many milliseconds has passed between when the timer was first called (started)
-- and when the timer was called the next (finished). Mainly used for benchmarking, etc.
local startTime = nil
function utils.timer( printResult )
	if not startTime then
		startTime = getTimer()
	else
		local time = getTimer()-startTime
		if printResult then
			print( "FINISH TIME: " .. time )
		end
		startTime = nil
		return time
	end
end

-- Simple benchmarking: check how long it takes for a function, f, to be run over n iterations.
function utils.benchmark( f, iterations )
	if type(f) ~= "function" then
		print( "WARNING: bad argument #1 to 'benchmark' (function expected, got " .. type(f) .. ")." )
		return 0
	end
	
	local startTime = getTimer()
	local iterations = iterations or 1
	
	for i = 1, iterations do
		f()
	end
	
	local result = getTimer() - startTime
	print( "TIME: " .. result )
	return result
end

-- Scale factor is the value that Solar2D has used to scale all display objects.
function utils.getScaleFactor()
    -- The scale factor depends on device orientation.
    if find( system.orientation, "portrait" ) then
        return display.pixelWidth / display.actualContentWidth
    else
        return display.pixelWidth / display.actualContentHeight
    end
end

--------------------------------------------------------------------------------------------------
-- display
--------------------------------------------------------------------------------------------------

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

-- Returns a random entry from a given table (non-recursive).
function table.getRandom( t )
	local temp = {}
	for i, v in pairs( t ) do
		temp[#temp+1] = v
	end
	return temp[random(#temp)]
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

-- Print out all values within a table and its possible subtables (for debugging).
-- (source: Solar2D Docs - https://docs.coronalabs.com/tutorial/data/outputTable)
local function printSubtable( printCache, t, indent )
    if ( printCache[tostring(t)] ) then
        print( indent .. "*" .. tostring(t) )
    else
        printCache[tostring(t)] = true
        if ( type( t ) == "table" ) then
            for pos,val in pairs( t ) do
                local key = type(pos) == "string" and "[\"" .. pos .. "\"] => " or "[" .. pos .. "] => "
                if ( type(val) == "table" ) then
                    print( indent .. key .. tostring( t ).. " {" )
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

function table.print( t )
    local printCache = {}

    if ( type(t) == "table" ) then
        print( tostring(t) .. " {" )
        printSubtable( printCache, t, "  " )
        print( "}" )
    else
        printSubtable( printCache, t, "  " )
    end
end

-- Count the number of entries in a given table (non-recursive).
function table.count( t )
	local count = 0
	for i, v in pairs( t ) do
		count = count+1
	end
	return count
end

--------------------------------------------------------------------------------------------------
-- string
--------------------------------------------------------------------------------------------------

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

-- Pass a string (s) and find how many times a character (or pattern) occurs in it.
function string.count( s, character )
    return select( 2, gsub( s, character, "") )
end

--------------------------------------------------------------------------------------------------
-- math
--------------------------------------------------------------------------------------------------

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

-- Return a simple and reliable random seed (integer).
function math.getseed()
	return os.time() + getTimer()*10
end

--------------------------------------------------------------------------------------------------

return utils
