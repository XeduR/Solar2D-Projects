-- Loads Aseprite exports (a sheet JSON with its PNG, or a lone PNG) and builds images, sprites and nine-slices from them.

-- XXX / TODO: see about writing a better/more streamlined Aseprite importer/wrapper for Solar2D at some point.

local sheets = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local json = require( "json" )
local config = require( "data.art" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local cache = {}

--------------------------------------------------------------------------------------
-- Localised functions

local max = math.max
local tonumber = tonumber

--------------------------------------------------------------------------------------
-- Private functions

-- Aseprite names frames "<title> <number>.<extension>", with no number for a single frame.
-- A JSON hash of frames decodes in no set order, so that number puts them back in export order.
local function frameOrder( name )
	return tonumber( name:match( " (%d+)%.[^%.]*$" ) or name:match( " (%d+)$" ) ) or 0
end

-- Returns { name, entry } per frame in export order, from either the hash or the array form.
local function orderedFrames( frames )
	local list = {}

	if #frames > 0 then
		for i = 1, #frames do
			list[i] = { name = frames[i].filename, entry = frames[i] }
		end

		return list
	end

	for name, entry in pairs( frames ) do
		list[#list + 1] = { name = name, entry = entry }
	end

	table.sort( list, function( first, second )
		local firstOrder, secondOrder = frameOrder( first.name ), frameOrder( second.name )
		if firstOrder ~= secondOrder then
			return firstOrder < secondOrder
		end

		return first.name < second.name
	end )

	return list
end

-- A PNG's width and height are 4-byte big-endian numbers at bytes 17-24, in its first chunk.
local function readPNGSize( path )
	local file = io.open( path, "rb" )
	if not file then
		return nil
	end

	local header = file:read( 24 )
	file:close()

	if not header or #header < 24 or header:sub( 2, 4 ) ~= "PNG" then
		return nil
	end

	local function bigEndian( offset )
		local first, second, third, fourth = header:byte( offset, offset + 3 )
		return ( ( first * 256 + second ) * 256 + third ) * 256 + fourth
	end

	return bigEndian( 17 ), bigEndian( 21 )
end

-- With inner padding, the trimmed image sits centred inside Aseprite's frame rect.
-- spriteSourceSize is where that image sat on the untrimmed canvas, so subtracting it gives the canvas's top-left on the sheet.
local function frameGeometry( entry )
	local rect = entry.frame
	local trim = entry.spriteSourceSize or { x = 0, y = 0, w = rect.w, h = rect.h }
	local canvas = entry.sourceSize or { w = trim.w, h = trim.h }

	local imageX = rect.x + ( rect.w - trim.w ) * 0.5
	local imageY = rect.y + ( rect.h - trim.h ) * 0.5

	return { imageX = imageX, imageY = imageY, trim = trim, canvas = canvas, originX = imageX - trim.x, originY = imageY - trim.y }
end

-- Frame rects are in content units on a sheet scaled up by pixelScale, so images draw at the art scale with no further scaling.
local function sheetFrame( geometry, scale )
	local trim, canvas = geometry.trim, geometry.canvas
	local frame = { x = geometry.imageX * scale, y = geometry.imageY * scale, width = trim.w * scale, height = trim.h * scale }

	if trim.x ~= 0 or trim.y ~= 0 or trim.w ~= canvas.w or trim.h ~= canvas.h then
		frame.sourceX = trim.x * scale
		frame.sourceY = trim.y * scale
		frame.sourceWidth = canvas.w * scale
		frame.sourceHeight = canvas.h * scale
	end

	return frame
end

-- One cycle in play order: reverse directions start at the last frame, and pingpong turns back without repeating either end frame.
local function playOrder( first, last, direction )
	local isReversed = direction == "reverse" or direction == "pingpong_reverse"
	local from, to, step = first, last, 1

	if isReversed then
		from, to, step = last, first, -1
	end

	local frames = {}
	for frame = from, to, step do
		frames[#frames + 1] = frame
	end

	if direction == "pingpong" or direction == "pingpong_reverse" then
		for frame = to - step, from + step, -step do
			frames[#frames + 1] = frame
		end
	end

	return frames
end

-- frames and durations are parallel lists: the sheet frame index and its duration at each step of one cycle.
local function newTag( first, last, direction, durations )
	local frames = playOrder( first, last, direction )

	local tagDurations = {}
	for i = 1, #frames do
		tagDurations[i] = durations[frames[i]]
	end

	return { first = first, count = last - first + 1, direction = direction, frames = frames, durations = tagDurations }
end

local function readTags( meta, durations )
	local tags = {}
	local frameTags = meta.frameTags or {}

	for i = 1, #frameTags do
		local tag = frameTags[i]
		tags[tag.name] = newTag( tag.from + 1, tag.to + 1, tag.direction or "forward", durations )
	end

	return tags
end

-- Only each slice's first key is read, in art pixels on the canvas.
-- The first slice with a 9-slice centre becomes the sheet's nine-slice; Aseprite gives that centre relative to the slice bounds.
local function readSlices( meta )
	local slices, nineSlice = {}, nil
	local metaSlices = meta.slices or {}

	for i = 1, #metaSlices do
		local key = metaSlices[i].keys and metaSlices[i].keys[1]
		if key then
			local bounds, center = key.bounds, key.center
			slices[metaSlices[i].name] = { bounds = bounds, center = center, pivot = key.pivot }

			if center and not nineSlice then
				nineSlice = {
					name = metaSlices[i].name,
					bounds = bounds,
					columns = { center.x, center.w, bounds.w - center.x - center.w },
					rows = { center.y, center.h, bounds.h - center.y - center.h },
				}
			end
		end
	end

	return slices, nineSlice
end

-- Appends the nine pieces of every frame to the sheet frames; a piece with no width or height gets no frame and stays false in its slot.
local function addPieceFrames( frames, ordered, nineSlice, scale )
	local bounds, columns, rows = nineSlice.bounds, nineSlice.columns, nineSlice.rows
	local columnStart = { bounds.x, bounds.x + columns[1], bounds.x + columns[1] + columns[2] }
	local rowStart = { bounds.y, bounds.y + rows[1], bounds.y + rows[1] + rows[2] }
	local pieceFrames = {}

	for i = 1, #ordered do
		local originX, originY = ordered[i].geometry.originX, ordered[i].geometry.originY
		local slots = {}

		for row = 1, 3 do
			for column = 1, 3 do
				local slot = ( row - 1 ) * 3 + column
				slots[slot] = false

				if columns[column] > 0 and rows[row] > 0 then
					frames[#frames + 1] = {
						x = ( originX + columnStart[column] ) * scale,
						y = ( originY + rowStart[row] ) * scale,
						width = columns[column] * scale,
						height = rows[row] * scale,
					}
					slots[slot] = #frames
				end
			end
		end

		pieceFrames[i] = slots
	end

	return pieceFrames
end

local function frameSize( sheet, index )
	local frame = sheet.frames[index]

	return frame.sourceWidth or frame.width, frame.sourceHeight or frame.height
end

-- Error level 3 points the errors at the caller of sheets.load.
local function loadSheet( key, folder, jsonPath )
	local data = json.decodeFile( jsonPath )
	if type( data ) ~= "table" or type( data.frames ) ~= "table" or type( data.meta ) ~= "table" then
		error( "sheets: cannot read " .. key .. ".json", 3 )
	end

	local ordered = orderedFrames( data.frames )
	if #ordered == 0 then
		error( "sheets: " .. key .. ".json has no frames", 3 )
	end

	local scale = config.pixelScale
	local frames, durations, frameIndex = {}, {}, {}

	for i = 1, #ordered do
		local entry = ordered[i].entry
		ordered[i].geometry = frameGeometry( entry )
		frames[i] = sheetFrame( ordered[i].geometry, scale )
		durations[i] = entry.duration or config.defaultFrameDuration
		frameIndex[ordered[i].name] = i
	end

	local slices, nineSlice = readSlices( data.meta )
	if nineSlice then
		nineSlice.pieceFrames = addPieceFrames( frames, ordered, nineSlice, scale )
	end

	local imagePath = folder .. data.meta.image
	local sheetContentWidth = data.meta.size.w * scale
	local sheetContentHeight = data.meta.size.h * scale
	local imageSheet = graphics.newImageSheet( imagePath, system.ResourceDirectory, {
		frames = frames,
		sheetContentWidth = sheetContentWidth,
		sheetContentHeight = sheetContentHeight,
	} )

	if not imageSheet then
		error( "sheets: cannot load image " .. imagePath, 3 )
	end

	local sheet = {
		key = key,
		isSingle = false,
		imageSheet = imageSheet,
		imagePath = imagePath,
		sheetContentWidth = sheetContentWidth,
		sheetContentHeight = sheetContentHeight,
		frames = frames,
		frameCount = #ordered,
		frameIndex = frameIndex,
		tags = readTags( data.meta, durations ),
		slices = slices,
		nineSlice = nineSlice,
	}

	sheet.frameWidth, sheet.frameHeight = frameSize( sheet, 1 )

	return sheet
end

local function loadSingle( key, imagePath, pngPath )
	local width, height = readPNGSize( pngPath )
	if not width then
		error( "sheets: cannot read the PNG size of " .. imagePath, 3 )
	end

	return {
		key = key,
		isSingle = true,
		imagePath = imagePath,
		frameCount = 1,
		frameWidth = width * config.pixelScale,
		frameHeight = height * config.pixelScale,
		frameIndex = {},
		tags = {},
		slices = {},
	}
end

-- frame is a 1-based index, a frame name from the JSON, or a tag name for that tag's first frame; nil means the first frame.
local function resolveFrame( sheet, frame )
	local index = frame or 1

	if type( frame ) == "string" then
		local tag = sheet.tags[frame]
		index = sheet.frameIndex[frame] or tag and tag.first
	end

	if type( index ) ~= "number" or index < 1 or index > sheet.frameCount or index % 1 ~= 0 then
		error( "sheets: no frame '" .. tostring( frame ) .. "' in " .. sheet.key, 3 )
	end

	return index
end

-- The sequence loops the tag's cycle forward forever; time is the whole cycle's length, because a sequence splits it evenly over its frames.
local function sequenceFor( name, tag )
	local time = 0
	for i = 1, #tag.durations do
		time = time + tag.durations[i]
	end

	return { name = name, frames = tag.frames, time = time, loopCount = 0, loopDirection = "forward" }
end

local function buildPieces( group )
	local sheet = group.sheet
	local slots = sheet.nineSlice.pieceFrames[group.frame]

	for slot = 1, 9 do
		if group.pieces[slot] then
			display.remove( group.pieces[slot] )
		end

		group.pieces[slot] = false

		local index = slots[slot]
		if index then
			local frame = sheet.frames[index]
			group.pieces[slot] = display.newImageRect( group, sheet.imageSheet, index, frame.width, frame.height )
		end
	end
end

-- Corners keep their art size; edges and the centre stretch by setting xScale and yScale against each piece's own size.
local function layoutPieces( group )
	local width, height = group.sliceWidth, group.sliceHeight
	local nineSlice = group.sheet.nineSlice

	local scale = config.pixelScale
	local left, right = nineSlice.columns[1] * scale, nineSlice.columns[3] * scale
	local top, bottom = nineSlice.rows[1] * scale, nineSlice.rows[3] * scale

	local columnWidth = { left, max( 0, width - left - right ), right }
	local rowHeight = { top, max( 0, height - top - bottom ), bottom }
	local columnX = { ( left - width ) * 0.5, ( left - right ) * 0.5, ( width - right ) * 0.5 }
	local rowY = { ( top - height ) * 0.5, ( top - bottom ) * 0.5, ( height - bottom ) * 0.5 }

	for row = 1, 3 do
		for column = 1, 3 do
			local piece = group.pieces[( row - 1 ) * 3 + column]
			if piece then
				local pieceWidth, pieceHeight = columnWidth[column], rowHeight[row]
				piece.x, piece.y = columnX[column], rowY[row]
				piece.isVisible = pieceWidth > 0 and pieceHeight > 0

				if piece.isVisible then
					piece.xScale, piece.yScale = pieceWidth / piece.width, pieceHeight / piece.height
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- Public functions

function sheets.applyTextureDefaults()
	display.setDefault( "magTextureFilter", config.magTextureFilter )
	display.setDefault( "minTextureFilter", config.minTextureFilter )
end

-- frameWidth and frameHeight are in content units (art pixels times pixelScale); slice bounds and centres stay in art pixels.
function sheets.load( family, name )
	local key = family .. "/" .. name

	if cache[key] then
		return cache[key]
	end

	local folder = config.imageRoot .. family .. "/"
	local imagePath = folder .. name .. ".png"
	local pngPath = system.pathForFile( imagePath, system.ResourceDirectory )

	if not pngPath then
		error( "sheets: cannot find " .. imagePath, 2 )
	end

	-- io.open checks for the JSON because system.pathForFile would print a missing-file warning for every lone PNG.
	local jsonPath = pngPath:sub( 1, -5 ) .. ".json"
	local jsonFile = io.open( jsonPath, "r" )

	local sheet

	if jsonFile then
		jsonFile:close()
		sheet = loadSheet( key, folder, jsonPath )
	else
		sheet = loadSingle( key, imagePath, pngPath )
	end

	cache[key] = sheet

	return sheet
end

-- parent may be nil; the image is centred on its anchor at pixelScale.
function sheets.newImage( parent, family, name, frame )
	local sheet = sheets.load( family, name )
	local index = resolveFrame( sheet, frame )

	if sheet.isSingle then
		local image
		if parent then
			image = display.newImage( parent, sheet.imagePath, system.ResourceDirectory )
		else
			image = display.newImage( sheet.imagePath, system.ResourceDirectory )
		end

		if not image then
			error( "sheets: cannot load image " .. sheet.imagePath, 2 )
		end

		image.xScale, image.yScale = config.pixelScale, config.pixelScale

		return image
	end

	local width, height = frameSize( sheet, index )

	if parent then
		return display.newImageRect( parent, sheet.imageSheet, index, width, height )
	end

	return display.newImageRect( sheet.imageSheet, index, width, height )
end

-- One sequence per tag, picked and ordered by sequenceNames or every tag by default; a sheet with no tags gets one "default" sequence.
function sheets.newSprite( parent, family, name, sequenceNames )
	local sheet = sheets.load( family, name )

	if sheet.isSingle then
		error( "sheets: " .. sheet.key .. " is a single image, not a sheet", 2 )
	end

	local sequences = {}
	if sequenceNames then
		for i = 1, #sequenceNames do
			local tag = sheet.tags[sequenceNames[i]]
			if not tag then
				error( "sheets: no tag '" .. tostring( sequenceNames[i] ) .. "' in " .. sheet.key, 2 )
			end
			sequences[#sequences + 1] = sequenceFor( sequenceNames[i], tag )
		end

	else
		local tagNames = {}

		for tagName in pairs( sheet.tags ) do
			tagNames[#tagNames + 1] = tagName
		end

		table.sort( tagNames, function( first, second )
			local firstTag, secondTag = sheet.tags[first], sheet.tags[second]

			if firstTag.first ~= secondTag.first then
				return firstTag.first < secondTag.first
			end

			return first < second
		end )

		for i = 1, #tagNames do
			sequences[#sequences + 1] = sequenceFor( tagNames[i], sheet.tags[tagNames[i]] )
		end
	end

	if #sequences == 0 then
		local durations = {}

		for i = 1, sheet.frameCount do
			durations[i] = config.defaultFrameDuration
		end

		sequences[1] = sequenceFor( "default", newTag( 1, sheet.frameCount, "forward", durations ) )
	end

	if parent then
		return display.newSprite( parent, sheet.imageSheet, sequences )
	end

	return display.newSprite( sheet.imageSheet, sequences )
end

-- Built from the sheet's first slice with a 9-slice centre; width and height are in content units, and the group's origin is its centre.
function sheets.newNineSlice( parent, family, name, width, height, frame )
	local sheet = sheets.load( family, name )

	if not sheet.nineSlice then
		error( "sheets: " .. sheet.key .. " has no slice with a nine-patch centre", 2 )
	end

	local group = display.newGroup()
	if parent then
		parent:insert( group )
	end

	group.sheet = sheet
	group.pieces = {}
	group.frame = resolveFrame( sheet, frame )
	buildPieces( group )

	function group:resize( newWidth, newHeight )
		self.sliceWidth, self.sliceHeight = newWidth, newHeight
		layoutPieces( self )
	end

	function group:setFrame( frameOrTagName )
		self.frame = resolveFrame( self.sheet, frameOrTagName )
		buildPieces( self )
		layoutPieces( self )
	end

	group:resize( width, height )

	return group
end

return sheets
