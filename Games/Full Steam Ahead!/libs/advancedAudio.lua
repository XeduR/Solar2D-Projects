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
--  © 2024-2025                            Last Updated: 29 Aug 2026   --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------

-- Advanced audio management module for Solar2D with channel management,
-- priority system, and audio type categorization. It uses filename strings
-- as handles to control audio. Require this module and call its functions in
-- place of Solar2D's stock audio API.

local advancedAudio = {}

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
local _isChannelActive = audio.isChannelActive

-------------------------------------------------------------------------

local totalChannels = 32

local audioHandle = {}
local audioCount = 0

-- Volume levels for each audio type
local typeVolume = {
	all = 1.0
}

-- Initialize audio channels with default settings
local audioChannels = {}
for i = 1, totalChannels do
	audioChannels[i] = {
		type = "all",
		priority = 0,
		startTime = 0,
		filename = nil
	}
end

-- Reusable sort function for channel prioritization
local function sortByPriorityAndTime( channelA, channelB )
	if channelA.priority == channelB.priority then
		return channelA.startTime < channelB.startTime
	end
	return channelA.priority < channelB.priority
end

-------------------------------------------------------------------------

-- Reset channel to idle state (priority 0 is the lowest, so idle channels evict first)
local function resetChannel( channelIndex )
	local channel = audioChannels[channelIndex]
	channel.priority = 0
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
function advancedAudio.assignChannelTypes( firstChannel, lastChannel, audioType )
	if type( firstChannel ) ~= "number" or type( lastChannel ) ~= "number" then
		print( "WARNING: assignChannelTypes requires numeric channel indices" )
		return false
	end

	if type( audioType ) ~= "string" then
		print( "WARNING: bad argument #3 to \"assignChannelTypes\" (string expected, got " .. type( audioType ) .. ")" )
		return false
	end

	if firstChannel < 1 or lastChannel > totalChannels or firstChannel > lastChannel then
		print( "WARNING: Invalid channel range (must be 1-" .. totalChannels .. " and firstChannel <= lastChannel)" )
		return false
	end

	-- Assign new type to channels
	for i = firstChannel, lastChannel do
		audioChannels[i].type = audioType
	end

	-- Create new type volume if this is a new type
	if not typeVolume[audioType] then
		typeVolume[audioType] = 1.0
	end

	-- Set volume for newly assigned channels
	for i = firstChannel, lastChannel do
		_setVolume( typeVolume[audioType], { channel = i } )
	end

	return true
end

-- List all channel types for debugging
function advancedAudio.listChannelTypes()
	local channelsByType = {}

	-- Group channels by type
	for i = 1, totalChannels do
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
			print( string.format( "  %s = %d-%d", audioType, channels[1], channels[#channels] ) )
		else
			print( string.format( "  %s = %s", audioType, table.concat( channels, ", " ) ) )
		end
	end
	print( "" )
end

-- Lists all audio handles created by the library
function advancedAudio.listAudioHandles()
	local noHandles = true
	print( "\nList of audio handles:\n" )
	for i, _ in pairs( audioHandle ) do
		print( "\t[\"" .. i .. "\"]" )
		noHandles = false
	end
	print( noHandles and "\tNo audio handles found.\n" or "" )
end

-- List active channels for debugging
function advancedAudio.listActiveChannels()
	print( "\nActive Channels:" )
	print( "================" )
	local hasActive = false

	for i = 1, totalChannels do
		if _isChannelActive( i ) then
			local channel = audioChannels[i]
			print( string.format( "  Channel %d: type=\"%s\", priority=%d, file=\"%s\", elapsed=%.2fs",
				i, channel.type, channel.priority, channel.filename or "unknown",
				( getTimer() - channel.startTime ) / 1000 ) )
			hasActive = true
		end
	end

	if not hasActive then
		print( "  No active channels" )
	end
	print( "" )
end

-------------------------------------------------------------------------

-- Load sound effect(s). Returns the filename (string) or the passed table so the
-- returned value works as a handle in the module's filename-as-handle scheme.
function advancedAudio.loadSound( filename, directory )
	directory = directory or system.ResourceDirectory

	if type( filename ) == "string" then
		if not audioHandle[filename] then
			audioHandle[filename] = _loadSound( filename, directory )
			audioCount = audioCount + 1
		end
		return filename
	elseif type( filename ) == "table" then
		for _, file in pairs( filename ) do
			if type( file ) == "string" and not audioHandle[file] then
				audioHandle[file] = _loadSound( file, directory )
				audioCount = audioCount + 1
			end
		end
		return filename
	else
		print( "WARNING: bad argument #1 to \"loadSound\" (string or table expected, got " .. type( filename ) .. ")" )
		return nil
	end
end

-- Load audio stream(s). Returns the filename (string) or the passed table so the
-- returned value works as a handle in the module's filename-as-handle scheme.
function advancedAudio.loadStream( filename, directory )
	directory = directory or system.ResourceDirectory

	if type( filename ) == "string" then
		if not audioHandle[filename] then
			audioHandle[filename] = _loadStream( filename, directory )
			audioCount = audioCount + 1
		end
		return filename
	elseif type( filename ) == "table" then
		for _, file in pairs( filename ) do
			if type( file ) == "string" and not audioHandle[file] then
				audioHandle[file] = _loadStream( file, directory )
				audioCount = audioCount + 1
			end
		end
		return filename
	else
		print( "WARNING: bad argument #1 to \"loadStream\" (string or table expected, got " .. type( filename ) .. ")" )
		return nil
	end
end

-- Find an idle channel for the audio type (paused channels count as occupied)
local function findAvailableChannel( audioType )
	for i = 1, totalChannels do
		local channel = audioChannels[i]
		if channel.type == audioType and not _isChannelActive( i ) then
			return i
		end
	end
	return nil
end

-- Find the lowest priority, oldest channel to evict (only called when no idle channel exists)
local function findLowestPriorityChannel( audioType )
	local candidates = {}

	-- Collect active channels of matching type as eviction candidates
	for i = 1, totalChannels do
		local channel = audioChannels[i]
		if channel.type == audioType and _isChannelActive( i ) then
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

	-- Sort lowest priority first, then oldest start time first
	sort( candidates, sortByPriorityAndTime )

	return candidates[1].index
end

-- Play audio with advanced channel management. Uses filename strings as handles
-- instead of requiring direct audio handle references
function advancedAudio.play( filename, options )
	-- Check if audio handle exists
	if not audioHandle[filename] then
		return 0
	end

	options = options or {}

	-- Copy the caller's options into a fresh table so the caller's table is never mutated
	local playOptions = {}
	for key, value in pairs( options ) do
		playOptions[key] = value
	end

	local audioType = playOptions.type or "all"
	local priority = playOptions.priority or 1
	local volumeMultiplier = playOptions.volume or 1
	local userOnComplete = playOptions.onComplete

	local channel

	if playOptions.channel then
		-- Caller requested a specific channel: honour it without auto-assign or eviction
		channel = playOptions.channel
		if type( channel ) ~= "number" or channel < 1 or channel > totalChannels then
			print( "WARNING: Invalid channel " .. tostring( channel ) .. " passed to play (must be a number 1-" .. totalChannels .. ")" )
			return 0
		end
		if _isChannelActive( channel ) then
			print( "WARNING: channel " .. channel .. " is already active" )
			return 0
		end
	else
		-- Find an idle channel for the given audio type
		channel = findAvailableChannel( audioType )

		-- If none is idle, evict the lowest priority, oldest sound of this type
		if not channel then
			channel = findLowestPriorityChannel( audioType )

			if channel then
				advancedAudio.stop( channel )
			else
				print( "WARNING: No channels available for audio type \"" .. audioType .. "\"" )
				return 0
			end
		end

		playOptions.channel = channel
	end

	-- Wrap onComplete so the channel resets when playback finishes
	playOptions.onComplete = function( event )
		resetChannel( channel )

		if type( userOnComplete ) == "function" then
			userOnComplete( event )
		end
	end

	-- Commit channel bookkeeping now that the play is going ahead
	audioChannels[channel].priority = priority
	audioChannels[channel].startTime = getTimer()
	audioChannels[channel].filename = filename

	-- Final volume from the type volume and the per-play multiplier
	local finalVolume = ( typeVolume[audioType] or 1.0 ) * volumeMultiplier
	_setVolume( finalVolume, { channel = channel } )

	return _play( audioHandle[filename], playOptions )
end

-------------------------------------------------------------------------

-- Stop audio and reset channel
function advancedAudio.stop( channelOrType )
	if type( channelOrType ) == "number" then
		local channel = channelOrType
		if channel >= 1 and channel <= totalChannels then
			_stop( channel )
			resetChannel( channel )
		end
	elseif type( channelOrType ) == "string" then
		-- Stop all channels of this type
		local audioType = channelOrType
		for i = 1, totalChannels do
			if audioChannels[i].type == audioType and _isChannelActive( i ) then
				_stop( i )
				resetChannel( i )
			end
		end
	else
		-- Stop every channel and clear all bookkeeping
		_stop( channelOrType )
		for i = 1, totalChannels do
			resetChannel( i )
		end
	end
end

-- Stop audio with delay and reset channel
function advancedAudio.stopWithDelay( duration, options )
	if type( options ) == "string" then
		-- Stop all channels of this type with delay
		local audioType = options
		for i = 1, totalChannels do
			if audioChannels[i].type == audioType and _isChannelActive( i ) then
				_stopWithDelay( duration, { channel = i } )
				local channel = i
				local scheduledFilename = audioChannels[i].filename
				timer.performWithDelay( duration, function()
					-- Only reset if the channel still holds the sound we scheduled
					if audioChannels[channel].filename == scheduledFilename then
						resetChannel( channel )
					end
				end, 1, "advancedAudio" )
			end
		end
	elseif type( options ) == "table" and options.channel then
		local channel = options.channel
		local result = _stopWithDelay( duration, options )

		if channel >= 1 and channel <= totalChannels then
			local scheduledFilename = audioChannels[channel].filename
			timer.performWithDelay( duration, function()
				-- Only reset if the channel still holds the sound we scheduled
				if audioChannels[channel].filename == scheduledFilename then
					resetChannel( channel )
				end
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

function advancedAudio.setVolume( volume, options )
	if type( options ) == "string" then
		-- Set volume for all channels of specific type
		local audioType = options
		typeVolume[audioType] = volume

		for i = 1, totalChannels do
			if audioChannels[i].type == audioType then
				_setVolume( volume, { channel = i } )
			end
		end
	else
		-- Standard behavior
		_setVolume( volume, options )
	end
end

function advancedAudio.setMaxVolume( volume, options )
	if type( options ) == "string" then
		-- Set max volume for all channels of specific type
		local audioType = options
		for i = 1, totalChannels do
			if audioChannels[i].type == audioType then
				_setMaxVolume( volume, { channel = i } )
			end
		end
	else
		-- Standard behavior
		_setMaxVolume( volume, options )
	end
end

function advancedAudio.setMinVolume( volume, options )
	if type( options ) == "string" then
		-- Set min volume for all channels of specific type
		local audioType = options
		for i = 1, totalChannels do
			if audioChannels[i].type == audioType then
				_setMinVolume( volume, { channel = i } )
			end
		end
	else
		-- Standard behavior
		_setMinVolume( volume, options )
	end
end

function advancedAudio.getVolume( options )
	if type( options ) == "string" then
		-- Get the configured volume for an audio type
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

function advancedAudio.getMaxVolume( options )
	if type( options ) == "string" then
		-- Get max volume for first channel of specific type
		local audioType = options
		for i = 1, totalChannels do
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

function advancedAudio.getMinVolume( options )
	if type( options ) == "string" then
		-- Get min volume for first channel of specific type
		local audioType = options
		for i = 1, totalChannels do
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

function advancedAudio.rewind( arg )
	arg = type( arg ) == "string" and audioHandle[arg] or arg
	return _rewind( arg )
end

function advancedAudio.seek( time, arg )
	arg = type( arg ) == "string" and audioHandle[arg] or arg
	return _seek( time, arg )
end

function advancedAudio.getDuration( filename )
	if audioHandle[filename] then
		return _getDuration( audioHandle[filename] )
	end
end

function advancedAudio.dispose( filename )
	if audioHandle[filename] then
		-- Stop and reset any channel still playing this handle before disposing
		for i = 1, totalChannels do
			if audioChannels[i].filename == filename then
				advancedAudio.stop( i )
			end
		end

		_dispose( audioHandle[filename] )
		audioHandle[filename] = nil
		audioCount = audioCount - 1
	end
end

function advancedAudio.disposeAll()
	-- Stop and reset any channel still playing a handle before disposing
	for i = 1, totalChannels do
		if audioChannels[i].filename then
			advancedAudio.stop( i )
		end
	end

	for _, handle in pairs( audioHandle ) do
		_dispose( handle )
	end
	audioCount = 0
	audioHandle = {}
end

return advancedAudio
