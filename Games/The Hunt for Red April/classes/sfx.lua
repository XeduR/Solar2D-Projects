-- Sound effects module with distance-based volume and directional variant selection.

local sfx = {}

local gameConfig = require( "data.gameConfig" )
require( "libs.advancedAudio" )

--------------------------------------------------------------------------------------
-- Localised functions

local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local audioDir = "assets/audio/"
local audioConfig
local isEnabled = true
local engineHumActive = false

-- Player sounds (single variant).
local playerSounds = {
	"sonarPlayer.wav",
	"engineHum.mp3",
	"submarineExplode.wav",
}

-- Torpedo launch (3 variants: left, right, center).
local torpedoLaunchSuffixes = { "_left", "_right", "_center" }

-- Directional sounds (4 variants: left_near, left_far, right_near, right_far).
local directionalSounds = {
	"sonarDestroyer",
	"depthCharge",
	"torpedoExplode",
	"carrierExplode",
	"destroyerExplode",
}

local directionalSuffixes = { "_near_left", "_far_left", "_near_right", "_far_right" }

--------------------------------------------------------------------------------------
-- Private functions

local function distanceVolume( dist )
	if dist <= audioConfig.distanceMin then return 1 end
	if dist >= audioConfig.distanceMax then return 0 end
	return 1 - ( dist - audioConfig.distanceMin ) / ( audioConfig.distanceMax - audioConfig.distanceMin )
end

-- Cross product of player's forward vector and direction to source.
-- Positive = source is to the right of the player's facing direction.
local function getSide( playerX, playerY, playerHeading, sourceX, sourceY )
	local dx = sourceX - playerX
	local dy = sourceY - playerY
	local cross = cos( playerHeading ) * dy - sin( playerHeading ) * dx
	return cross >= 0 and "left" or "right"
end

--------------------------------------------------------------------------------------
-- Public functions

function sfx.init()
	audioConfig = gameConfig.audio
	audio.setVolume( audioConfig.masterVolume or 0.5 )
	audio.assignChannelTypes( 1, 1, "engine" )

	for i = 1, #playerSounds do
		audio.loadSound( audioDir .. playerSounds[i] )
	end

	for i = 1, #torpedoLaunchSuffixes do
		audio.loadSound( audioDir .. "torpedoLaunch" .. torpedoLaunchSuffixes[i] .. ".wav" )
	end

	for i = 1, #directionalSounds do
		for j = 1, #directionalSuffixes do
			print( audioDir .. directionalSounds[i] .. directionalSuffixes[j] .. ".wav" )
			audio.loadSound( audioDir .. directionalSounds[i] .. directionalSuffixes[j] .. ".wav" )
		end
	end
end

function sfx.setEnabled( value )
	isEnabled = value
	if not value then
		for i = 1, 32 do
			audio.stop( i )
		end
	elseif engineHumActive then
		audio.play( audioDir .. "engineHum.mp3", { type = "engine", loops = -1, volume = 0 } )
	end
end

function sfx.isEnabled()
	return isEnabled
end

-- Play a sound originating from the player (full volume, single variant).
function sfx.playPlayer( name )
	if not isEnabled then return end
	audio.play( audioDir .. name .. ".wav" )
end

-- Play a directional sound from a world position relative to the player.
function sfx.playDirectional( name, sourceX, sourceY, playerX, playerY, playerHeading )
	if not isEnabled then return end

	local dx = sourceX - playerX
	local dy = sourceY - playerY
	local dist = sqrt( dx * dx + dy * dy )
	local vol = distanceVolume( dist )
	if vol <= 0 then return end

	local side = getSide( playerX, playerY, playerHeading, sourceX, sourceY )
	local proximity = dist <= audioConfig.distanceClose and "near" or "far"
	local filename = audioDir .. name .. "_" .. proximity .. "_" .. side .. ".wav"
	audio.play( filename, { volume = vol } )
end

-- Play torpedo launch with left/right/centre variant based on submarine heading.
function sfx.playTorpedoLaunch( heading )
	if not isEnabled then return end
	local horizontal = cos( heading )
	local variant
	if horizontal > 0.707 then
		variant = "right"
	elseif horizontal < -0.707 then
		variant = "left"
	else
		variant = "center"
	end
	audio.play( audioDir .. "torpedoLaunch_" .. variant .. ".wav" )
end

function sfx.startEngineHum()
	engineHumActive = true
	if not isEnabled then return end
	audio.play( audioDir .. "engineHum.mp3", { type = "engine", loops = -1 } )
end

function sfx.stopEngineHum()
	engineHumActive = false
	audio.stop( 1 )
end

return sfx
