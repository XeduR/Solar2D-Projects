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

--[[
	utils.lua is a simple and expanding Lua module that I personally use
	in my projects to in order to add frequently used functions to my
	projects without having to rewrite them every time.
	
	Some of these functions are part of the utils module, whereas others
	are added straight to their respective global library, e.g. _G.table.
	
	CHANGE LOG:
	-----------
	
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
local sGmatch = string.gmatch
local sSub = string.sub
local sLen = string.len
local sRep = string.rep
local tostring = tostring
local pairs = pairs
local print = print
local type = type

--------------------------------------------------------------------------------------------------
-- utils
--------------------------------------------------------------------------------------------------

-- Check if a given file exists or not.
function utils.checkForFile( filename, directory )
    if type(filename) ~= "string" then
        print( "WARNING: bad argument #1 to 'checkForFile' (string expected, got " .. type(filename) .. ")." )
        return false
    end
	
	local path = system.pathForFile( filename, directory or system.ResourceDirectory )
	local file = io.open( path, "r" )
	if file then
		file:close()
		return true
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
function table.print( t )
    local printCache = {}

    local function printSubtable( t, indent )
        if ( printCache[tostring(t)] ) then
            print( indent .. "*" .. tostring(t) )
        else
            printCache[tostring(t)] = true
            if ( type( t ) == "table" ) then
                for pos,val in pairs( t ) do
                    if ( type(val) == "table" ) then
                        print( indent .. "[" .. pos .. "] => " .. tostring( t ).. " {" )
                        printSubtable( val, indent .. sRep( " ", sLen(pos)+8 ) )
                        print( indent .. sRep( " ", sLen(pos)+6 ) .. "}" )
                    elseif ( type(val) == "string" ) then
                        print( indent .. "[" .. pos .. '] => "' .. val .. '"' )
                    else
                        print( indent .. "[" .. pos .. "] => " .. tostring(val) )
                    end
                end
            else
                print( indent..tostring(t) )
            end
        end
    end

    if ( type(t) == "table" ) then
        print( tostring(t) .. " {" )
        printSubtable( t, "  " )
        print( "}" )
    else
        printSubtable( t, "  " )
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

-- Pass a string (s) to split and character by which to split the string.
function string.split( s, character )
	local t = {}
	for _s in sGmatch(s, "([^"..character.."]+)") do
		t[#t+1] = _s
	end
	return t
end

-- Pass a string (s) to split in two and an index from where to split.
function string.splitInTwo( s, index )
	return sSub(s,1,index), sSub(s,index+1)
end

--------------------------------------------------------------------------------------------------

return utils
