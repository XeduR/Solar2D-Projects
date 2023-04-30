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

local random = math.random
local sqrt = math.sqrt
local atan2 = math.atan2
local deg = math.deg
local rad = math.rad
local cos = math.cos
local sin = math.sin
local min = math.min

local planet = {}
local parcel = {}
local satellite = {}
local spacestation
local HUD

---------------------------------------------------------------------------

local minDistance = 20 -- Dragging below this will cancel the parcel shot.
local maxDistance = 150 -- Dragging above this will be capped to this distance.
local minStrokeWidth = 4
local maxStrokeWidth = 12

local parcelWidth = 20
local parcelHeight = 12
local firingStrength = 320
local globalGravityModifier = 0.0015

local spacestationMoveHorizontal = 80
local spacestationMoveVertical = 30

local starCount = 1000
rng.randomseed( 1000 )


---------------------------------------------------------------------------

display.setDefault( "background", 5/255, 5/255, 25/255 )
display.setDefault( "magTextureFilter", "nearest" )
display.setDefault( "minTextureFilter", "nearest" )

local filePath = system.pathForFile( "data/particleStarfield.json" )
local f = io.open( filePath, "r" )
local emitterData = f:read( "*a" )
local emitterParams = json.decode( emitterData )
f:close()

audio.setVolume( 0.25 )
audio.loadSFX( "assets/audio" )

---------------------------------------------------------------------------

-- Functions.
local function gravityField( self, event )
	local objectToPull = event.other
	local gotJoint = objectToPull.joint[self.id]

	if event.phase == "began" and not gotJoint then
        timer.performWithDelay( 10, function()
			-- Make sure that the parcle still exists.
			if type( objectToPull ) == "table" and tonumber(objectToPull.width) and objectToPull.width ~= 0 then
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

local function parcelCollision( self, event )
	local other = event.other

	if event.phase == "began" then
		if other.type ~= "gravitation" then
			timer.performWithDelay( 10, function()
				if type( self ) == "table" and tonumber(self.width) and self.width ~= 0 then
					display.remove( self )
					parcel[self.id] = nil
				end
			end )
		end
	end
end


local function aim( event )
	local target = event.target
	local phase = event.phase

	display.remove( target.lineEnd )
	target.lineEnd = nil
	display.remove( target.line )
	target.line = nil

	if phase == "began" or phase == "moved" then
		-- print( event.xDelta, event.yDelta )

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

		local xEnd = target.xStart - cos( target.angle ) * distance
		local yEnd = target.yStart - sin( target.angle ) * distance

		target.line = display.newLine( groupUI, target.xStart, target.yStart, xEnd, yEnd )

		if distance < minDistance then
			target.line:setStrokeColor( 1, 0, 0 )
			target.launchStrength = nil
		else
			target.line:setStrokeColor( 1, 1, 1 )
			target.launchStrength = (distance-minDistance)/(maxDistance-minDistance)*firingStrength
		end
		target.line.strokeWidth = minStrokeWidth + (maxStrokeWidth-minStrokeWidth) * (distance/maxDistance)

		target.lineEnd = display.newText({
			parent = groupUI,
			text = target.launchStrength and tostring( math.floor( ((distance-minDistance)/(maxDistance-minDistance))*100 ) ) .. "%" or "0%",
			x = target.xStart - cos( target.angle ) * (distance + 20),
			y = target.yStart - sin( target.angle ) * (distance + 20),
			-- font = "assets/fonts/kenvector_future_thin.ttf",
			fontSize = 24,
			align = "center"
		})

	else
		display.getCurrentStage():setFocus( nil )
		target.touchStarted = false

		if target.launchStrength then
			local newParcel = display.newImageRect( groupUI, "assets/images/parcel.png", parcelWidth, parcelHeight )
			newParcel.x, newParcel.y = target.xLaunch, target.yLaunch
			newParcel.id = #parcel+1
			newParcel.joint = {}

			physics.addBody( newParcel, "dynamic", { isSensor=true } )
			newParcel.collision = parcelCollision
			newParcel:addEventListener( "collision" )
			newParcel:setLinearVelocity( -cos( target.angle ) * target.launchStrength, -sin( target.angle ) * target.launchStrength )
			newParcel.xPrev, newParcel.yPrev = newParcel.x, newParcel.y
			-- newParcel.rotation = deg( target.angle ) + 90

			parcel[#parcel+1] = newParcel
		end
	end
end

local function update()
	-- Update planet, satellite and spacestation positions.
	for i = 1, #planet do
		planet[i].fill.effect.offX = planet[i].fill.effect.offX + 0.001*planet[i].rotationModifier
		planet[i].fill.effect.offY = planet[i].fill.effect.offY + 0.0001*planet[i].rotationModifier
	end

	for i = 1, #satellite do
		satellite[i].position = satellite[i].position + satellite[i].speed

		local angle = rad( satellite[i].position )
		satellite[i].x = satellite[i].planet.x + cos( angle - 45 ) * satellite[i].planet.width*0.5
		satellite[i].y = satellite[i].planet.y + sin( angle - 45  ) * satellite[i].planet.width*0.5
	end

	spacestation.position = spacestation.position + 1
	spacestation.x = spacestation.xBase + cos( rad( spacestation.position ) ) * spacestationMoveHorizontal
	spacestation.y = spacestation.yBase + sin( rad( spacestation.position ) ) * spacestationMoveVertical

	---------------------------------------------------------------

	-- Update parcel rotations.
	for i = 1, #parcel do
		if parcel[i] then
			local angle = atan2( parcel[i].y - parcel[i].yPrev, parcel[i].x - parcel[i].xPrev )

			parcel[i].rotation = deg( angle )-- + 90
			parcel[i].xPrev, parcel[i].yPrev = parcel[i].x, parcel[i].y
		end
	end

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

			}
			loadsave.save( savedata, "data.json" )
		end

		-- Assign/update variables based on save data, e.g. volume, highscores, etc.


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

	local emitter = display.newEmitter( emitterParams )
	emitter.x = display.contentCenterX
	emitter.y = display.contentCenterY
	groupBackground:insert( emitter )

	for i = 1, starCount do
		local star = display.newRect( groupBackground, rng.random( screen.minX, screen.maxX ), rng.random( screen.minY, screen.maxY ), 1, 1 )
		star:setFillColor( 1, 0.9 + rng.random()*0.1, 0.9 + rng.random()*0.1, rng.random( 5, 10 )*0.1 )
	end

	---------------------------------------------------------------

	local yLevel = 360
	local planetData = {
		{ x=130, y=yLevel, radius=48, rotationModifier=1.5, gravityModifier=1.5, image="assets/images/planet1.png" },
		{ x=330, y=yLevel, radius=64, rotationModifier=1.3, gravityModifier=1, image="assets/images/planet2.png" },
		{ x=560, y=yLevel, radius=120, rotationModifier=0.6, gravityModifier=1, image="assets/images/planet3.png" },
		{ x=810, y=yLevel, radius=64, rotationModifier=1.1, gravityModifier=1, image="assets/images/planet4.png" },
		-- { x=840, y=220, radius=32, image="assets/images/test.png" },
		-- { x=420, y=480, radius=100, image="assets/images/test.png" },
	}


	local galaxyCentre = display.newCircle( groupPlanets, screen.minX, yLevel, 12 )

	-- Bounce the galaxy centre.
	transition.to( galaxyCentre, { time=5000, xScale=1.2, yScale=1.2, rotation=15, transition=easing.continuousLoop, iterations=-1 } )

	display.setDefault( "textureWrapX", "repeat" )
	display.setDefault( "textureWrapY", "repeat" )

	for i = 1, #planetData do
		-- Create a planet.
		planet[i] = display.newRect( groupPlanets, planetData[i].x, planetData[i].y, planetData[i].radius*2, planetData[i].radius*2 )
		planet[i]:addEventListener( "touch", aim )
		physics.addBody( planet[i], "static", { radius=planet[i].width*0.5 } )
		planet[i].type = "planet"

		-- Set up the planet's texture.
		planet[i].fill = {
			type = "image",
			filename = planetData[i].image,
		}
		-- planet[i].fill.rotation = -45
		planet[i].fill.effect = "filter.custom.fisheye"
		planet[i].fill.effect.intensity = 25
		planet[i].rotationModifier = planetData[i].rotationModifier

		---------------------------------------------------------------

		-- Create a circle to represent the planet's gravitation.
		planet[i].gravitation = display.newCircle( groupPlanets, planetData[i].x, planetData[i].y, planetData[i].radius*2 )
		planet[i].gravitation:setFillColor( 1, 0.2 )
		physics.addBody( planet[i].gravitation, "static", { radius=planet[i].gravitation.width*0.5 } )
		planet[i].gravitation.gravity = planetData[i].radius*planetData[i].gravityModifier*globalGravityModifier
		planet[i].gravitation.type = "gravitation"
		planet[i].gravitation.id = i

		planet[i].gravitation.collision = gravityField
		planet[i].gravitation:addEventListener( "collision" )

		---------------------------------------------------------------

		-- Create a circle to represent the planet's orbit.
		planet[i].orbit = display.newCircle( groupPlanets, screen.minX, planetData[i].y, planetData[i].x-screen.minX )
		planet[i].orbit:setFillColor( 0, 0 )
		planet[i].orbit.strokeWidth = 2
		planet[i].orbit:setStrokeColor( 1, 0.2 )
	end

	display.setDefault( "textureWrapX", "clampToEdge" )
	display.setDefault( "textureWrapY", "clampToEdge" )

	---------------------------------------------------------------

	-- Create satellites.
	local satelliteData = {
		{ planet=planet[2].gravitation, startPos=80, speed=0.25 },
		{ planet=planet[3].gravitation, startPos=30, speed=0.35 },
		{ planet=planet[3].gravitation, startPos=160, speed=0.35 },
		{ planet=planet[4].gravitation, startPos=220, speed=0.25 },
	}

	for i = 1, #satelliteData do
		satellite[i] = display.newCircle( groupPlanets, satelliteData[i].planet.x, satelliteData[i].planet.y, 8 )
		satellite[i].planet = satelliteData[i].planet
		satellite[i].position = satelliteData[i].startPos
		satellite[i].speed = satelliteData[i].speed
		satellite[i].type = "satellite"

		physics.addBody( satellite[i], "static", { radius=satellite[i].width*0.5 } )
	end

	---------------------------------------------------------------

	-- Create a spacestation.
	spacestation = display.newCircle( groupPlanets, 100, screen.minY+100, 18 )
	spacestation:setFillColor( 0.2, 1 )
	physics.addBody( spacestation, "static", { radius=spacestation.width*0.5 } )
	spacestation.xBase, spacestation.yBase = spacestation.x, spacestation.y
	spacestation.position = 0
	spacestation.yOffset = 0
	spacestation.type = "spacestation"

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

	end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene