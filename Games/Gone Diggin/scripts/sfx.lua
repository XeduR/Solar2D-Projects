local sfx = {}

local audioFiles = {
	"gold.wav",
	"ground.wav",
	"timerStart.wav",
	"gameover.wav",
	"bg.wav"
}

for i = 1, #audioFiles do
	sfx[audioFiles[i]:sub(1,-5)] = audio.loadSound( "sfx/" .. audioFiles[i] )
end

-- Cap master volume, reserve channel 1 for BG and start looping it.
sfx.maxVolume = 0.35
audio.setVolume( sfx.maxVolume )
audio.reserveChannels( 1 )
audio.setVolume( 0.5, { channel=1 } )
audio.play( sfx["bg"], { channel=1, loops=-1 } )

return sfx