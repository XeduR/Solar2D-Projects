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
--  © 2024-2025                            Last Updated: 27 Nov 2025   --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------

-- Advanced audio management library for Solar2D with channel management,
-- priority system, and audio type categorization. It handles audio handle
-- references and uses filename strings as handles to control audio.

-------------------------------------------------------------------------
-- IMPORTANT! This library overwrites Solar2D's standard audio functions.
-------------------------------------------------------------------------

local getTimer = system.getTimer
local sort = table.sort
local pairs = pairs
local type = type

-- Localize audio functions
local _dispose = audio.dispose
local _getDuration = audio.getDuration
local _loadSound = audio.loadSound
local _loadStream = audio.loadStream
local _play = audio.play
local _rewind = audio.rewind
local _seek = audio.seek
local _stop = audio.stop
local _stopWithDelay = audio.stopWithDelay
local _setVolume = audio.setVolume
local _setMaxVolume = audio.setMaxVolume
local _setMinVolume = audio.setMinVolume
local _getVolume = audio.getVolume
local _getMaxVolume = audio.getMaxVolume
local _getMinVolume = audio.getMinVolume
local _isChannelPlaying = audio.isChannelPlaying

-------------------------------------------------------------------------

local audioHandle = {}
local audioCount = 0

-- Volume levels for each audio type
local typeVolume = {
	all = 1.0
}

-- Initialize 32 audio channels with default settings
local audioChannels = {}
for i = 1, 32 do
	audioChannels[i] = {
		type = "all",
		priority = math.huge,
		startTime = 0,
		filename = nil
	}
end

-- Reusable sort function for channel prioritization
local function sortByPriorityAndTime( a, b )
	if a.priority == b.priority then
		return a.startTime < b.startTime
	end
	return a.priority > b.priority
end

-------------------------------------------------------------------------

-- Reset channel to default state
local function resetChannel( channelIndex )
	local channel = audioChannels[channelIndex]
	channel.priority = math.huge
	channel.startTime = 0
	channel.filename = nil

	-- Restore type volume
	local channelType = channel.type
	local channelVolume = typeVolume[channelType]
	if channelVolume then
		_setVolume( channelVolume, { channel = channelIndex } )
	end
end

-------------------------------------------------------------------------

-- Assign audio types to specific channel ranges
function audio.assignChannelTypes( firstChannel, lastChannel, audioType )
	if type( firstChannel ) ~= "number" or type( lastChannel ) ~= "number" then
		print( "WARNING: assignChannelTypes requires numeric channel indices" )
		return false
	end

	if type( audioType ) ~= "string" then
		print( "WARNING: bad argument #3 to \"assignChannelTypes\" (string expected, got " .. type( audioType ) .. ")" )
		return false
	end

	if firstChannel < 1 or lastChannel > 32 or firstChannel > lastChannel then
		print( "WARNING: Invalid channel range (must be 1-32 and firstChannel <= lastChannel)" )
		return false
	end

	-- Track which types exist after this assignment
	local typesInUse = {}

	-- Assign new type to channels
	for i = firstChannel, lastChannel do
		audioChannels[i].type = audioType
		typesInUse[audioType] = true
	end

	-- Check all other channels for their types
	for i = 1, 32 do
		if i < firstChannel or i > lastChannel then
			typesInUse[audioChannels[i].type] = true
		end
	end

	-- Create new type volume if this is a new type
	if not typeVolume[audioType] then
		typeVolume[audioType] = 1.0
	end

	-- Remove types that no longer have channels
	for audioTypeKey, _ in pairs( typeVolume ) do
		if not typesInUse[audioTypeKey] then
			typeVolume[audioTypeKey] = nil
		end
	end

	-- Set volume for newly assigned channels
	for i = firstChannel, lastChannel do
		_setVolume( typeVolume[audioType], { channel = i } )
	end

	return true
end

-- List all channel types for debugging
function audio.listChannelTypes()
	local channelsByType = {}

	-- Group channels by type
	for i = 1, 32 do
		local channelType = audioChannels[i].type
		if not channelsByType[channelType] then
			channelsByType[channelType] = {}
		end
		channelsByType[channelType][#channelsByType[channelType] + 1] = i
	end

	print( "\nChannel Types:" )
	print( "==============" )

	-- Sort and display each type
	for audioType, channels in pairs( channelsByType ) do
		sort( channels )

		-- Check if channels are consecutive
		local isConsecutive = true
		for i = 2, #channels do
			if channels[i] ~= channels[i-1] + 1 then
				isConsecutive = false
				break
			end
		end

		-- Format output
		if isConsecutive and #channels > 1 then
			print(string.format("  %s = %d-%d", audioType, channels[1], channels[#channels]))
		else
			print(string.format("  %s = %s", audioType, table.concat(channels, ", ")))
		end
	end
	print( "" )
end

-- Lists all audio handles created by the library
function audio.listAudioHandles()
	local noHandles = true
	print( "\nList of audio handles:\n" )
	for i, _ in pairs( audioHandle ) do
		print( "\t[\"" .. i .. "\"]" )
		noHandles = false
	end
	print( noHandles and "\tNo audio handles found.\n" or "" )
end

-- List active channels for debugging
function audio.listActiveChannels()
	print( "\nActive Channels:" )
	print( "================" )
	local hasActive = false

	for i = 1, 32 do
		if _isChannelPlaying(i) then
			local ch = audioChannels[i]
			print(string.format("  Channel %d: type=\"%s\", priority=%d, file=\"%s\", elapsed=%.2fs",
				i, ch.type, ch.priority, ch.filename or "unknown",
				(getTimer() - ch.startTime) / 1000))
			hasActive = true
		end
	end

	if not hasActive then
		print( "  No active channels" )
	end
	print( "" )
end

-------------------------------------------------------------------------

-- Load sound effect(s)
function audio.loadSound( filename, directory )
	directory = directory or system.ResourceDirectory

	if type( filename ) == "string" then
		if not audioHandle[filename] then
			audioHandle[filename] = _loadSound( filename, directory )
			audioCount = audioCount + 1
		end
	elseif type( filename ) == "table" then
		for _, file in pairs( filename ) do
			if type( file ) == "string" and not audioHandle[file] then
				audioHandle[file] = _loadSound( file, directory )
				audioCount = audioCount + 1
			end
		end
	else
		print( "WARNING: bad argument #1 to \"loadSound\" (string or table expected, got " .. type( filename ) .. ")" )
	end
end

-- Load audio stream(s)
function audio.loadStream( filename, directory )
	directory = directory or system.ResourceDirectory

	if type( filename ) == "string" then
		if not audioHandle[filename] then
			audioHandle[filename] = _loadStream( filename, directory )
			audioCount = audioCount + 1
		end
	elseif type( filename ) == "table" then
		for _, file in pairs( filename ) do
			if type( file ) == "string" and not audioHandle[file] then
				audioHandle[file] = _loadStream( file, directory )
				audioCount = audioCount + 1
			end
		end
	else
		print( "WARNING: bad argument #1 to \"loadStream\" (string or table expected, got " .. type( filename ) .. ")" )
	end
end

-- Find available channel for audio type
local function findAvailableChannel( audioType )
	for i = 1, 32 do
		local channel = audioChannels[i]
		if channel.type == audioType and not _isChannelPlaying( i ) then
			return i
		end
	end
	return nil
end

-- Find lowest priority oldest channel (only called when no free channels exist)
local function findLowestPriorityChannel( audioType )
	local candidates = {}

	-- Collect all channels of matching type (all are playing, already verified)
	for i = 1, 32 do
		local channel = audioChannels[i]
		if channel.type == audioType then
			candidates[#candidates + 1] = {
				index = i,
				priority = channel.priority,
				startTime = channel.startTime
			}
		end
	end

	if #candidates == 0 then
		return nil
	end

	-- Sort by priority (highest number = lowest priority), then by startTime (oldest first)
	sort( candidates, sortByPriorityAndTime )

	return candidates[1].index
end

-- Play audio with advanced channel management. Uses filename strings as handles
-- instead of requiring direct audio handle references
function audio.play( filename, options )
	-- Check if audio handle exists
	if not audioHandle[filename] then
		return 0
	end

	-- Set up options
	options = options or {}
	local audioType = options.type or "all"
	local priority = options.priority or 1
	local volumeMultiplier = options.volume or 1
	local userOnComplete = options.onComplete

	-- Find available channel for the given audio type
	local channel = findAvailableChannel( audioType )

	-- If no channel is available, then find the the lowest priority sound available
	if not channel then
		channel = findLowestPriorityChannel( audioType )

		-- Stop the oldest and lowest priority sound
		if channel then
			audio.stop( channel )
		else
			print( "WARNING: No channels available for audio type \"" .. audioType .. "\"" )
			return 0
		end
	end

	-- Calculate final volume based on type volume and multiplier
	local baseVolume = typeVolume[audioType] or 1.0
	local finalVolume = baseVolume * volumeMultiplier

	-- Update options with channel
	options.channel = channel

	-- Create wrapper onComplete that resets channel and calls user callback
	options.onComplete = function( event )
		-- Reset channel data and restore volume
		resetChannel( channel )

		-- Call user's onComplete if provided
		if type( userOnComplete ) == "function" then
			userOnComplete( event )
		end
	end

	-- Update channel data
	audioChannels[channel].priority = priority
	audioChannels[channel].startTime = getTimer()
	audioChannels[channel].filename = filename

	-- Set volume before playing
	_setVolume( finalVolume, { channel = channel } )

	-- Play the audio
	return _play( audioHandle[filename], options )
end

-------------------------------------------------------------------------

-- Stop audio and reset channel
function audio.stop( channelOrType )
	if type( channelOrType ) == "number" then
		local channel = channelOrType
		if channel >= 1 and channel <= 32 then
			_stop( channel )
			resetChannel( channel )
		end
	elseif type( channelOrType ) == "string" then
		-- Stop all channels of this type
		local audioType = channelOrType
		for i = 1, 32 do
			if audioChannels[i].type == audioType and _isChannelPlaying( i ) then
				_stop( i )
				resetChannel( i )
			end
		end
	else
		_stop( channelOrType )
	end
end

-- Stop audio with delay and reset channel
function audio.stopWithDelay( duration, options )
	if type( options ) == "string" then
		-- Stop all channels of this type with delay
		local audioType = options
		for i = 1, 32 do
			if audioChannels[i].type == audioType and _isChannelPlaying( i ) then
				_stopWithDelay( duration, { channel = i } )
				timer.performWithDelay( duration, function()
					resetChannel( i )
				end, 1, "advancedAudio" )
			end
		end
	elseif type( options ) == "table" and options.channel then
		local channel = options.channel
		local result = _stopWithDelay( duration, options )

		if channel >= 1 and channel <= 32 then
			timer.performWithDelay( duration, function()
				resetChannel( channel )
			end, 1, "advancedAudio" )
		end

		return result
	else
		-- Default behavior - stop all channels
		return _stopWithDelay( duration, options )
	end
end

-------------------------------------------------------------------------

-- Volume management with audio type support

function audio.setVolume( volume, options )
	if type( options ) == "string" then
		-- Set volume for all channels of specific type
		local audioType = options
		typeVolume[audioType] = volume

		for i = 1, 32 do
			if audioChannels[i].type == audioType then
				_setVolume( volume, { channel = i } )
			end
		end
	else
		-- Standard behavior
		_setVolume( volume, options )
	end
end

function audio.setMaxVolume( volume, options )
	if type( options ) == "string" then
		-- Set max volume for all channels of specific type
		local audioType = options
		for i = 1, 32 do
			if audioChannels[i].type == audioType then
				_setMaxVolume( volume, { channel = i } )
			end
		end
	else
		-- Standard behavior
		_setMaxVolume( volume, options )
	end
end

function audio.setMinVolume( volume, options )
	if type( options ) == "string" then
		-- Set min volume for all channels of specific type
		local audioType = options
		for i = 1, 32 do
			if audioChannels[i].type == audioType then
				_setMinVolume( volume, { channel = i } )
			end
		end
	else
		-- Standard behavior
		_setMinVolume( volume, options )
	end
end

function audio.getVolume( options )
	if type( options ) == "string" then
		-- Get volume for audio type
		local audioType = options
		if typeVolume[audioType] then
			return typeVolume[audioType]
		end
		-- No volume found for this type
		return 0, "invalidChannelType"
	else
		-- Standard behavior
		return _getVolume( options )
	end
end

function audio.getMaxVolume( options )
	if type( options ) == "string" then
		-- Get max volume for first channel of specific type
		local audioType = options
		for i = 1, 32 do
			if audioChannels[i].type == audioType then
				return _getMaxVolume( { channel = i } )
			end
		end
		-- No channel found for this type
		return 0, "invalidChannelType"
	else
		-- Standard behavior
		return _getMaxVolume( options )
	end
end

function audio.getMinVolume( options )
	if type( options ) == "string" then
		-- Get min volume for first channel of specific type
		local audioType = options
		for i = 1, 32 do
			if audioChannels[i].type == audioType then
				return _getMinVolume( { channel = i } )
			end
		end
		-- No channel found for this type
		return 0, "invalidChannelType"
	else
		-- Standard behavior
		return _getMinVolume( options )
	end
end

-------------------------------------------------------------------------

-- Standard audio functions
-- (unchanged, except for using filename strings as handles)

function audio.rewind( arg )
	arg = type( arg ) == "string" and audioHandle[arg] or arg
	return _rewind( arg )
end

function audio.seek( time, arg )
	arg = type( arg ) == "string" and audioHandle[arg] or arg
	return _seek( time, arg )
end

function audio.getDuration( filename )
	if audioHandle[filename] then
		return _getDuration( audioHandle[filename] )
	end
end

function audio.dispose( filename )
	if audioHandle[filename] then
		_dispose( audioHandle[filename] )
		audioHandle[filename] = nil
		audioCount = audioCount - 1
		if audioCount == 0 then
			audioHandle = {}
		end
	end
end

function audio.disposeAll()
	for _, handle in pairs( audioHandle ) do
		_dispose( handle )
	end
	audioCount = 0
	audioHandle = {}
end
