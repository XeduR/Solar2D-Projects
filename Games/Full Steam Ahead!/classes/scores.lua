-- Top speeds board and knots formatting.

local scores = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local scoresConfig = require( "data.scores" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local boardMethods = {}
boardMethods.__index = boardMethods

--------------------------------------------------------------------------------------
-- Localised functions

local floor = math.floor

--------------------------------------------------------------------------------------
-- Private functions

local function isDescending( first, second )
	return first > second
end

-- Groups the digits in threes from the right by working on the reversed string, then strips a separator left at the front.
local function groupThousands( wholeKnots )
	local separator = scoresConfig.thousandsSeparator
	local reversedDigits = string.format( "%d", wholeKnots ):reverse()
	local grouped = reversedDigits:gsub( "(%d%d%d)", "%1" .. separator:reverse() ):reverse()
	local leadingSeparator = "^" .. separator:gsub( "%p", "%%%0" )

	return ( grouped:gsub( leadingSeparator, "" ) )
end

--------------------------------------------------------------------------------------
-- Public functions

function scores.new( savedList, maxEntries )
	local board = setmetatable( {}, boardMethods )

	board.maxEntries = maxEntries
	board.list = {}

	if type( savedList ) == "table" then
		for i = 1, #savedList do
			if type( savedList[i] ) == "number" then
				board.list[#board.list + 1] = savedList[i]
			end
		end
	end

	table.sort( board.list, isDescending )

	for i = #board.list, maxEntries + 1, -1 do
		board.list[i] = nil
	end

	return board
end

function boardMethods:submit( knots )
	local rank = #self.list + 1

	-- Ties rank below existing entries.
	for i = 1, #self.list do
		if knots > self.list[i] then
			rank = i
			break
		end
	end

	if rank > self.maxEntries then
		return nil
	end

	table.insert( self.list, rank, knots )
	self.list[self.maxEntries + 1] = nil

	return rank
end

function boardMethods:getList()
	local copy = {}

	for i = 1, #self.list do
		copy[i] = self.list[i]
	end

	return copy
end

function scores.formatKnots( knots )
	local wholeKnots = floor( knots + 0.5 )
	local magnitudes = scoresConfig.magnitudes
	local index = 0

	for i = 1, #magnitudes do
		if wholeKnots >= magnitudes[i].value then
			index = i
		end
	end

	if index == 0 then
		return string.format( scoresConfig.knotsFormat, groupThousands( wholeKnots ) )
	end

	local precision = 10 ^ scoresConfig.scaledDecimals
	local scaled = floor( wholeKnots / magnitudes[index].value * precision + 0.5 ) / precision

	-- Rounding can carry into the next magnitude, as in 999.96 million.
	local nextMagnitude = magnitudes[index + 1]
	if nextMagnitude and scaled * magnitudes[index].value >= nextMagnitude.value then
		index = index + 1
		scaled = floor( wholeKnots / magnitudes[index].value * precision + 0.5 ) / precision
	end

	local scaledText = string.format( "%." .. scoresConfig.scaledDecimals .. "f %s", scaled, magnitudes[index].name )

	return string.format( scoresConfig.knotsFormat, scaledText )
end

return scores
