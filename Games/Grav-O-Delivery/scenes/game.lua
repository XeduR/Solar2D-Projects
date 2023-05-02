local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local rng = require("classes.rng")
local json = require( "json" )
local loadsave, savedata

local kernel = require("assets.shaders.filter_fisheye")
graphics.defineEffect( kernel )

local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )
-- physics.setDrawMode( "hybrid" )

---------------------------------------------------------------------------

-- Forward declarations & variables.
local groupBackground = display.newGroup()
local groupPlanets = display.newGroup()
local groupUI = display.newGroup()
local HUD = display.newGroup()
HUD.target = {}

local random = math.random
local floor = math.floor
local sqrt = math.sqrt
local atan2 = math.atan2
local deg = math.deg
local rad = math.rad
local cos = math.cos
local sin = math.sin
local min = math.min

local updateHUD, newgame, gameover

local button = {}
local planet = {}
local parcel = {}
local satellite = {}
local spacestation

local parcelsShot = 0
local successCount = 0
local currentDelivery = 1
local highscore = 0
local parcelSource, parcelTarget, targetTag


---------------------------------------------------------------------------

local minDistance = 20 -- Dragging below this will cancel the parcel shot.
local maxDistance = 140 -- Dragging above this will be capped to this distance.

local parcelWidth = 20
local parcelHeight = 12
local firingStrength = 320
local globalGravityModifier = 0.0015

local sizeHUD = {
	planet = 48,
	spacestation = 40,
	satellite = 26,
}

local spacestationMoveHorizontal = 80
local spacestationMoveVertical = 30

local yLevel = 360

local planetData = {
	{ x=130, y=yLevel, radius=48, rotationModifier=1.5, gravityModifier=2, image="assets/images/planet1.png" },
	{ x=330, y=yLevel, radius=64, rotationModifier=1.3, gravityModifier=1.25, image="assets/images/planet2.png" },
	{ x=560, y=yLevel, radius=120, rotationModifier=0.6, gravityModifier=1, image="assets/images/planet3.png" },
	{ x=810, y=yLevel, radius=64, rotationModifier=1.1, gravityModifier=1.25, image="assets/images/planet4.png" },
}

local satelliteData = {
	{ planet=2, startPos=80, radius=8, speed=0.25 },
	{ planet=3, startPos=30, radius=10, speed=0.35 },
	{ planet=3, startPos=160, radius=12, speed=0.35 },
	{ planet=4, startPos=220, radius=10, speed=0.25 },
}

local deliveries = {
	{ "planet3", "planet4", "satellite4" }, -- planet1
	{ "planet4", "satellite4" }, -- planet2
	{ "planet1", "spacestation" }, -- planet3
	{ "planet1", "planet2", "satellite1", "spacestation" }, -- planet4
}

local starCount = 1200
rng.randomseed( 1000 )

local masterVolume = 0.75
local bgmVolume = 0.35
local sfxVolume = 0.5

local fontName = "assets/fonts/munro.ttf"

---------------------------------------------------------------------------

-- Create a delivery route from the deliveries table.
local deliveryRoute = {}
for i = 1, #deliveries do
	for j = 1, #deliveries[i] do
		deliveryRoute[#deliveryRoute+1] = { "planet" .. i, deliveries[i][j] }
	end
end

-- DEBUG: for quick gameover.
-- deliveryRoute = {}
-- deliveryRoute[1] = { "planet1", "planet2" }

display.setDefault( "background", 5/255, 5/255, 25/255 )
display.setDefault( "magTextureFilter", "nearest" )
display.setDefault( "minTextureFilter", "nearest" )

local filePath = system.pathForFile( "data/particleStarfield.json" )
local f = io.open( filePath, "r" )
local emitterData = f:read( "*a" )
local emitterParams = json.decode( emitterData )
f:close()

audio.setVolume( masterVolume )
-- audio.loadSFX( "assets/audio" )

local sfx = {
	bgm = audio.loadSound( "assets/audio/sinnesloschen-beam-117362.mp3" ),
	success = audio.loadSound( "assets/audio/success.wav" ),
	failure = audio.loadSound( "assets/audio/failure.wav" ),
	fire = audio.loadSound( "assets/audio/fire.wav" ),
	newgame = audio.loadSound( "assets/audio/newgame.wav" ),
	gameover = audio.loadSound( "assets/audio/gameover.wav" ),
}

---------------------------------------------------------------------------

-- Fisher-Yates shuffle:
local function shuffle( t )
	for i = #t, 2, -1 do
	  local j = random(i)
	  t[i], t[j] = t[j], t[i]
	end
end


-- Start attracting parcels to the planet.
local function gravityField( self, event )
	local objectToPull = event.other
	local gotJoint = objectToPull.joint[self.id]

	if event.phase == "began" and not gotJoint then
        timer.performWithDelay( 10, function()
			-- Make sure that the parcle still exists.
			if type( objectToPull ) == "table" and tonumber( objectToPull.width ) and objectToPull.width ~= 0 and objectToPull.inGame then
				local joint = physics.newJoint( "touch", objectToPull, objectToPull.x, objectToPull.y )
				if joint then
					joint.frequency = self.gravity
					joint.dampingRatio = 0.0
					joint:setTarget( self.x, self.y )

					objectToPull.joint[self.id] = joint
				end
			end
		end )

	elseif event.phase == "ended" and gotJoint then
        objectToPull.joint[self.id]:removeSelf()
        objectToPull.joint[self.id] = nil

    end
end


local function parcelHit( target, success )
	local popupSize = 24
	local popup

	if success then
		-- audio.play( "assets/audio/success.wav" )
		audio.play( sfx.success )

		successCount = successCount + 1
		HUD.parcel[target.id]:setFillColor( 0, 0.8, 0 )

		popup = display.newImage( groupUI, "assets/images/success.png", target.x, target.y )
	else
		-- audio.play( "assets/audio/failure.wav" )
		audio.play( sfx.failure )

		HUD.parcel[target.id]:setFillColor( 0.8, 0, 0 )

		popup = display.newImage( groupUI, "assets/images/failure.png", target.x, target.y )
	end


	if popup then
		transition.to( popup, { time=500, delay=50, alpha=0, xScale=1.25, yScale=1.25, onComplete=function()
			display.remove( popup )
			popup = nil
		end } )
	end
end

local function parcelCollision( self, event )
	local other = event.other

	if event.phase == "began" then
		if other and other.type ~= "gravitation" then
			timer.performWithDelay( 10, function()
				if type( self ) == "table" and self.inGame then
					display.remove( self )
					self.inGame = false
				end
			end )


			if other.type == "levelBounds" then
				parcelHit( self, false )
			else
				-- print( "target:", self.target, self.id, "hit:", other.id )
				if self.target == other.id then
					parcelHit( self, true )
				else
					parcelHit( self, false )
				end
			end

			if parcelsShot >= #deliveryRoute then
				gameover()
			end

			updateHUD( false )
		end
	end
end

-- Aim and launch parcels.
local function aim( event )
	local target = event.target
	local phase = event.phase

	-- Allow parcels to be fired only from the current source planet.
	if target.id == parcelSource and parcelsShot < #deliveryRoute then

		display.remove( target.lineEnd )
		target.lineEnd = nil

		if phase == "began" or phase == "moved" then

			if not target.touchStarted then
				display.getCurrentStage():setFocus( target )
				target.touchStarted = true
			end

			-- Draw a simple line to help the player aim.
			local distance = min( sqrt( event.xDelta*event.xDelta + event.yDelta*event.yDelta ), maxDistance )

			target.angle = atan2( event.yDelta, event.xDelta )
			target.xStart = target.x - cos( target.angle ) * target.width*0.5
			target.yStart = target.y - sin( target.angle ) * target.width*0.5
			target.xLaunch = target.xStart - cos( target.angle ) * (parcelWidth*1.5)
			target.yLaunch = target.yStart - sin( target.angle ) * (parcelWidth*1.5)

			local n = #target.aim-1
			for i = 1, #target.aim do
				target.aim[i].x = target.xStart - cos( target.angle ) * (distance*(i-1)/n)
				target.aim[i].y = target.yStart - sin( target.angle ) * (distance*(i-1)/n)
				target.aim[i].isVisible = true
			end

			local r, g, b = 0, 0, 0
			if distance < minDistance then
				r = 0.85
				target.launchStrength = nil
			else
				g = 0.85
				target.launchStrength = (distance-minDistance)/(maxDistance-minDistance)*firingStrength
			end

			for i = 1, #target.aim do
				target.aim[i]:setStrokeColor( r, g, b )
				target.aim[i].isVisible = true
			end


			target.lineEnd = display.newText({
				parent = groupUI,
				text = target.launchStrength and tostring( floor( ((distance-minDistance)/(maxDistance-minDistance))*100 ) ) .. "%" or "0%",
				x = target.xStart - cos( target.angle ) * (distance + 32),
				y = target.yStart - sin( target.angle ) * (distance + 32),
				font = fontName,
				fontSize = 30,
				align = "center"
			})
			target.lineEnd:setFillColor( r, g, b )

		else
			display.getCurrentStage():setFocus( nil )
			target.touchStarted = false

			-- Hide the aim assist line.
			for i = 1, #target.aim do
				target.aim[i].isVisible = false
			end

			if target.launchStrength then
				local newParcel = display.newImageRect( groupUI, "assets/images/parcel.png", parcelWidth, parcelHeight )
				newParcel.x, newParcel.y = target.xLaunch, target.yLaunch
				newParcel.id = #parcel+1
				newParcel.joint = {}
				newParcel.inGame = true
				newParcel.target = parcelTarget

				physics.addBody( newParcel, "dynamic", { isSensor=true } )
				newParcel.collision = parcelCollision
				newParcel:addEventListener( "collision" )
				newParcel:setLinearVelocity( -cos( target.angle ) * target.launchStrength, -sin( target.angle ) * target.launchStrength )
				newParcel.xPrev, newParcel.yPrev = newParcel.x, newParcel.y

				parcel[#parcel+1] = newParcel

				if parcelsShot == 0 then
					transition.to( guide, { time=500, alpha=0 } )
				end

				-- audio.play( "assets/audio/fire.wav" )
				audio.play( sfx.fire )

				parcelsShot = parcelsShot + 1
				updateHUD( true )
			end
		end
	end
end


local function update()
	-- Update planet, satellite and spacestation positions.
	for i = 1, #planet do
		planet[i].fill.effect.offX = planet[i].fill.effect.offX + 0.001*planet[i].rotationModifier
		planet[i].fill.effect.offY = planet[i].fill.effect.offY + 0.0001*planet[i].rotationModifier

		planet[i].clouds.fill.effect.offX = planet[i].clouds.fill.effect.offX + 0.001*planet[i].rotationModifier
		planet[i].clouds.fill.effect.offY = planet[i].clouds.fill.effect.offY + 0.0001*planet[i].rotationModifier
	end

	for i = 1, #satelliteData do
		if satellite[i] then
			satellite[i].position = satellite[i].position + satellite[i].speed

			local angle = rad( satellite[i].position )
			satellite[i].x = satellite[i].planet.x + cos( angle - 45 ) * satellite[i].planet.width*0.5
			satellite[i].y = satellite[i].planet.y + sin( angle - 45  ) * satellite[i].planet.width*0.5

			-- Rotate the satellites as they orbit the planets.
			local rotation = atan2( satellite[i].y - satellite[i].planet.y, satellite[i].x - satellite[i].planet.x )
			satellite[i].rotation = deg( rotation ) + 90
		end
	end

	spacestation.fill.effect.offX = spacestation.fill.effect.offX + 0.005
	spacestation.fill.effect.offY = spacestation.fill.effect.offY + 0.003
	spacestation.position = spacestation.position + 1
	spacestation.x = spacestation.xBase + cos( rad( spacestation.position ) ) * spacestationMoveHorizontal
	spacestation.y = spacestation.yBase + sin( rad( spacestation.position ) ) * spacestationMoveVertical

	---------------------------------------------------------------

	-- Update parcel rotations.
	for i = 1, #parcel do
		if parcel[i].inGame then
			local angle = atan2( parcel[i].y - parcel[i].yPrev, parcel[i].x - parcel[i].xPrev )

			parcel[i].rotation = deg( angle )
			parcel[i].xPrev, parcel[i].yPrev = parcel[i].x, parcel[i].y
		end
	end


	if parcelTarget then
		local t = HUD.target[parcelTarget].realTarget
		targetTag.x, targetTag.y = t.x, t.y - t.height*0.5 - 10
	end
end


-- HUD can be updated to show a new target, or to update the success/failure count.
local nPrev
function updateHUD( getNewTarget )
	if getNewTarget then
		if currentDelivery <= #deliveryRoute then
			-- Hide the old source and target from the HUD.
			if parcelTarget then
				HUD.target[parcelTarget].isVisible = false
			end
			if parcelTarget then
				HUD.target[parcelSource].isVisible = false
			end

			local thisDelivery = deliveryRoute[currentDelivery]
			parcelSource = thisDelivery[1]
			parcelTarget = thisDelivery[2]

			HUD.target[parcelSource].x = HUD.fromText.x + HUD.fromText.width*0.5 + (HUD.toText.contentBounds.xMin - HUD.fromText.contentBounds.xMax)*0.5
			HUD.target[parcelSource].y = HUD.fromText.y
			HUD.target[parcelSource].isVisible = true

			HUD.target[parcelTarget].x = HUD.toText.x + HUD.toText.width*0.5 + (HUD.panel.contentBounds.xMax - HUD.toText.contentBounds.xMax)*0.5
			HUD.target[parcelTarget].y = HUD.toText.y
			HUD.target[parcelTarget].isVisible = true
			HUD.target[parcelSource].isVisible = true

			-- A bit clunky way of getting the planet number from the parcel source.
			-- Last minute changes and not enough time to write/fix it properly.
			local n = tonumber( parcelSource:sub(-1) )

			if nPrev then
				planet[nPrev]:setState( "inactive" )
			end
			planet[n]:setState( "active" )

			currentDelivery = currentDelivery + 1
			nPrev = n
		else
			planet[nPrev]:setState( "inactive" )

			parcelTarget = nil
			targetTag.x, targetTag.y = screen.minX - 100, screen.minY - 100
		end
	end
end


function newgame()
	-- Reset the delivery route order every game.
	shuffle( deliveryRoute )

	for _, v in pairs( HUD.target ) do
		v.isVisible = false
	end

	parcelsShot = 0
	currentDelivery = 1
	successCount = 0
	nPrev = nil

	for i = 1, #deliveryRoute do
		HUD.parcel[i]:setFillColor( 0.2 )
	end

	transition.to( guide, { time=500, alpha=1, onComplete=function()
		-- audio.play( "assets/audio/newgame.wav" )
		audio.play( sfx.newgame )

		updateHUD( true )

		transition.to( HUD, { time=500, y=HUD.yRevealed, transition=easing.outQuad } )
	end } )

end


function gameover( didRestart )

	-- Remove all parcels (only necessary if player restarts).
	for i = 1, #parcel do
		display.remove( parcel[i] )
		parcel[i] = nil
	end

	if didRestart then
		if nPrev then
			planet[nPrev]:setState( "inactive" )
		end

		parcelTarget = nil
		targetTag.x, targetTag.y = screen.minX - 100, screen.minY - 100

		transition.to( HUD, { time=500, y=HUD.yHidden, transition=easing.outQuad, onComplete=newgame } )

	else
		transition.to( HUD, { time=500, y=HUD.yHidden, transition=easing.outQuad } )

		-- Show player score and highscore.
		local score = floor( successCount / #deliveryRoute * 100 )
		local highscore = savedata.highscore or 0
		local newHighscore = false
		if score > highscore then
			highscore = score
			newHighscore = true
			savedata.highscore = highscore
			loadsave.save( savedata, "data.json" )
		end

		-- Cover the screen with a black rectangle.
		local cover = display.newRect( groupUI, screen.centerX, screen.centerY, screen.width, screen.height )
		cover:setFillColor( 0, 0.1 )

		local window = display.newGroup()
		groupUI:insert( window )

		window.panel = display.newRoundedRect( window, screen.centerX, screen.centerY, 480, 280, 8 )
		window.panel:setFillColor( 0, 0.5 )
		window.panel.strokeWidth = 1

		-- Create a title and text for the window.
		window.title = display.newText({
			parent = window,
			text = "GAMEOVER",
			x = window.panel.x,
			y = window.panel.y - window.panel.height*0.5 + 32,
			width = window.panel.width - 16,
			align = "center",
			font = fontName,
			fontSize = 48,
		})

		window.text = display.newText({
			parent = window,
			text = "SUCCESSFUL DELIVERIES: " .. score .. "%\n\nHIGHSCORE: " .. highscore .. "%",
			x = window.panel.x,
			y = window.panel.y,
			width = window.panel.width - 16,
			align = "center",
			font = fontName,
			fontSize = 32,
		})

		if newHighscore then
			window.highscore = display.newText({
				parent = window,
				text = "NEW HIGHSCORE!",
				x = window.panel.x,
				y = window.panel.y + window.panel.height*0.5 - 32,
				width = window.panel.width - 16,
				align = "center",
				font = fontName,
				fontSize = 40,
			})
			window.highscore:setFillColor( 0.9, 0.75, 0 )

		else
			-- Move texts down a bit if there's no highscore text.
			window.title.y = window.title.y + 32
			window.text.y = window.text.y + 32

		end

		transition.from( window, { time=500, alpha=0, onComplete=function()
			-- audio.play( "assets/audio/gameover.wav" )
			audio.play( sfx.gameover )
		end } )

		local continue = display.newText({
			parent = groupUI,
			text = "CLICK TO PLAY AGAIN",
			x = window.panel.x,
			y = window.panel.y + window.panel.height*0.5 + 60,
			width = window.panel.width - 16,
			align = "center",
			font = fontName,
			fontSize = 48,
		})
		continue.alpha = 0

		-- Fade in the continue text and make it blink.
		transition.to( continue, { delay=750, time=750, alpha=1, onComplete=function()
			transition.blink( continue, { time=1000 } )

			-- Start a new game after hiding the gameover screen.
			cover:addEventListener( "touch", function( event )
				if event.phase == "ended" then
					transition.cancel( continue )

					transition.to( cover, { time=500, alpha=0 } )
					transition.to( window, { time=500, alpha=0 } )
					transition.to( continue, { time=500, alpha=0, onComplete=function()
						display.remove( cover )
						display.remove( window )
						display.remove( continue )
						newgame()
					end } )
				end
			end )
		end } )
	end
end


local function toggleSFX( event )
	if event.phase == "ended" then
		local id = event.target.id

		savedata[id] = not savedata[id]

		if savedata[id] then
			button[id].fill = button[id].fillOn
		else
			button[id].fill = button[id].fillOff
		end

		if id == "music" then
			audio.setVolume( savedata.music and bgmVolume or 0, { channel=1 } )
		else
			local _sfxVolume = savedata.sound and sfxVolume or 0
			for i = 2, 32 do
				audio.setVolume( _sfxVolume, { channel=i } )
			end
		end

		loadsave.save( savedata, "data.json" )
	end
	return true
end

---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view
	-- If the project uses savedata, then load existing data or set it up.
	if event.params and event.params.usesSavedata then
		loadsave = require("classes.loadsave")
		savedata = loadsave.load("data.json")

		if not savedata then
			-- Assign initial values for save data.
			savedata = {
				music = true,
				sound = true,
				highscore = 0,
			}
			loadsave.save( savedata, "data.json" )
		end

		-- Assign/update variables based on save data, e.g. volume, highscores, etc.
		audio.setVolume( savedata.music and bgmVolume or 0, { channel=1 } )

		local _sfxVolume = savedata.sound and sfxVolume or 0
		for i = 2, 32 do
			audio.setVolume( _sfxVolume, { channel=i } )
		end

		highscore = savedata.highscore
	end


	---------------------------------------------------------------

	-- Create physics walls for the screen edges.
	local wallThickness = 20
	local wallLeft = display.newRect( groupBackground, screen.minX - wallThickness*0.5 - parcelWidth*2, screen.centerY, wallThickness, screen.height+wallThickness*2 )
	physics.addBody( wallLeft, "static" )
	wallLeft.type = "levelBounds"

	local wallRight = display.newRect( groupBackground, screen.maxX + wallThickness*0.5 + parcelWidth*2, screen.centerY, wallThickness, screen.height+wallThickness*2 )
	physics.addBody( wallRight, "static" )
	wallRight.type = "levelBounds"

	local wallTop = display.newRect( groupBackground, screen.centerX, screen.minY - wallThickness*0.5 - parcelWidth*2, screen.width+wallThickness*2, wallThickness )
	physics.addBody( wallTop, "static" )
	wallTop.type = "levelBounds"

	local wallBottom = display.newRect( groupBackground, screen.centerX, screen.maxY + wallThickness*0.5 + parcelWidth*2, screen.width+wallThickness*2, wallThickness )
	physics.addBody( wallBottom, "static" )
	wallBottom.type = "levelBounds"

	---------------------------------------------------------------

	-- Create background stars.
	local emitter = display.newEmitter( emitterParams )
	emitter.x = display.contentCenterX
	emitter.y = display.contentCenterY
	groupBackground:insert( emitter )

	-- Using my RNG module to ensure the same stars are generated on all devices/platforms.
	for _ = 1, starCount do
		local star = display.newRect( groupBackground, rng.random( screen.minX, screen.maxX ), rng.random( screen.minY, screen.maxY ), rng.random( 2 ), rng.random( 2 ) )
		star:setFillColor( 1, 0.9 + rng.random()*0.1, 0.9 + rng.random()*0.1, rng.random( 5, 10 )*0.1 )
	end

	---------------------------------------------------------------

	local galaxyCentre = display.newImage( groupPlanets, "assets/images/galaxyCentre.png", screen.minX, yLevel )
	galaxyCentre.xStart, galaxyCentre.yStart = galaxyCentre.x, galaxyCentre.y

	-- Bounce the galaxy centre.
	transition.to( galaxyCentre, { time=5000, x=galaxyCentre.xStart+random(2), y=galaxyCentre.yStart+random(2), xScale=1.2, yScale=1.2, rotation=15, transition=easing.continuousLoop, iterations=-1 } )

	display.setDefault( "textureWrapX", "repeat" )
	display.setDefault( "textureWrapY", "repeat" )

	-- Create the planets.
	for i = 1, #planetData do
		local radius = planetData[i].radius

		-- Create the planet's body.
		local newPlanet = display.newCircle( groupPlanets, planetData[i].x, planetData[i].y, radius )
		newPlanet:addEventListener( "touch", aim )
		physics.addBody( newPlanet, "static", { radius=newPlanet.width*0.5 } )
		newPlanet.type = "planet"
		newPlanet.id = "planet" .. i

		-- Set up the planet's texture.
		newPlanet.fill = {
			type = "image",
			filename = planetData[i].image,
		}
		newPlanet.fill.rotation = rng.random( -45, 45 )
		newPlanet.fill.effect = "filter.custom.fisheye"
		newPlanet.fill.effect.intensity = 25
		newPlanet.rotationModifier = planetData[i].rotationModifier

		-- Add shading to the planet.
		newPlanet.shading = display.newImageRect( groupPlanets, "assets/images/planetShading.png", newPlanet.width+2, newPlanet.height+2 )
		newPlanet.shading.x, newPlanet.shading.y = newPlanet.x, newPlanet.y

		-- Create clouds.
		newPlanet.clouds = display.newCircle( groupPlanets, planetData[i].x, planetData[i].y, radius )

		newPlanet.clouds.fill = {
			type = "image",
			filename = "assets/images/" .. newPlanet.id .. "clouds.png",
		}
		newPlanet.clouds.fill.rotation = rng.random( -45, 45 )
		newPlanet.clouds.fill.effect = "filter.custom.fisheye"
		newPlanet.clouds.fill.effect.intensity = 25

		newPlanet.clouds.fill.effect.offX = rng.random()
		newPlanet.clouds.fill.effect.offY = rng.random()


		newPlanet.clouds.rotationModifier = planetData[i].rotationModifier*0.25

		---------------------------------------------------------------

		-- Create a HUD version of the planet.
		local planetHUD = display.newGroup()
		planetHUD.realTarget = newPlanet
		HUD:insert( planetHUD )

		planetHUD.planet = display.newCircle( planetHUD, 0, 0, radius )

		planetHUD.planet.fill = {
			type = "image",
			filename = planetData[i].image,
		}
		planetHUD.planet.fill.effect = "filter.custom.fisheye"
		planetHUD.planet.fill.effect.intensity = 25

		-- Create a HUD version of the planet's shading.
		planetHUD.shading = display.newImageRect( planetHUD, "assets/images/planetShading.png", planetHUD.width+2, planetHUD.height+2 )
		planetHUD.shading.x, planetHUD.shading.y = planetHUD.x, planetHUD.y

		-- Create a HUD version of the planet's clouds.
		planetHUD.clouds = display.newCircle( planetHUD, planetHUD.x, planetHUD.y, radius )

		planetHUD.clouds.fill = {
			type = "image",
			filename = "assets/images/" .. newPlanet.id .. "clouds.png",
		}
		planetHUD.clouds.fill.rotation = rng.random( -45, 45 )
		planetHUD.clouds.fill.effect = "filter.custom.fisheye"
		planetHUD.clouds.fill.effect.intensity = 25

		planetHUD.clouds.fill.effect.offX = rng.random()
		planetHUD.clouds.fill.effect.offY = rng.random()

		-- -- Scale the HUD planet.
		local scale = sizeHUD.planet / planetHUD.width
		planetHUD:scale( scale, scale )

		HUD.target[newPlanet.id] = planetHUD

		---------------------------------------------------------------

		-- Create a circle to represent the planet's gravitation.
		newPlanet.gravitation = display.newCircle( groupPlanets, planetData[i].x, planetData[i].y, radius*2 )

		-- Try setting up a radial gradient fill for the gravitation circle.
		newPlanet.gravitation.fill.effect = "generator.radialGradient"
		newPlanet.gravitation.fill.effect.color1 = { 0, 0, 0, 1 }
		newPlanet.gravitation.fill.effect.color2 = { 1, 1, 1, 0.15 }
		newPlanet.gravitation.fill.effect.center_and_radiuses  =  { 0.5, 0.5, 0.55, 0.15 }
		newPlanet.gravitation.fill.effect.aspectRatio  = 1
		newPlanet.gravitation.alpha = 0.35
		newPlanet.gravitation.blendMode = "add"

		-- Create a dot stroke for the gravitation circle.
		newPlanet.groupStroke = display.newGroup()
		newPlanet.groupStroke.x, newPlanet.groupStroke.y = newPlanet.x, newPlanet.y
		newPlanet.groupStroke:toBack()

		-- Assign a dynamic number of dots to the stroke.
		local dots = floor( 4*radius*math.pi )*0.08
		local n, theta, dtheta = 1, 0, math.pi*2/dots

		for _ = 1, dots*2, 2 do
			newPlanet.groupStroke[n] = display.newCircle( newPlanet.groupStroke, radius*2 * cos(theta), radius*2 * sin(theta), 2 )
			newPlanet.groupStroke[n]:setFillColor( 1, 0.35 )
			newPlanet.groupStroke[n].strokeWidth = 1
			newPlanet.groupStroke[n]:setStrokeColor( 1, 0.15 )

			theta = theta + dtheta
			n = n+1
		end

		local function rotateStroke()
			transition.to( newPlanet.groupStroke, { time=1000, rotation=newPlanet.groupStroke.rotation + 1, onComplete=rotateStroke } )
		end
		rotateStroke()

		function newPlanet:setState( state )
			local greyscale, alpha = 1, 0.75

			if state == "inactive" then
				greyscale, alpha = 1, 0.35
			end

			for i = 1, dots do
				self.groupStroke[i]:setStrokeColor( greyscale, alpha - 0.2 )
				self.groupStroke[i]:setFillColor( greyscale, alpha )
			end
		end

		-- Set up the gravitation circle's physics.
		physics.addBody( newPlanet.gravitation, "static", { radius=newPlanet.gravitation.width*0.5 } )
		newPlanet.gravitation.gravity = planetData[i].radius*planetData[i].gravityModifier*globalGravityModifier
		newPlanet.gravitation.type = "gravitation"
		newPlanet.gravitation.id = i

		newPlanet.gravitation.collision = gravityField
		newPlanet.gravitation:addEventListener( "collision" )
		newPlanet.gravitation:toBack()

		---------------------------------------------------------------

		-- Create a circle to represent the planet's orbit.
		newPlanet.orbit = display.newCircle( groupPlanets, screen.minX, planetData[i].y, planetData[i].x-screen.minX )
		newPlanet.orbit:setFillColor( 0, 0 )
		newPlanet.orbit.strokeWidth = 2
		newPlanet.orbit:setStrokeColor( 1, 0.2 )
		newPlanet.orbit:toBack()

		---------------------------------------------------------------

		-- Create a table to store the planet's aim assist circles.
		newPlanet.aim = {}
		for j = 1, 10 do
			newPlanet.aim[j] = display.newCircle( groupUI, newPlanet.x, newPlanet.y, 2 )
			newPlanet.aim[j].strokeWidth = 2
			newPlanet.aim[j]:setStrokeColor( 0, 0.85, 0 )
			newPlanet.aim[j].isVisible = false
		end

		planet[i] = newPlanet
	end

	---------------------------------------------------------------

	-- Create a spacestation.
	spacestation = display.newCircle( groupPlanets, 100, screen.minY+100, 16 )

	-- Set up the spacestation's texture.
	spacestation.fill = {
		type = "image",
		filename = "assets/images/spacestation.png",
	}
	spacestation.fill.rotation = rng.random( -45, 45 )
	spacestation.fill.effect = "filter.custom.fisheye"
	spacestation.fill.effect.intensity = 8
	spacestation.rotationModifier = 1

	physics.addBody( spacestation, "static", { radius=spacestation.width*0.5 } )
	spacestation.xBase, spacestation.yBase = spacestation.x, spacestation.y
	spacestation.position = 0
	spacestation.yOffset = 0
	spacestation.type = "spacestation"
	spacestation.id = "spacestation"

	---------------------------------------------------------------

	-- Create a HUD version of the spacestation.
	HUD.target["spacestation"] = display.newCircle( HUD, 0, 0, spacestation.width*0.5 )
	HUD.target["spacestation"].realTarget = spacestation

	-- Set up the spacestation's texture.
	HUD.target["spacestation"].fill = {
		type = "image",
		filename = "assets/images/spacestation.png",
	}
	HUD.target["spacestation"].fill.effect = "filter.custom.fisheye"
	HUD.target["spacestation"].fill.effect.intensity = 8
	HUD.target["spacestation"].rotationModifier = 1

	-- Scale the HUD spacestation.
	local scale = sizeHUD.spacestation / HUD.target["spacestation"].width
	HUD.target["spacestation"]:scale( scale, scale )

	---------------------------------------------------------------

	display.setDefault( "textureWrapX", "clampToEdge" )
	display.setDefault( "textureWrapY", "clampToEdge" )

	---------------------------------------------------------------

	-- Slight randomisation between game launches.
	local satelliteOffset = random(360)

	-- Create the satellites.
	for i = 1, #satelliteData do
		local parent = planet[satelliteData[i].planet].gravitation

		satellite[i] = display.newImageRect( groupPlanets, "assets/images/satellite.png", satelliteData[i].radius*2, satelliteData[i].radius*2 )
		satellite[i].x, satellite[i].y = parent.x, parent.y
		satellite[i]:setFillColor( 0.7 )
		satellite[i].planet = parent
		satellite[i].position = satelliteData[i].startPos + satelliteOffset
		satellite[i].speed = satelliteData[i].speed
		satellite[i].type = "satellite"
		satellite[i].id = "satellite" .. i

		physics.addBody( satellite[i], "static", { radius=satelliteData[i].radius } )

		-----------------------------------------------------------

		-- Create a HUD version of the satellite.
		HUD.target[satellite[i].id] = display.newCircle( HUD, 0, 0, satelliteData[i].radius )
		HUD.target[satellite[i].id].realTarget = satellite[i]

		HUD.target[satellite[i].id]:setFillColor( 0.7 )

		-- Scale the HUD satellite.
		local scale = sizeHUD.satellite / HUD.target[satellite[i].id].width
		HUD.target[satellite[i].id]:scale( scale, scale )
	end

	---------------------------------------------------------------

	-- Create the HUD.
	local height = 96
	local counterSize = 20
	local counterPadding = 4

	HUD.x, HUD.y = screen.centerX, screen.minY-height*0.5
	HUD.panel = display.newRoundedRect( HUD, 0, screen.minY-1, 320, height, 8 )
	HUD.panel:setFillColor( 0, 0.5 )
	HUD.panel.strokeWidth = 1
	HUD.panel:toBack()

	HUD.yRevealed = screen.minY+HUD.panel.height*0.5-2
	HUD.yHidden = screen.minY - 16
	HUD.y = HUD.yHidden

	local loopStart = -floor( #deliveryRoute*0.5 )
	local loopEnd = floor( #deliveryRoute*0.5 )

	HUD.parcel = {}
	local n = 1
	for i = loopStart, loopEnd do
		local parcelMarker = display.newCircle( HUD, i*(counterSize + counterPadding), 32, counterSize*0.5 )

		parcelMarker.fill.effect = "generator.radialGradient"
		parcelMarker.fill.effect.color1 = { 0, 0, 0, 1 }
		parcelMarker.fill.effect.color2 = { 1, 1, 1, 0.15 }
		parcelMarker.fill.effect.center_and_radiuses  =  { 0.5, 0.5, 0.55, 0.15 }
		parcelMarker.fill.effect.aspectRatio  = 1
		parcelMarker.strokeWidth = 1
		parcelMarker:setStrokeColor( 1, 0.75 )

		HUD.parcel[n] = parcelMarker
		n = n + 1
	end

	HUD.fromText = display.newText({
		parent = HUD,
		text = "DELIVERY FROM:",
		x = -76,
		y = -12,
		font = fontName,
		fontSize = 24,
	})
	HUD.fromText:setFillColor( 1 )

	HUD.toText = display.newText({
		parent = HUD,
		text = "TO:",
		x = 0,
		y = HUD.fromText.y,
		font = fontName,
		fontSize = 24,
	})
	HUD.toText:setFillColor( 1 )
	HUD.toText.x = HUD.fromText.x + HUD.fromText.width*0.5 + HUD.toText.width*0.5 + sizeHUD.planet*1.4

	---------------------------------------------------------------

	local buttonSize = 48
	local buttonPadding = 8

	button["restart"] = display.newRect( groupUI, screen.maxX-buttonSize*0.5 - buttonPadding, screen.minY+buttonSize*0.5 + buttonPadding, buttonSize, buttonSize )
	button["restart"].fill = {
		type = "image",
		filename = "assets/images/restart.png",
	}

	button["restart"]:addEventListener( "touch", function( event )
		if event.phase == "ended" then
			gameover( true )
		end
		return true
	end )

	---------------------------------------------------------------

	button["music"] = display.newRect( groupUI, screen.maxX-buttonSize*1.5 - buttonPadding*2, screen.minY+buttonSize*0.5 + buttonPadding, buttonSize, buttonSize )
	button["music"].id = "music"
	button["music"]:addEventListener( "touch", toggleSFX )

	button["music"].fillOn = {
		type = "image",
		filename = "assets/images/musicOn.png",
	}
	button["music"].fillOff = {
		type = "image",
		filename = "assets/images/musicOff.png",
	}

	if savedata.music then
		button["music"].fill = button["music"].fillOn
	else
		button["music"].fill = button["music"].fillOff
	end

	---------------------------------------------------------------

	button["sound"] = display.newRect( groupUI, screen.maxX-buttonSize*2.5 - buttonPadding*3, screen.minY+buttonSize*0.5 + buttonPadding, buttonSize, buttonSize )
	button["sound"].id = "sound"
	button["sound"]:addEventListener( "touch", toggleSFX )

	button["sound"].fillOn = {
		type = "image",
		filename = "assets/images/soundOn.png",
	}
	button["sound"].fillOff = {
		type = "image",
		filename = "assets/images/soundOff.png",
	}

	if savedata.sound then
		button["sound"].fill = button["sound"].fillOn
	else
		button["sound"].fill = button["sound"].fillOff
	end

	---------------------------------------------------------------

	guide = display.newGroup()
	groupUI:insert( guide )

	guide.panel = display.newRoundedRect( guide, screen.centerX, screen.centerY, 240, 120, 8 )
	guide.panel:setFillColor( 0, 0.5 )
	guide.panel.strokeWidth = 1

	guide.panel.x, guide.panel.y = screen.maxX - guide.panel.width*0.5 - 16, screen.maxY - guide.panel.height*0.5 - 16

	guide.text = display.newText({
		parent = guide,
		text = "DRAG AND HOLD A PLANET TO AIM.\n\nRELEASE TO FIRE.",
		x = guide.panel.x,
		y = guide.panel.y,
		width = guide.panel.width - 16,
		align = "center",
		font = fontName,
		fontSize = 24,
	})

	---------------------------------------------------------------

	targetTag = display.newImage( groupUI, "assets/images/target.png", screen.minX - 100, screen.minY - 100 )
	targetTag.anchorY = 1

	transition.to( targetTag, { time=750, xScale=1.25, yScale=1.25, transition=easing.continuousLoop, iterations=-1 } )

	Runtime:addEventListener( "enterFrame", update )
end

---------------------------------------------------------------------------

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		-- If coming from launchScreen scene, then start by removing it.
		if composer._previousScene == "scenes.launchScreen" then
			composer.removeScene( "scenes.launchScreen" )
		end

	elseif event.phase == "did" then
		-- audio.play( "assets/audio/sinnesloschen-beam-117362.mp3", { channel=1, loops=-1 } )
		audio.play( sfx.bgm, { channel=1, loops=-1 } )

		newgame()
	end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene