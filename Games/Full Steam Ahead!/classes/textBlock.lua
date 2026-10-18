-- Multi-line text built from one single-line text object per line, so the line pitch is the same on every platform.

local textBlock = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local gameText = require( "classes.gameText" )
local fonts = require( "data.fonts" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local blockMethods = {}

local alignAnchors = { left = 0, center = 0.5, right = 1 }

--------------------------------------------------------------------------------------
-- Localised functions

local max = math.max

--------------------------------------------------------------------------------------
-- Private functions

local function newLine( group, text, params )
	local line = gameText.new( {
		parent = group,
		text = text,
		x = 0,
		y = 0,
		font = params.font,
		fontSize = params.fontSize,
	} )
	line.anchorY = 0

	return line
end

-- Greedy wrap on measured candidate lines; a word wider than the wrap width gets a line of its own.
local function addParagraph( group, paragraph, params, lines )
	local wrapWidth = params.width

	-- An empty paragraph still takes a line's pitch but draws nothing.
	if not paragraph:find( "%S" ) then
		lines[#lines + 1] = false
		return
	end

	if not wrapWidth then
		lines[#lines + 1] = newLine( group, paragraph, params )
		return
	end

	local current, currentText = nil, nil

	for word in paragraph:gmatch( "%S+" ) do
		local candidateText = currentText and currentText .. " " .. word or word
		local candidate = newLine( group, candidateText, params )

		if current and candidate.width > wrapWidth then
			gameText.remove( candidate )
			lines[#lines + 1] = current
			current, currentText = newLine( group, word, params ), word
		else
			gameText.remove( current )
			current, currentText = candidate, candidateText
		end
	end

	lines[#lines + 1] = current
end

--------------------------------------------------------------------------------------
-- Public functions

function blockMethods.setFillColor( block, ... )
	local lines = block.lines

	for i = 1, #lines do
		if lines[i] then
			lines[i]:setFillColor( ... )
		end
	end
end

-- params: parent, text, x, y, font, fontSize, width (optional wrap width), align (left, center, right), anchorX, anchorY (default 0.5), colour, lineSpacing.
-- The returned group has text, lines (a text object per line, false for an empty one), blockWidth (the widest line), blockHeight, and setFillColor.
function textBlock.new( params )
	local group = display.newGroup()

	if params.parent then
		params.parent:insert( group )
	end

	local lines = {}

	for paragraph in ( params.text .. "\n" ):gmatch( "([^\n]*)\n" ) do
		addParagraph( group, paragraph, params, lines )
	end

	local blockWidth, lineHeight = 0, 0

	for i = 1, #lines do
		if lines[i] then
			blockWidth = max( blockWidth, lines[i].width )
			lineHeight = max( lineHeight, lines[i].height )
		end
	end

	local pitch = params.fontSize * ( params.lineSpacing or fonts.lineSpacing )
	local blockHeight = ( #lines - 1 ) * pitch + lineHeight
	local alignAnchor = alignAnchors[params.align or "left"]
	local left = -( params.anchorX or 0.5 ) * blockWidth
	local top = -( params.anchorY or 0.5 ) * blockHeight

	for i = 1, #lines do
		local line = lines[i]

		if line then
			line.anchorX = alignAnchor
			line.x = left + alignAnchor * blockWidth
			line.y = top + ( i - 1 ) * pitch
		end
	end

	group.x = params.x or 0
	group.y = params.y or 0
	group.text = params.text
	group.lines = lines
	group.blockWidth = blockWidth
	group.blockHeight = blockHeight
	group.setFillColor = blockMethods.setFillColor

	if params.colour then
		group:setFillColor( unpack( params.colour ) )
	end

	return group
end

return textBlock
