-- Sound effects, captain babble, continuous loop layers and the tempo-following music.

local sound = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local advancedAudio = require( "libs.advancedAudio" )
local config = require( "data.sound" )
local bgmTempos = require( "data.bgmTempos" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local tempoConfig = config.tempo
local tempos = bgmTempos.tempos

-- Seconds of update( dt ) time, which drives the retrigger intervals.
local clock = 0

local effects = {}
local nextPlayTimes = {}
local babbleFiles = {}

local layers = {}
local layersByName = {}
local loopsPaused = false

-- Slider volume per channel type, and the gain each channel plays at under it.
local typeVolumes = { music = 1, loop = 1, babble = 1, sfx = 1 }
local channelTypes = {}
local channelGains = {}

local musicVoices = {}
local currentVoice
local musicLevel = 1
local musicLevelTarget = 1
local musicLevelRate = 0
local targetIndex = 1
local sinceSwitch = 0
local tempoFiles = {}

--------------------------------------------------------------------------------------
-- Localised functions

local exp = math.exp
local max = math.max
local min = math.min
local format = string.format
local getTimer = system.getTimer

--------------------------------------------------------------------------------------
-- Private functions

local function sfxPath( name )
	return format( config.sfxPath, name )
end

local function bgmPath( index )
	return format( config.bgmPath, tempos[index] )
end

local function loopSeconds( index )
	return bgmTempos.beatsPerLoop * 60 / tempos[index]
end

local function approach( value, target, step )
	if value < target then
		return min( target, value + step )
	end

	return max( target, value - step )
end

local function applyChannelVolume( channel )
	advancedAudio.setVolume( typeVolumes[channelTypes[channel]] * channelGains[channel], { channel = channel } )
end

local function assignChannels( firstChannel, count, typeName )
	local lastChannel = firstChannel + count - 1

	advancedAudio.assignChannelTypes( firstChannel, lastChannel, typeName )

	for channel = firstChannel, lastChannel do
		channelTypes[channel] = typeName
		channelGains[channel] = 1
	end

	return lastChannel + 1
end

local function setupChannels()
	local nextChannel = 1
	local channelCounts = config.channels

	for i = 1, channelCounts.music do
		musicVoices[i] = { channel = nextChannel + i - 1, gain = 0, target = 0, isPlaying = false }
	end
	nextChannel = assignChannels( nextChannel, channelCounts.music, "music" )

	for i = 1, #config.layers do
		local layerConfig = config.layers[i]
		local filename = advancedAudio.loadSound( sfxPath( layerConfig.file ) )
		local layer = { config = layerConfig, filename = filename, channel = nextChannel, level = 0, target = 0, isPlaying = false }

		nextChannel = assignChannels( nextChannel, 1, "loop" )
		layers[i] = layer
		layersByName[layerConfig.name] = layer
	end

	nextChannel = assignChannels( nextChannel, channelCounts.babble, "babble" )
	assignChannels( nextChannel, channelCounts.sfx, "sfx" )
end

local function loadEffects()
	for name, effectConfig in pairs( config.effects ) do
		local files = {}

		for i = 1, #effectConfig.files do
			files[i] = advancedAudio.loadSound( sfxPath( effectConfig.files[i] ) )
		end

		effects[name] = { files = files, thresholds = effectConfig.thresholds or {}, volume = effectConfig.volume, interval = effectConfig.interval }
	end

	local babbleConfig = config.babble

	-- Indexed by anger tier from 1, since tier 0 lines play no babble.
	for tier = 1, #babbleConfig.voices do
		babbleFiles[tier] = {}

		for length = 1, #babbleConfig.lengths do
			local name = format( babbleConfig.file, babbleConfig.voices[tier], babbleConfig.lengths[length] )

			babbleFiles[tier][length] = advancedAudio.loadSound( sfxPath( name ) )
		end
	end
end

-- Index of the band a value falls in, where each threshold starts the next band.
local function bandIndex( thresholds, value )
	local index = 1

	for i = 1, #thresholds do
		if value >= thresholds[i] then
			index = i + 1
		end
	end

	return index
end

local function playOneShot( filename, typeName, volume )
	local channel = advancedAudio.play( filename, { type = typeName, volume = volume } )

	if channel and channel > 0 then
		channelGains[channel] = volume
	end
end

--------------------------------------------------------------------------------------
-- Loop layers

local function stopLoop( layer )
	advancedAudio.stop( layer.channel )
	layer.isPlaying = false
end

local function updateLayers( dt )
	local silentGain = config.silentGain

	for i = 1, #layers do
		local layer = layers[i]
		local layerConfig = layer.config

		layer.level = layer.level + ( layer.target - layer.level ) * ( 1 - exp( -dt / layerConfig.smoothing ) )

		local gain = layerConfig.volume * layer.level
		local targetGain = layerConfig.volume * layer.target

		channelGains[layer.channel] = gain

		if layer.isPlaying then
			-- Stops only on the way to silence, so a level resting near the threshold never starts and stops the loop repeatedly.
			if gain <= silentGain and targetGain <= silentGain then
				stopLoop( layer )
			else
				applyChannelVolume( layer.channel )
			end

		elseif gain > silentGain and not loopsPaused then
			advancedAudio.play( layer.filename, { channel = layer.channel, type = "loop", loops = -1, volume = 0 } )
			layer.isPlaying = true
			applyChannelVolume( layer.channel )
		end
	end
end

--------------------------------------------------------------------------------------
-- Music

local function stopMusicVoice( voice )
	advancedAudio.stop( voice.channel )
	voice.isPlaying = false
	voice.gain = 0
	voice.target = 0
end

local function applyMusicVolumes()
	for i = 1, #musicVoices do
		local voice = musicVoices[i]

		if voice.isPlaying then
			channelGains[voice.channel] = voice.gain * musicLevel
			applyChannelVolume( voice.channel )
		end
	end
end

-- Elapsed share 0..1 of the voice's current loop.
local function loopPosition( voice )
	local length = loopSeconds( voice.index )
	local elapsed = ( getTimer() - voice.startTime ) / 1000

	return ( elapsed % length ) / length
end

-- Starts the tempo at the playing tempo's position in its loop and cross-fades to it.
local function switchTempo( index )
	local incoming = musicVoices[1]

	if incoming == currentVoice then
		incoming = musicVoices[2]
	end

	if incoming.isPlaying then
		stopMusicVoice( incoming )
	end

	local crossFadeRate = 1 / tempoConfig.crossFade
	local position = 0

	if currentVoice and currentVoice.isPlaying then
		position = loopPosition( currentVoice )
		currentVoice.target = 0
		currentVoice.rate = crossFadeRate
		incoming.gain = 0
	else
		incoming.gain = 1
	end

	local offset = position * loopSeconds( index ) * 1000

	advancedAudio.play( tempoFiles[index], { channel = incoming.channel, type = "music", loops = -1, volume = 0 } )

	if offset > 0 then
		advancedAudio.seek( offset, { channel = incoming.channel } )
	end

	incoming.index = index
	incoming.startTime = getTimer() - offset
	incoming.target = 1
	incoming.rate = crossFadeRate
	incoming.isPlaying = true

	currentVoice = incoming
	sinceSwitch = 0

	applyMusicVolumes()
end

local function isMusicPlaying()
	return currentVoice ~= nil and currentVoice.isPlaying
end

local function updateMusic( dt )
	if not isMusicPlaying() then
		return
	end

	musicLevel = approach( musicLevel, musicLevelTarget, musicLevelRate * dt )

	if musicLevelTarget <= 0 and musicLevel <= 0 then
		sound.cutMusic()
		return
	end

	for i = 1, #musicVoices do
		local voice = musicVoices[i]

		if voice.isPlaying then
			voice.gain = approach( voice.gain, voice.target, voice.rate * dt )

			if voice ~= currentVoice and voice.gain <= 0 then
				stopMusicVoice( voice )
			end
		end
	end

	sinceSwitch = sinceSwitch + dt

	-- No switches while fading out, so the fade ends on the tempo it started from.
	if musicLevelTarget > 0 and sinceSwitch >= tempoConfig.hold and targetIndex ~= currentVoice.index then
		switchTempo( targetIndex )
	end

	applyMusicVolumes()
end

-- Returns the music to the slowest tempo, starting it with a fade-in when it is not playing.
local function returnToSlowest()
	sound.setKnots( 0 )

	musicLevelTarget = 1
	musicLevelRate = 1 / config.musicFadeIn

	if not isMusicPlaying() then
		musicLevel = 0
		switchTempo( 1 )

	elseif currentVoice.index ~= 1 then
		switchTempo( 1 )
	end
end

--------------------------------------------------------------------------------------
-- Public functions

function sound.play( name, level )
	local effect = effects[name]

	if not effect then
		error( "sound.play: unknown effect \"" .. tostring( name ) .. "\"", 2 )
	end

	if clock < ( nextPlayTimes[name] or 0 ) then
		return
	end

	nextPlayTimes[name] = clock + effect.interval

	local variant = min( #effect.files, bandIndex( effect.thresholds, level or 0 ) )

	playOneShot( effect.files[variant], "sfx", effect.volume )
end

function sound.babble( tier, characters )
	local voiceFiles = babbleFiles[tier]

	if not voiceFiles then
		error( "sound.babble: no voice for tier " .. tostring( tier ), 2 )
	end

	advancedAudio.stop( "babble" )
	playOneShot( voiceFiles[bandIndex( config.babble.lengthThresholds, characters )], "babble", config.babble.volume )
end

function sound.update( dt )
	clock = clock + dt
	updateLayers( dt )
	updateMusic( dt )
end

function sound.setVolumes( volumes )
	advancedAudio.setVolume( volumes.master )

	typeVolumes.music = volumes.music
	typeVolumes.loop = volumes.sfx
	typeVolumes.babble = volumes.sfx
	typeVolumes.sfx = volumes.sfx

	-- The type volume resets every channel of the type, so each channel's own gain goes back on top.
	for typeName, volume in pairs( typeVolumes ) do
		advancedAudio.setVolume( volume, typeName )
	end

	for channel = 1, #channelTypes do
		applyChannelVolume( channel )
	end
end

function sound.setLayer( name, level )
	local layer = layersByName[name]

	if not layer then
		error( "sound.setLayer: unknown layer \"" .. tostring( name ) .. "\"", 2 )
	end

	layer.target = level
end

-- Moves the target tempo up past every threshold the knots reach, and down only below a threshold times downFactor.
function sound.setKnots( knots )
	local thresholds = tempoConfig.thresholds

	while targetIndex < #tempos and knots >= thresholds[targetIndex] do
		targetIndex = targetIndex + 1
	end

	while targetIndex > 1 and knots < thresholds[targetIndex - 1] * tempoConfig.downFactor do
		targetIndex = targetIndex - 1
	end
end

function sound.pauseLoops()
	loopsPaused = true

	for i = 1, #layers do
		if layers[i].isPlaying then
			audio.pause( layers[i].channel )
		end
	end
end

function sound.resumeLoops()
	loopsPaused = false

	for i = 1, #layers do
		if layers[i].isPlaying then
			audio.resume( layers[i].channel )
		end
	end
end

-- Also zeroes every layer level, so the loops stay silent until setLayer raises one again.
function sound.stopLoops()
	for i = 1, #layers do
		local layer = layers[i]

		layer.level = 0
		layer.target = 0

		if layer.isPlaying then
			stopLoop( layer )
		end
	end
end

function sound.cutMusic()
	for i = 1, #musicVoices do
		if musicVoices[i].isPlaying then
			stopMusicVoice( musicVoices[i] )
		end
	end

	musicLevel = 0
	musicLevelTarget = 0
end

function sound.fadeOutMusic( seconds )
	if not isMusicPlaying() then
		return
	end

	if seconds <= 0 then
		sound.cutMusic()
		return
	end

	musicLevelTarget = 0
	musicLevelRate = musicLevel / seconds
end

function sound.restartMusic()
	returnToSlowest()
end

function sound.reset()
	advancedAudio.stop( "sfx" )
	advancedAudio.stop( "babble" )
	sound.stopLoops()

	loopsPaused = false
	nextPlayTimes = {}

	returnToSlowest()
end

--------------------------------------------------------------------------------------
-- Setup

assert( #tempoConfig.thresholds == #tempos - 1, "data/sound.lua needs one tempo threshold per tempo after the first in data/bgmTempos.lua" )

setupChannels()
loadEffects()

for i = 1, #tempos do
	tempoFiles[i] = advancedAudio.loadSound( bgmPath( i ) )
end

return sound
