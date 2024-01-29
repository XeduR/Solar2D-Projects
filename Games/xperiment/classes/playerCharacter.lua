local player = {}

local options =
{
    width = 144,
    height = 269,
    numFrames = 6
}

local imageSheet = graphics.newImageSheet( "assets/images/characters/player/character.png", options )

local sequenceData = {
    {
        name = "idle",
        frames = { 1 },
        time = 400,
        loopCount = 0,
        loopDirection = "forward"
    },
    {
        name = "walk",
        frames = { 2, 1, 3, 1  },
        time = 1200,
        loopCount = 0,
        loopDirection = "forward"
    },
    {
        name = "idleTrash",
        frames = { 4 },
        time = 400,
        loopCount = 0,
        loopDirection = "forward"
    },
    {
        name = "walkTrash",
        frames = { 5, 4, 6, 4 },
        time = 1200,
        loopCount = 0,
        loopDirection = "forward"
    }
}


---------------------------------------------------------------------------


function player.new( parent, x, y, scale, model )
	local character = display.newSprite( parent, imageSheet, sequenceData )
	character.x, character.y = x, y
	character.anchorY = 1
	character.baseScale = scale

	character.xScale, character.yScale = character.baseScale, character.baseScale
	character.suffix = model == "trash" and "Trash" or ""

	local directionPrev = 0
	function character.move( dir )
		if directionPrev ~= dir then
			if dir == 0 then
				character:setSequence( "idle" .. character.suffix )
			elseif dir > 0 then
				character.xScale = -character.baseScale
			elseif dir < 0 then
				character.xScale = character.baseScale
			end

			if directionPrev == 0 and not player.characterMoving then
				character:setSequence( "walk" .. character.suffix )
			end

		end

		if not player.characterMoving then
			character:play()
		end
		directionPrev = dir
	end
	character.move( 0 )

	function character.stop()
		directionPrev = 0
		if not player.characterMoving then
			character:setSequence( "idle" .. character.suffix )
			character:pause()
		end
	end


	return character
end


return player