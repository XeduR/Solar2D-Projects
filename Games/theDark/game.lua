local composer = require( "composer" )
local screen = require( "spyric.screen" )
local snowParams = require( "data.snowParams" )
local fireParams = require( "data.fireParams" )
local physics = require( "physics" )
physics.start()
-- physics.setDrawMode( "hybrid" )

local sheetInfo = require( "data.walkAnimation" )
local imageSheet = graphics.newImageSheet( "images/walkAnimation.png", sheetInfo:getSheet() )
local sequences = {
    {
        name = "left",
        frames = { 1,2,3,4 },
        time = 1200,
        loopCount = 0
    },
    {
        name = "right",
        frames = { 5,6,7,8 },
        time = 1200,
        loopCount = 0
    },
}

local sfx = {}
sfx[#sfx+1] = audio.loadSound( "audio/press1.wav" )
sfx[#sfx+1] = audio.loadSound( "audio/press2.wav" )
sfx[#sfx+1] = audio.loadSound( "audio/press3.wav" )
audio.setVolume( 0.5 )
audio.reserveChannels( 1 )

local sound = true
local currentSFX = 1
local function playSFX()
	if sound then
		audio.play( sfx[currentSFX] )
	end
	currentSFX = currentSFX+1
	if currentSFX > #sfx then
		currentSFX = 1
	end
end

local groupBackground = display.newGroup()
local groupDialogue = display.newGroup()
local groupPlayer = display.newGroup()
local groupMap = display.newGroup()
local groupSnow = display.newGroup()
local groupLight = display.newGroup()
local groupUI = display.newGroup()
local snapshot = display.newSnapshot( groupLight, screen.width, screen.height )
snapshot:translate( screen.centreX, screen.centreY )

-- Collision filters (created using spyricCollision.xlsx found in "development files")
local playerFilter = { categoryBits=1, maskBits=4 }
local playerSensorFilter = { categoryBits=2, maskBits=8 }
local terrainFilter = { categoryBits=4, maskBits=9 }
local treeFilter = { categoryBits=8, maskBits=6 }

local text, heading, underline = {}
local logo, logoEmitter, terrain, background, player, darkness, lantern, startTime
local forestLeft, forestRight, timerSnowfall, timerCampfire, campfire, heart
local tree, snowEmitter, heartMeter = {}, {}, {}
local fontHeading = "fonts/OpenSans-SemiBold.ttf"
local font = "fonts/OpenSans-Regular.ttf"


-- Localised and forward declared functions
local gameover, showLogo, say, startGame, updateCampfire
local _transitionTo = transition.to
local _dRemove = display.remove
local _random = math.random
local _floor = math.floor
local _abs = math.abs
local _min = math.min
local _max = math.max

-- Player variables:
local stats = {}
local maxWarmth = 1200
local fuelLanternMax = 400
local fuelCampfireMax = 500
-- Past these levels, the player will take damage.
stats.fuelLanternThreshold = 100
stats.fuelCampfireThreshold = 100

-- General variables concerning display objects:
local skyGradientHeight = 400
local terrainStrokeSize = 8
local playerWidth = 20
local lanternMoveTime = 100
local lanternOffsetX = -32
local lanternOffsetY = -36
local playerSensorRadius = 64
local lanternRadius = 350
local campfireRadius = 520
local darknessAlpha = 0.98
local startEndTime = 2500
local windSpeedMin = 200
local windSpeedMax = 500
local windSpeedTimeToMax = 60000

-- Terrain generation variables:
local segmentWidth = 400
local segmentHeight = 100
local segmentCount = 14
local minElevation = -15
local maxElevation = 15
local lockElevation = 40
local forestPadding = 60 -- the distance before the forest the player stops.
-- terrainLevel is only approximate as the ground has slopes.
local terrainLevel = screen.maxY - 200

-- Automatically assigned variables:
local moveMax = segmentWidth*segmentCount*0.5 - segmentWidth*0.5 - forestPadding
local moveMin = -moveMax
local skyOffset = skyGradientHeight+screen.maxY
local canStart = false
local windSpeed = 0
local isNextToCamp = false
local canRefuel = false
local nearbyTree
local windDirection = ""
local gameHasEnded = false
local isLanternOn = true
local isCampfireOn = true
local startGameByKey = false

-- Nifty little trick table for shifting the lantern when moving.
local lanternX = {x=0,direction=""}

--------------------------------------------------------------
-- Development variables (comment these out for builds):
--------------------------------------------------------------
-- local SENSOR_ALPHA = 0.1
-- local SKIP_TO = "logo"  -- Accepted values: "logo", "game"
-- local FASTER_MOVEMENT = 20
-- local DISABLE_HAZARDS = true -- this'll lock heart to "frozen"
--------------------------------------------------------------

-- Logo transition functions: start
local jumpStart

local function jumpEasing( a, b, c, d )
	return c+d*(((1-a/b)^2)-((1-a/b)^40))*1.2
end

local function logoReset()
	logo.xScale, logo.yScale = 1, 1
	text["start"].xScale, text["start"].yScale = 1, 1
    if canStart then logoGrow() end
end

function logoGrow()
    _transitionTo( logo, { tag="pulse", time=1200, xScale=1.05, yScale=1.05, transition=jumpEasing, onComplete=logoReset })
    _transitionTo( text["start"], { tag="pulse", time=1200, xScale=1.05, yScale=1.05, transition=jumpEasing })
end
-- Logo transition functions: end


local direction, isLeftPressed, isRightPressed, forestTriggered
local function moveMap()
    local toX = FASTER_MOVEMENT and FASTER_MOVEMENT or 1.6

    if direction == "right" then
        toX = -toX
    end
    if (toX < 0 and groupMap.x >= moveMin) or (toX > 0 and groupMap.x <= moveMax) then
        -- This player/map movement is a bit of a "hack" method, but hey, it's a short game jam, so why not?

        -- Seems that this hack method will leave the player trailing after some time, so player isn't centered after a while,
        -- but as this is a LD game with limited time, I'll leave it here as it "looks cool" and won't cause much of an issue.
        groupMap.x = groupMap.x + toX
        groupPlayer.x = groupPlayer.x + toX
		groupDialogue.x = groupDialogue.x + toX
        groupSnow.x = groupSnow.x + toX*0.5
        player.x = player.x - toX
        forestTriggered = false
    else
        if not forestTriggered then
            forestTriggered = true
			say( "I'm not going so deep into to the forest at night!" )
        end
    end
end


local function movelantern( direction )
    transition.cancel( "lantern" )

    -- Gradually move the lantern towards the movement direction at a fixed pace.
    local toX, timeLeft = 0
    if direction == "left" then
        toX = lanternOffsetX
        timeLeft = lanternMoveTime * ((lanternOffsetX-lanternX.x)/lanternOffsetX)
    elseif direction == "right" then
        toX = -lanternOffsetX
        timeLeft = lanternMoveTime * ((-lanternOffsetX-lanternX.x)/lanternOffsetX)
    -- else
    --     timeLeft = lanternMoveTime * (lanternX.x/lanternOffsetX)
    end

    _transitionTo( lanternX, { tag="lantern", time=_abs(timeLeft), x=toX } )
end

local movementStopped = false
local function stopMovement()
	if not movementStopped then
		player:pause()
		movementStopped = true
	    Runtime:removeEventListener( "enterFrame", moveMap )
	    direction = nil
	    -- movelantern()
	end
end


local function onKeyEvent( event )
    local key, phase = event.keyName, event.phase
    -- Move the player left or right as long as the button is pressed and move the lantern.
	if startGameByKey then
		startGameByKey = false
		startGame( {phase="ended"} )
	else
	    if phase == "down" then

	        if key == "a" or key == "left" then
	            isLeftPressed = true
	            if not direction then
					movementStopped = false
	                direction = "left"
					player:setSequence( direction )
					player:play()
	                movelantern( direction )
	                Runtime:addEventListener( "enterFrame", moveMap )
	            end
	        elseif key == "d" or key == "right" then
	            isRightPressed = true
	            if not direction then
					movementStopped = false
	                direction = "right"
					player:setSequence( direction )
					player:play()
	                movelantern( direction )
	                Runtime:addEventListener( "enterFrame", moveMap )
	            end
			elseif key == "space" then
				if canRefuel then
					playSFX()
					stats.fuelLantern = fuelLanternMax
			        lantern.alpha = 1
				end
				if nearbyTree then
					playSFX()
					if stats.hasFirewood then
						if _random() < 0.5 then
							say( "I have more wood than I can carry." )
						else
							say( "I should first return what I'm carrying to the camp." )
						end
					else
						local n = _random()
						if n < 0.33 then
							say( "(Thud)" )
						elseif n < 0.66 then
							say( "(Chop)" )
						else
							say( "(Thwack)" )
						end
						local scale = 1+_random(-5,5)*0.01
						nearbyTree.xScale, nearbyTree.yScale = scale, scale
						nearbyTree.hits = nearbyTree.hits-1
						if nearbyTree.hits <= 0 then
							if _random() < 0.5 then
								say( "Take that, tree!" )
							else
								say( "I have enough firewood now." )
							end
							stats.hasFirewood = true
							local id = nearbyTree.id
							_dRemove( tree[id] )
							tree[id] = nil
							nearbyTree = nil
						end
					end
				end
			elseif key == "s" then
				sound = not sound
				if not sound then
					text["sfx"].text = "Press S to enable sounds."
				else
					text["sfx"].text = "Press S to mute sounds."
				end
	        -- Debugging/development shortcut to force gameover.
			elseif key == "q" then
	            gameover()
	        end
	    elseif phase == "up" then
	        if (key == "a" or key == "left") and direction == "left" then
	            isLeftPressed = false
	            if isRightPressed then
					movementStopped = false
	                direction = "right"
					player:setSequence( direction )
					player:play()
	                movelantern( direction )
	            else
	                stopMovement()
	            end
	        elseif (key == "d" or key == "right") and direction == "right" then
	            isRightPressed = false
	            if isLeftPressed then
					movementStopped = false
	                direction = "left"
					player:setSequence( direction )
					player:play()
	                movelantern( direction )
	            else
	                stopMovement()
	            end
	        end
	    end
	end
    return false
end

function say( s )
	playSFX()
	text["player"].text = s or ""
	text["player"].alpha = 1
	_transitionTo( text["player"], {time=1500, alpha=0} )
end


local lanternOutOfFuel = false
local campfireOutOfFuel = false
local function updateLights()
	local lanternFuelLeft, campfireFuelLeft
	if stats.fuelLantern <= stats.fuelLanternThreshold then
		if not lanternOutOfFuel then
			lantern.alpha = 0
		end
		isLanternOn = false
		lanternOutOfFuel = true
	else
		lanternFuelLeft = stats.fuelLantern/fuelLanternMax
	end
	if stats.fuelCampfire <= stats.fuelCampfireThreshold then
		if not campfireOutOfFuel then
			campfireLight.alpha = 0
		end
		isNextToCamp = false
		isCampfireOn = false
		campfireOutOfFuel = true
		updateCampfire()
	else
		campfireFuelLeft = stats.fuelCampfire/fuelCampfireMax
	end

	if not lanternOutOfFuel then
	    lantern.xScale, lantern.yScale = lanternFuelLeft, lanternFuelLeft
	    lantern.y = player.y - screen.centreY + lanternOffsetY
	    lantern.x = lanternX.x
	end

	if not campfireOutOfFuel then
	    campfireLight.xScale, campfireLight.yScale = campfireFuelLeft, campfireFuelLeft
	    campfireLight.y = campfireLight.startingY - (player.startingY - player.y)
	    campfireLight.x = campfireLight.startingX + groupMap.x
	end

    snapshot:invalidate()
end


local function gameLoop()
    if isNextToCamp then
		if stats.warmth <= maxWarmth then
	        stats.warmth = stats.warmth + 2
		end
    else
        if nearbyTree then
			-- print( player.x, nearbyTree.x )
            stats.warmth = stats.warmth - windSpeed*0.0003
        else
            stats.warmth = stats.warmth - windSpeed*0.001
        end
    end
	-- If the player is in complete darkness, then they'll freeze faster
	if not isCampfireOn and not isLanternOn then
		stats.warmth = stats.warmth - 1
	end

	stats.fuelLantern = stats.fuelLantern - 0.15
	stats.fuelCampfire = stats.fuelCampfire - 0.08
	-- print( stats.fuelLantern, stats.fuelCampfire )
	text["player"].x, text["player"].y = player.x, player.y - 60

	-- This colour & alpha looping is terribly unoptimised.
	local warmthPercentage = stats.warmth/maxWarmth
	local heartR = 0.9*warmthPercentage*0.5
	local heartG = 0.4-warmthPercentage*0.4
	local heartB = 1-warmthPercentage
	heart:setFillColor( heartR, heartG, heartB )
	for i = 1, 90 do
		heartMeter[i]:setFillColor( heartR, heartG, heartB )
	end
	local progress = _min(_floor(90*warmthPercentage), 90 )
	for i = 1, progress do
		heartMeter[i].alpha = 1
	end
	if progress >= 0 then
		for i = progress+1, 90 do
			heartMeter[i].alpha = 0
		end
	end

    if stats.warmth <= 0 then
		if _random() < 0.5 then
			say( "...anyone?" )
		else
			say( "Hello...?" )
		end

		if not isLantern and not isCampfireOn then
        	gameover( "Keep your lantern and campfire going or you'll freeze." )
		elseif not isLantern then
        	gameover( "You freeze faster without your lantern." )
		else
        	gameover( "It's so cold... too cold." )
		end
    end
end


function updateCampfire()
	local multiplier = (stats.fuelCampfire-stats.fuelCampfireThreshold)/fuelCampfireMax
	local n = campfire.whichEmitter

	if timerCampfire then
		timer.cancel( timerCampfire )
		timerCampfire = nil
	end

	if campfire.emitter[n] then
		campfire.emitter[n]:stop()
		timer.performWithDelay( 1000, function()
			_dRemove( campfire.emitter[n] )
			campfire.emitter[n] = nil
		end )
	end
	if n == 1 then campfire.whichEmitter = 2 else campfire.whichEmitter = 1 end

	campfire.emitter[campfire.whichEmitter] = display.newEmitter( fireParams.get( _max(5,150*multiplier), _max(2,16*multiplier), _max(0.5,1.5*multiplier) ) )
	campfire.emitter[campfire.whichEmitter].x = campfire.x
	campfire.emitter[campfire.whichEmitter].y = campfire.y
	groupMap:insert( campfire.emitter[campfire.whichEmitter] )

	timerCampfire = timer.performWithDelay( 2000, updateCampfire )
end


local function addSnowfall( gameStarted )

	local function start()
		if not gameHasEnded then
			local angle
			if type( gameStarted ) == "boolean" then
				angle, windSpeed = _random( 85, 95 ), 140
			else
				if _random() > 0.5 then
					angle = _random( 100, 150 )
					windDirection = "right"
				else
					angle = _random( 30, 80 )
					windDirection = "left"
				end
				min = (windSpeedMax-windSpeedMin)*(system.getTimer()-startTime)/windSpeedTimeToMax
				if min > windSpeedMax then min = windSpeedMax end
				windSpeed = _random( min, windSpeedMax )

				if windSpeed < windSpeedMax*0.25 then
					say( "The wind is picking up, it'll get colder." )
				elseif windSpeed < windSpeedMax*0.5 then
					say( "The wind is starting to get a lot colder." )
				elseif windSpeed < windSpeedMax*0.75 then
					say( "The wind is harsh, but I can't give up!" )
				else
					say( "The wind is severe, I won't make it!" )
				end
			end
			-- Performance would be improved if these emitters were
			-- only activated as they are about to enter the screen.
			local emitterParams = snowParams.get( {
				xVariance = segmentWidth,
				absolutePosition = true,
				angle = angle,
				windSpeed = windSpeed
			} )

			local xStart = 0--segmentWidth*0.5
			for i = 1, segmentCount do
				snowEmitter[i] = display.newEmitter( emitterParams )
				snowEmitter[i].x = xStart+segmentWidth*(i-1)
				snowEmitter[i].y = display.contentCenterY - 200
				groupSnow:insert( snowEmitter[i] )
			end

			timerSnowfall = timer.performWithDelay( _random( 8000, 16000 ), addSnowfall )
		end
	end

	local function clear()
        for i = 1, segmentCount do
			if snowEmitter[i] then
				_dRemove( snowEmitter[i] )
				snowEmitter[i] = nil
			end
        end
		start()
	end

	if type( gameStarted ) == "boolean" then
		start()
	else
        for i = 1, segmentCount do
			if snowEmitter[i] then
            	snowEmitter[i]:stop()
			end
        end
		timer.performWithDelay( 2000, clear )
    end
end


function startGame( event )
    if event.phase == "ended" then
        if canStart then
			startGameByKey = false
            canStart = false
			gameHasEnded = false
			campfireLight.startingX, campfireLight.startingY = campfire.x-screen.centreX, campfire.y-screen.centreY
			player.startingY = player.y
            snapshot:invalidate( "canvas" )
            Runtime:addEventListener( "enterFrame", updateLights )

            if event.skip then
                logo.y = logo.y-skyOffset
                text["title"].y = text["title"].y-skyOffset
                logoEmitter.y = logoEmitter.y-skyOffset
                skyGradient.y = skyGradient.y-skyOffset
                groupMap.y = groupMap.y-skyOffset
                groupPlayer.y = groupPlayer.y-skyOffset
                groupLight.y = groupLight.y-skyOffset

                Runtime:addEventListener( "enterFrame", gameLoop )
                player.sensor:addEventListener( "collision" )
				_transitionTo( heart, { time=200, alpha=1 })
				_transitionTo( heart.overlay, { time=200, alpha=1 })
                startTime = system.getTimer()
                addSnowfall( true )
                logoEmitter:stop()
                -- Runtime:addEventListener( "key", onKeyEvent )
            else
                -- background:addEventListener( "touch", startGame )
                transition.cancel( "pulse" )
                _transitionTo( logo, { time=startEndTime, y=logo.y-skyOffset, alpha=0, onComplete=function()
                	Runtime:addEventListener( "enterFrame", gameLoop )
                    player.sensor:addEventListener( "collision" )
					_transitionTo( heart, { time=200, alpha=1 })
					_transitionTo( heart.overlay, { time=200, alpha=1 })
                    startTime = system.getTimer()
                    addSnowfall( true )
                    logoEmitter:stop()
                    -- Runtime:addEventListener( "key", onKeyEvent )
                end })
                _transitionTo( text["title"], { time=startEndTime, y=text["title"].y-skyOffset, alpha=0 })
                _transitionTo( text["start"], { time=startEndTime*0.5, alpha=0 })
                _transitionTo( logoEmitter, { time=startEndTime, y=logoEmitter.y-skyOffset, alpha=0 })
                _transitionTo( skyGradient, { time=startEndTime, y=skyGradient.y-skyOffset })
                _transitionTo( groupMap, { time=startEndTime, y=groupMap.y-skyOffset })
                _transitionTo( groupPlayer, { time=startEndTime, y=groupPlayer.y-skyOffset })
                _transitionTo( groupLight, { time=startEndTime, y=groupLight.y-skyOffset })
            end
        end
    end
    return true
end


function gameover( reason )
	stopMovement()
	if timerSnowfall then
		timer.cancel( timerSnowfall )
		timerSnowfall = nil
	end
	if timerCampfire then
		timer.cancel( timerCampfire )
		timerCampfire = nil
	end

	-- Setting all possible rogue texts transparent
	_transitionTo( text["refuel"], { time=250, alpha=0 })

	gameHasEnded = true
    Runtime:removeEventListener( "enterFrame", gameLoop )
    player.sensor:removeEventListener( "collision" )
    Runtime:removeEventListener( "key", onKeyEvent )

    for i = 1, #snowEmitter do
        snowEmitter[i]:stop()
    end

    local fadeTime = 2500
    text["gameover"].text = reason or "The Darkness is terrifying."

	_transitionTo( heart, { time=fadeTime*0.5, alpha=0 })
	_transitionTo( heart.overlay, { time=fadeTime*0.5, alpha=0 })
	for i = 1, 90 do
		heartMeter[i].alpha = 0
	end

    _transitionTo( text["gameover"], { time=fadeTime, alpha=1, onComplete=function()
        _transitionTo( text["gameover"], { time=startEndTime-500, alpha=0 })
    end })
    _transitionTo( snapshot, { time=fadeTime, alpha=1 })
    _transitionTo( campfireLight, { time=fadeTime, alpha=0 })
    _transitionTo( lantern, { time=fadeTime, alpha=0, onComplete=function()
        Runtime:removeEventListener( "enterFrame", updateLights )

        groupMap.x = 0
        groupPlayer.x = 0
		groupDialogue.x = 0
        groupSnow.x = 0
        player.x = screen.centreX

        _transitionTo( text["title"], { time=startEndTime, y=text["title"].y+skyOffset, alpha=1 })
        _transitionTo( logoEmitter, { time=startEndTime, y=logoEmitter.y+skyOffset, alpha=1 })
        _transitionTo( skyGradient, { time=startEndTime, y=skyGradient.y+skyOffset })
        _transitionTo( groupMap, { time=startEndTime, y=groupMap.y+skyOffset })
        _transitionTo( groupPlayer, { time=startEndTime, y=groupPlayer.y+skyOffset })
        _transitionTo( groupLight, { time=startEndTime, y=groupLight.y+skyOffset })
        _transitionTo( logo, { time=startEndTime, y=logo.y+skyOffset, alpha=1, onComplete=function()
            logoEmitter:start()
            showLogo()
        end })
    end })
end


local function newGame( skipEvent )
    snapshot.alpha = darknessAlpha
    if type( skipEvent ) == "table" and skipEvent.skip then
		canStart = true
		startGameByKey = true
        startGame( skipEvent )
		Runtime:addEventListener( "key", onKeyEvent )
    else
        _transitionTo( text["start"], { time=500, alpha=1, onComplete=function()
			canStart = true
			startGameByKey = true
            background:addEventListener( "touch", startGame )
			Runtime:addEventListener( "key", onKeyEvent )
        end })
        logoGrow()
    end
end


local function onCollision( self, event )
    local phase = event.phase
    local other = event.other.name

	if other == "campfire" then
		if phase == "began" then
			if stats.fuelCampfire >= stats.fuelCampfireThreshold then
				isNextToCamp = true
				isCampfireOn = true
			end
			local n =  _random()
			if stats.hasFirewood then
				if n < 0.33 then
					say( "Hopefully these will keep the fire going." )
				elseif n < 0.66 then
					say( "I need to go gather more firewood." )
				else
					say( "I wonder if I will make it through the night." )
				end
				stats.hasFirewood = false
				stats.fuelCampfire = fuelCampfireMax
				campfireLight.alpha = 1
				isNextToCamp = true
				isCampfireOn = true
				updateCampfire()
			else
				if n < 0.33 then
					say( "... so warm." )
				elseif n < 0.66 then
					say( "Maybe I'll warm up a bit." )
				else
					say( "Ah, the campfire!" )
				end
			end
		else
			isCampfireOn = false
			isNextToCamp = false
		end
	elseif other == "refuelPoint" then
		if phase == "began" then
			isLanternOn = true
			lanternOutOfFuel = false
			canRefuel = true
			text["refuel"].alpha = 1
		else
			_transitionTo( text["refuel"], { time=250, alpha=0 })
			canRefuel = false
		end

	elseif other == "tree" then
		if phase == "began" then
			if not nearbyTree then
				if _random() < 0.5 then
					say( "Trees provide shelter, but I need firewood." )
				else
					say( "This tree would make excellent firewood." )
				end
				nearbyTree = event.other
			end
		else
			nearbyTree = nil
		end
	end
end


local function generateTerrain()
    -- Create the shape for the terrain polygon
    local xy = {
        0,
        _random(minElevation, maxElevation)+terrainLevel,
        segmentWidth,
        _random(minElevation, maxElevation)+terrainLevel
    }
    local yMin, yMax = _min( xy[2], xy[4] ), screen.maxY+100
    for i = 2, segmentCount do
        xy[#xy+1] = segmentWidth*i
        local y = xy[#xy-1] + _random(minElevation, maxElevation)
        if y >= terrainLevel+lockElevation or y <= terrainLevel-lockElevation then
            y = terrainLevel
        end
        xy[#xy+1] = y
        if xy[#xy] < yMin then
            yMin = xy[#xy]
        end
    end
    xy[#xy+1] = xy[#xy-1]
    xy[#xy+1] = screen.maxY+100
    xy[#xy+1] = 0
    xy[#xy+1] = screen.maxY+100

    terrain = display.newPolygon( groupMap, screen.centreX, screen.maxY+100, xy )
    terrain.anchorY = 1
    physics.addBody( terrain, "static", { friction=10, density=10, bounce=0, filter=terrainFilter } )
    terrain.stroke = {
        type = "image",
        filename = "images/snow.png"
    }
    terrain.strokeWidth = terrainStrokeSize

    display.setDefault( "textureWrapX", "repeat" )
    -- display.setDefault( "textureWrapY", "repeat" )
    terrain.fill = {
        type = "image",
        filename = "images/ground.png"
    }
    terrain.fill.y = ( ( terrain.height - 128 ) / 2 ) / 128
    terrain.fill.scaleX = 128 / terrain.width
    terrain.fill.scaleY = 128 / terrain.height
    display.setDefault( "textureWrapX", "clanternToEdge" )
    -- display.setDefault( "textureWrapY", "clanternToEdge" )

    terrain.playerStartY = yMin - playerSensorRadius*0.5
    forestLeft.y = (xy[2]+xy[4])*0.5+10
    forestRight.y = (xy[#xy-4]+xy[#xy-6])*0.5+10
    terrain:toBack()
    forestLeft:toBack()
    forestRight:toBack()

	local xStart = terrain.x-terrain.width*0.5
	local skipSegmentA, skipSegmentB
	-- Prevent trees from spawning on the camp area.
	if segmentCount % 2 == 0 then
		local n = segmentCount*0.5
		skipSegmentA, skipSegmentB = n, n+1
	else
		local n = _floor(segmentCount*0.5)+1
		skipSegmentA, skipSegmentB = n, n
	end

	local n = 1
	for i = 1, segmentCount*2 do
		if n ~= skipSegmentA and n ~= skipSegmentB then
			if _random() > 0.3 then -- keep a change that there's no tree on some segment.
				tree[i] = display.newImageRect( groupMap, "images/tree.png", 80, 160 )
				tree[i].x, tree[i].y = xStart + _random( xy[n*2-1], xy[n*2+1] ), terrain.playerStartY
				local scale = 1+_random(-20,20)*0.01
				tree[i].xScale, tree[i].yScale = scale, scale
				physics.addBody( tree[i], "dynamic", { friction=10, density=10, radius=80*scale*0.5, bounce=0, filter=treeFilter } )
				tree[i].name = "tree"
				tree[i].id = i
				tree[i].hits = _random( 6, 12 )
				tree[i].isFixedRotation = true
				tree[i]:toBack()
			end
		end
		n = n+1
		if n >= segmentCount then
			n = 1
		end
	end
end

function showLogo( firstStart, skipEvent )
    if not firstStart then
        -- Remove all terrain and objects apart
		-- from the forests, which are reused.
        _dRemove( terrain )
        terrain = nil
        for i = 1, #tree do
            _dRemove( tree[i] )
            tree[i] = nil
        end
        for i = 1, #snowEmitter do
            _dRemove( snowEmitter[i] )
            snowEmitter[i] = nil
        end
        lantern.alpha = 1
		campfireLight.alpha = 1
    end
    generateTerrain()

    -- Assign new values for all game variables:
    player.y = terrain.playerStartY

    if _random() > 0.5 then
        campfire.x = _random( screen.centreX-playerSensorRadius-60, screen.centreX-playerSensorRadius-20 )
        campfire.refuelPoint.x = campfire.x - campfire.width*0.5 - _random( 40, 70 )
    else
        campfire.x = _random( screen.centreX+playerSensorRadius+20, screen.centreX+playerSensorRadius+60 )
        campfire.refuelPoint.x = campfire.x + campfire.width*0.5 + _random( 40, 70 )
    end
    campfire.y = terrain.playerStartY
	campfire.refuelPoint.y = campfire.y
	text["refuel"].x, text["refuel"].y = campfire.refuelPoint.x, campfire.refuelPoint.y - 80
    campfire.refuelPoint:toBack()
    campfire:toBack()

    stats.warmth = maxWarmth
    stats.fuelLantern = fuelLanternMax
    stats.fuelCampfire = fuelCampfireMax
	stats.hasFirewood = false
	lanternOutOfFuel = false
	campfireOutOfFuel = false
	isLanternOn = true
	isCampfireOn = true

	timer.performWithDelay( 500, function()
		updateCampfire()
	end )

    if DISABLE_HAZARDS then
        stats.warmth = math.huge
        stats.fuelLantern = math.huge
    end

    if skipEvent then
		text["move"].alpha = 1
		text["sfx"].alpha = 1
		text["space"].alpha = 1
		text["restart"].alpha = 1
        newGame( skipEvent )
        logo.y = logo.y-40
        text["title"].y = text["title"].y+10
    else
        if firstStart then
            _transitionTo( text["move"], { time=2000, alpha=1 })
            _transitionTo( text["sfx"], { time=2000, alpha=1 })
            _transitionTo( text["space"], { time=2000, alpha=1 })
            _transitionTo( text["restart"], { time=2000, alpha=1 })
            _transitionTo( logo, { time=2000, alpha=1, y=logo.y-40 })
            _transitionTo( text["title"], { delay=1500, time=500, y=text["title"].y+10, alpha=1, onComplete=newGame })
        else
            newGame()
        end
    end
end

local function clearDialogue()
    _transitionTo( groupDialogue, { delay=1500, time=1000, y=groupDialogue.y+10, alpha=0, onComplete=function()
		text["player"].alpha = 1
		for i = 1, 3 do
			text[i].alpha = 0
		end
		underline.alpha = 0
		groupDialogue.y = groupDialogue.y-10
		groupDialogue.alpha = 1
        showLogo( true )
    end })
end


local scene = composer.newScene()

-- Create all persisting display objects when the scene is loaded (and just toggle their alpha afterwards).
function scene:create( event )
    local sceneGroup = self.view
    groupMap.y = groupMap.y+skyOffset
    groupPlayer.y = groupPlayer.y+skyOffset
    groupLight.y = groupLight.y+skyOffset

	heart = display.newImageRect( groupUI, "images/heart.png", 64, 64 )
	heart.x, heart.y = screen.centreX, screen.maxY - 60
    heart:setFillColor( 0.95, 0.1, 0.2 )
	heart.alpha = 0

	heart.overlay = display.newImageRect( groupUI, "images/heartOverlay.png", 64, 64 )
	heart.overlay.blendMode = "add"
	heart.overlay.alpha = 0.5
	heart.overlay.x, heart.overlay.y = heart.x, heart.y
	heart.overlay.alpha = 0

	for i = 1, 90 do
		heartMeter[i] = display.newImageRect( groupUI, "images/heartMeter.png", 40, 8 )
		heartMeter[i].x, heartMeter[i].y = heart.x, heart.y
		heartMeter[i].rotation = 88-i*4
		heartMeter[i].anchorX = 0
		heartMeter[i].alpha = 0
	    heartMeter[i]:setFillColor( 0.95, 0.1, 0.2 )
	end
	heart:toFront()
	heart.overlay:toFront()

    campfire = display.newImageRect( groupMap, "images/campfire.png", 64, 32 )
	campfire.x, campfire.y = screen.centreX, screen.maxY - 100
    physics.addBody( campfire, "dynamic", { friction=10, density=10, bounce=0, radius=18, filter=treeFilter } )
    campfire.isFixedRotation = true
    campfire.name = "campfire"

	campfire.whichEmitter = 1
	campfire.emitter = {}

    campfire.refuelPoint = display.newImageRect( groupMap, "images/fuel.png", 100, 112 )
	campfire.refuelPoint.x, campfire.refuelPoint.y = screen.centreX, screen.maxY - 100
    campfire.refuelPoint.anchorY = 1
    physics.addBody( campfire.refuelPoint, "dynamic", { friction=10, density=10, bounce=0, filter=treeFilter } )
    campfire.refuelPoint.isFixedRotation = true
    campfire.refuelPoint.name = "refuelPoint"

    text["refuel"] = display.newText( groupDialogue, "Press space to refuel your lantern.", campfire.refuelPoint.x, campfire.refuelPoint.y, font, 20 )
    text["refuel"].alpha = 0

    logoEmitter = display.newEmitter( snowParams.get() )
    logoEmitter.x = display.contentCenterX
    logoEmitter.y = display.contentCenterY - 200
    groupSnow:insert( logoEmitter )

    skyGradient = display.newRect( groupUI, screen.centreX, screen.maxY, screen.width, skyGradientHeight )
    skyGradient.fill = {
        type = "gradient",
        color1 = { 0, 0 },
        color2 = { 0, 1 },
        direction = "down"
    }
    skyGradient.anchorY = 0

    -- player = display.newRect( groupPlayer, screen.centreX, screen.maxY - 100, playerWidth, playerHeight )
	player = display.newSprite( groupPlayer, imageSheet, sequences )
	player.x, player.y = screen.centreX, screen.maxY - 100
    player:setFillColor( 0.8, 0, 0 )
    physics.addBody( player, "dynamic", { friction=10, density=10, bounce=0, radius=50, filter=playerFilter } )
    player.isFixedRotation = true

    text["player"] = display.newText( groupDialogue, "", player.x, player.y, font, 20 )
    text["player"].alpha = 0

    player.sensor = display.newCircle( groupPlayer, player.x, player.y, playerSensorRadius )
    player.sensor:setFillColor( 0.8, 0, 0.8 )
    player.sensor.alpha = SENSOR_ALPHA and SENSOR_ALPHA or 0
    physics.addBody( player.sensor, "dynamic", { radius=playerSensorRadius, isSensor=true, filter=playerSensorFilter } )
    player.sensor.name = "player"
    player.sensor.collision = onCollision
    player.joint = physics.newJoint( "weld", player, player.sensor, player.x, player.y )

    darkness = display.newRect( 0, 0, screen.width, screen.height )
    darkness:setFillColor( 0 )
    snapshot.canvas:insert( darkness )
    lantern = display.newImageRect( "images/light.png", lanternRadius, lanternRadius )
    lantern:setFillColor( 1 )
    snapshot.canvas:insert( lantern )
	campfireLight = display.newImageRect( "images/light.png", campfireRadius*2, campfireRadius )
    campfireLight:setFillColor( 1 )
    snapshot.canvas:insert( campfireLight )
    snapshot.blendMode = "multiply"
    snapshot.alpha = darknessAlpha

    background = display.newRect( groupBackground, screen.centreX, screen.centreY, screen.width, screen.height )
    background.fill = {
        type = "gradient",
        color1 = { 0.06 },
        color2 = { 0.05, 0.06, 0.1 },
        direction = "down"
    }

    logo = display.newImageRect( groupUI, "images/logo.png", 240, 240 )
    logo.x, logo.y = screen.centreX, screen.centreY - 40
    logo.yStart = logo.y
    logo.alpha = 0

    text["gameover"] = display.newText( groupUI, "The Darkness is terrifying.", screen.centreX, screen.centreY, fontHeading, 36 )
    text["gameover"].alpha = 0

    text["title"] = display.newText( groupUI, "The Dark", screen.centreX, 70, fontHeading, 60 )
    text["title"].yStart = text["title"].y
    text["title"].alpha = 0

    text["start"] = display.newText( groupUI, "Tap to start", screen.centreX, 580, font, 36 )
    text["start"].yStart = text["start"].y
    text["start"].alpha = 0

    text[1] = display.newText( groupDialogue, "There's no telling what lies in the dark...", 130, 220, font, 36 )
    text[2] = display.newText( groupDialogue, "...and I'm too scared to find out.", 250, 280, font, 36 )
    text[3] = display.newText( groupDialogue, "And so I must keep the fire alive.", 210, 360, font, 36 )
    underline = display.newRect( groupDialogue, text[3].x + 240, text[3].y + text[3].height*0.5 + 20, 2, 4 )
    underline.alpha, underline.anchorX = 0, 0

    for i = 1, #text do
        text[i].alpha = 0
        text[i].anchorX = 0
    end

    forestLeft = display.newImageRect( groupMap, "images/forestLeft.png", 140, 200 )
	forestLeft.x, forestLeft.y = screen.centreX + moveMin - forestPadding, 0
    forestLeft.anchorX, forestLeft.anchorY = 1, 1
    forestLeft:toBack()
    forestLeft.fadeLeft = display.newRect( groupMap, forestLeft.x, screen.centreY, forestLeft.width, screen.height )
    forestLeft.fadeLeft.anchorX = 1
    forestLeft.fadeLeft.fill = {
        type = "gradient",
        color1 = { 0, 1 },
        color2 = { 0, 0 },
        direction = "right"
    }
    forestLeft.blackLeft = display.newRect( groupMap, forestLeft.x - forestLeft.width, screen.centreY, 320, screen.height )
    forestLeft.blackLeft.anchorX = 1
    forestLeft.blackLeft:setFillColor(0)

	-- text["forestLeft"] = display.newText( groupDialogue, "I'm not going to the forest at night!", forestLeft.x + 30, player.y, font, 20 )
    -- text["forestLeft"].anchorX, text["forestLeft"].alpha = 0, 0

    forestRight = display.newImageRect( groupMap, "images/forestRight.png", 140, 200 )
	forestRight.x, forestRight.y = screen.centreX + moveMax + forestPadding, 0
    forestRight.anchorX, forestRight.anchorY = 0, 1
    forestRight:toBack()
    forestRight.fadeRight = display.newRect( groupMap, forestRight.x, screen.centreY, forestRight.width, screen.height )
    forestRight.fadeRight.anchorX = 0
    forestRight.fadeRight.fill = {
        type = "gradient",
        color1 = { 0, 1 },
        color2 = { 0, 0 },
        direction = "left"
    }
    forestRight.blackRight = display.newRect( groupMap, forestRight.x + forestRight.width, screen.centreY, 320, screen.height )
    forestRight.blackRight.anchorX = 0
    forestRight.blackRight:setFillColor(0)

	-- text["forestRight"] = display.newText( groupDialogue, "I'm not going to the forest at night!", forestRight.x - 30, player.y, font, 20 )
    -- text["forestRight"].anchorX, text["forestRight"].alpha = 1, 0

	text["move"] = display.newText( groupUI, "Use A/D or left/right arrows to move.", screen.minX+10, screen.minY+10, font, 14 )
	text["move"].anchorX, text["move"].anchorY = 0, 0
	text["move"].alpha = 0

    text["sfx"] = display.newText( groupUI, "Press S to mute sounds.", screen.minX+10, text["move"].y+text["move"].height+4, font, 14 )
	text["sfx"].anchorX, text["sfx"].anchorY = 0, 0
	text["sfx"].alpha = 0

    text["space"] = display.newText( groupUI, "Press SPACE to interact.", screen.minX+10, text["sfx"].y+text["sfx"].height+4, font, 14 )
	text["space"].anchorX, text["space"].anchorY = 0, 0
	text["space"].alpha = 0

    text["restart"] = display.newText( groupUI, "Press Q to restart.", screen.minX+10, text["space"].y+text["space"].height+4, font, 14 )
	text["restart"].anchorX, text["restart"].anchorY = 0, 0
	text["restart"].alpha = 0

    sceneGroup:insert( groupBackground )
    sceneGroup:insert( groupPlayer )
    sceneGroup:insert( groupSnow )
    sceneGroup:insert( groupMap )
    sceneGroup:insert( groupLight )
    sceneGroup:insert( groupDialogue )
    sceneGroup:insert( groupUI )
end

-- Once the scene has been created, then load the introduction dialogue.
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "did" ) then
        if SKIP_TO then
            if SKIP_TO == "logo" then
                showLogo( true )
            elseif SKIP_TO == "game" then
                showLogo( true, {phase="ended",skip=true} )
            end
        else
            local initialDelay = 800
            local duration = 1200

            local function showRest()
                for i = 2, #text do
                    _transitionTo( text[i], { delay=initialDelay*(i-1)+duration*(i-2), time=duration, alpha=1, y=text[i].y+20 })
                end
                timer.performWithDelay( initialDelay*(#text-1)+duration*(#text-1), function()
                    _transitionTo( underline, { time=duration, alpha=1, width=292, onComplete=clearDialogue })
                end )
            end
            _transitionTo( text[1], { delay=initialDelay, time=duration, alpha=1, y=text[1].y+20, onComplete=showRest })
        end
    end
end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
-- -----------------------------------------------------------------------------------

return scene
