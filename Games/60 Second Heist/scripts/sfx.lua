local sfx = {}

audio.reserveChannels( 1 )
sfx.bg = audio.loadSound( "music/fast-talkin-by-kevin-macleod-from-filmmusic-io.mp3", {channel = 1})


local maxAudio = 0.3
local currentAudio = maxAudio
audio.setVolume( maxAudio, {channel=1} )
local isMuted = false
local bgActive = false

local function bgListener( event )
    bgActive = false
end

function sfx.toggleAudio( event )
    if event.phase == "ended" then
        isMuted = not isMuted
        audio.setVolume( not isMuted and maxAudio or 0, {channel=1} )
    end
end

function sfx.startBG()
    if not bgActive then
        audio.play( sfx.bg, {channel=1, onComplete=bgListener} )
        bgActive = true
    else
        audio.resume( {channel=1} )
    end
end

function sfx.stopBG()
    if bgActive then
        audio.pause( {channel=1} )
        audio.rewind( {channel=1} )
    end
end

function sfx.play( effect )
    if not isMuted then
        -- audio.play()
    end
end

return sfx