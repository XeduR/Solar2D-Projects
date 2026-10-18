-- Sky, Earth, scenery, starfield and camera zoom for both phases, plus the boat.

local world = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local sheets = require( "classes.sheets" )
local config = require( "data.world" )
local art = require( "data.art" )
local speedConfig = require( "data.speed" )
local boatModule = require( "classes.boat" )
local drawing = require( "classes.drawing" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local worldMethods = {}
worldMethods.__index = worldMethods

--------------------------------------------------------------------------------------
-- Localised functions

local approach = drawing.approach
local clamp01 = drawing.clamp01
local lerp = drawing.lerp
local newGroup = drawing.newGroup
local newPolygonAt = drawing.newPolygonAt
local randomItem = drawing.randomItem
local randomRange = drawing.randomRange
local setColour = drawing.setColour
local setPivot = drawing.setPivot
local smoothstep = drawing.smoothstep

local abs = math.abs
local asin = math.asin
local cos = math.cos
local deg = math.deg
local exp = math.exp
local floor = math.floor
local log = math.log
local max = math.max
local min = math.min
local pi = math.pi
local rad = math.rad
local random = math.random
local sin = math.sin
local sqrt = math.sqrt

--------------------------------------------------------------------------------------
-- Private functions

local function lerpLog( from, to, amount )
	return exp( lerp( log( from ), log( to ), amount ) )
end

local function addEarthPoint( vertices, rim, x, y )
	vertices[#vertices + 1] = x
	vertices[#vertices + 1] = y
	rim[#rim + 1] = x
	rim[#rim + 1] = y
end

-- Polygon and rim points relative to the circle's top point: the top arc closed off with a flat bottom, or the whole circle when it fits within halfSpan.
local function getEarthVertices( radius, halfSpan, floorDepth, segments, isFullCircle, offsetY )
	local vertices = {}
	local rim = {}

	if isFullCircle or radius <= halfSpan then
		for i = 0, segments - 1 do
			local angle = 2 * pi * i / segments
			addEarthPoint( vertices, rim, radius * sin( angle ), radius * ( 1 - cos( angle ) ) + offsetY )
		end

		rim[#rim + 1] = rim[1]
		rim[#rim + 1] = rim[2]

		return vertices, rim, true
	end

	local maxAngle = asin( halfSpan / radius )

	for i = 0, segments do
		local angle = -maxAngle + 2 * maxAngle * i / segments
		addEarthPoint( vertices, rim, radius * sin( angle ), radius * ( 1 - cos( angle ) ) + offsetY )
	end

	local floorY = max( floorDepth, radius * ( 1 - cos( maxAngle ) ) + offsetY + config.earth.edgeMargin )

	vertices[#vertices + 1] = halfSpan
	vertices[#vertices + 1] = floorY
	vertices[#vertices + 1] = -halfSpan
	vertices[#vertices + 1] = floorY

	return vertices, rim, false
end

local function clearGroup( group )
	for i = group.numChildren, 1, -1 do
		display.remove( group[i] )
	end
end

local function newSkyRect( group, top, bottom )
	local margin = config.sky.margin
	local rect = display.newRect( group, screen.centerX, screen.centerY, screen.width + margin * 2, screen.height + margin * 2 )

	rect.fill = {
		type = "gradient",
		color1 = top,
		color2 = bottom,
		direction = "down",
	}

	return rect
end

local function newSky( group )
	local settings = config.sky
	local sky = {}

	sky.calm = newSkyRect( group, settings.calmTop, settings.calmBottom )
	sky.deep = newSkyRect( group, settings.deepTop, settings.deepBottom )
	sky.deep.alpha = 0

	sky.space = display.newRect( group, screen.centerX, screen.centerY, screen.width + settings.margin * 2, screen.height + settings.margin * 2 )
	setColour( sky.space, settings.space )
	sky.space.alpha = 0

	return sky
end

local function newNebula( group )
	local settings = config.nebulae
	local scale = randomItem( settings.scales )
	local nebula = sheets.newSprite( group, config.family, settings.image, settings.tags )
	nebula:setSequence( randomItem( settings.tags ) )

	nebula.x = screen.minX + random() * screen.width
	nebula.y = screen.minY + random() * screen.height
	nebula.xScale = scale
	nebula.yScale = scale
	nebula.alpha = settings.alpha
	nebula.halfWidth = sheets.load( config.family, settings.image ).frameWidth * scale * 0.5

	return nebula
end

-- Every streak shares the long streak's canvas, so its drawn length comes from data rather than the image width.
local function newStreak( group, name, pivot )
	local streak = sheets.newImage( group, config.family, config.streakImage, name )
	setPivot( streak, config.family, config.streakImage, pivot )
	streak.baseLength = config.streakLengths[name] * art.pixelScale

	return streak
end

-- Each star carries a hidden speed streak that replaces it once the layer moves fast enough.
local function newStar( group, layer )
	local settings = config.stars
	local star = sheets.newSprite( group, config.family, settings.image, { randomItem( layer.tags ) } )

	star.x = screen.minX + random() * screen.width
	star.y = screen.minY + random() * screen.height
	star.baseAlpha = layer.alpha
	star.twinkleSpeed = randomRange( settings.twinkleSpeed )
	star.twinklePhase = random() * 2 * pi
	star.shownFrame = 1

	local streak = newStreak( group, layer.streak, settings.streakPivot )
	streak.isVisible = false
	star.streak = streak

	return star
end

local function newStarfield( group )
	local starfield = {
		group = group,
		nebulae = {},
		layers = {},
	}

	for i = 1, config.nebulae.count do
		starfield.nebulae[i] = newNebula( group )
	end

	local layers = config.stars.layers
	local halfSize = sheets.load( config.family, config.stars.image ).frameWidth * 0.5

	for i = 1, #layers do
		local stars = {}

		for index = 1, layers[i].count do
			stars[index] = newStar( group, layers[i] )
		end

		starfield.layers[i] = { settings = layers[i], stars = stars, halfSize = halfSize }
	end

	group.alpha = 0

	return starfield
end

local function newCloud( group )
	local settings = config.clouds
	local cloud = sheets.newSprite( group, config.family, settings.image, settings.sizes )
	setPivot( cloud, config.family, settings.image, settings.pivot )
	cloud.alpha = settings.alpha

	return cloud
end

local function newSpeedLine( group )
	local settings = config.speedLines

	return newStreak( group, randomItem( settings.streaks ), settings.pivot )
end

local function newWaveCrest( group )
	local settings = config.waves

	return sheets.newSprite( group, config.family, settings.image, settings.tags )
end

local function respawnCloud( cloud, x )
	local settings = config.clouds

	cloud.worldX = x
	cloud.altitude = randomRange( settings.altitude )
	cloud.parallax = randomRange( settings.parallax )
	cloud:setSequence( randomItem( settings.sizes ) )
end

local function respawnWave( wave, x )
	local settings = config.waves
	local depthLevel = random()

	wave.worldX = x
	wave.depthLevel = depthLevel
	wave.depth = lerp( settings.depth[1], settings.depth[2], depthLevel )
	wave.parallax = lerp( settings.parallaxFar, settings.parallaxNear, depthLevel )
	wave.size = lerp( settings.sizeFar, settings.sizeNear, depthLevel )
	wave.baseAlpha = randomRange( settings.alpha )
	wave:setSequence( settings.tags[min( #settings.tags, floor( depthLevel * #settings.tags ) + 1 )] )
end

function worldMethods:getSceneryScroll()
	local settings = config.scenery

	return settings.idleScroll + settings.maxScroll * self.speed ^ settings.curve
end

function worldMethods:getOceanStarLevel()
	local settings = config.stars

	return settings.oceanAlpha * self.speed ^ settings.oceanCurve
end

-- Built at scale 1 around the top point, wide and deep enough to still cover the screen when scaled down to minScale.
function worldMethods:rebuildEarth( isFullCircle )
	local earth = self.earth
	local settings = config.earth
	local margin = settings.edgeMargin
	local radius = earth.radius
	local top = earth.centreY - radius
	local reach = max( earth.centreX - ( screen.minX - margin ), screen.maxX + margin - earth.centreX )
	local halfSpan = reach / settings.minScale
	local floorDepth = max( margin, screen.maxY + margin - top ) / settings.minScale
	local segments = isFullCircle and settings.circleSegments or settings.segments
	local glowWidth = max( settings.glowMin, min( settings.glowMax, radius * settings.glowRatio ) )
	local innerWidth = glowWidth * settings.glowInnerRatio

	clearGroup( self.atmosphereLayer )
	clearGroup( self.earthLayer )

	local glowOuter = newPolygonAt( self.atmosphereLayer, ( getEarthVertices( radius + glowWidth, halfSpan, floorDepth, segments, isFullCircle, -glowWidth ) ) )
	setColour( glowOuter, settings.glowColour, settings.glowOuterAlpha )

	local glowInner = newPolygonAt( self.atmosphereLayer, ( getEarthVertices( radius + innerWidth, halfSpan, floorDepth, segments, isFullCircle, -innerWidth ) ) )
	setColour( glowInner, settings.glowColour, settings.glowInnerAlpha )

	local vertices, rimPoints, isCircleShape = getEarthVertices( radius, halfSpan, floorDepth, segments, isFullCircle, 0 )
	local ocean = newPolygonAt( self.earthLayer, vertices )
	ocean.fill = {
		type = "gradient",
		color1 = settings.oceanTop,
		color2 = settings.oceanBottom,
		direction = "down",
	}

	local rim = display.newLine( self.earthLayer, rimPoints[1], rimPoints[2], rimPoints[3], rimPoints[4] )

	for i = 5, #rimPoints, 2 do
		rim:append( rimPoints[i], rimPoints[i + 1] )
	end

	rim:setStrokeColor( settings.rimColour[1], settings.rimColour[2], settings.rimColour[3], settings.rimAlpha )

	earth.rim = rim
	earth.builtRadius = radius
	earth.halfSpan = halfSpan
	earth.floorDepth = floorDepth
	earth.isFullCircle = isFullCircle
	earth.isCircleShape = isCircleShape
end

-- A circle scaled about its top point stays a circle, so the built shape is reused until scaling would uncover part of the screen or show its straight edges.
function worldMethods:isEarthShapeValid()
	local earth = self.earth

	if not earth.builtRadius then
		return false
	end

	local settings = config.earth
	local scale = earth.radius / earth.builtRadius

	if scale > settings.maxScale then
		return false
	end

	if earth.isCircleShape then
		return true
	end

	if scale < settings.minScale then
		return false
	end

	local margin = settings.edgeMargin
	local cover = earth.halfSpan * scale
	local top = earth.centreY - earth.radius

	return earth.centreX - cover <= screen.minX - margin
		and earth.centreX + cover >= screen.maxX + margin
		and top + earth.floorDepth * scale >= screen.maxY + margin
end

function worldMethods:placeEarth()
	local earth = self.earth
	local scale = earth.radius / earth.builtRadius
	local top = earth.centreY - earth.radius
	local layers = self.earthLayers

	for i = 1, #layers do
		local layer = layers[i]

		layer.x = earth.centreX
		layer.y = top
		layer.xScale = scale
		layer.yScale = scale
	end

	earth.rim.strokeWidth = config.earth.rimWidth / scale
end

function worldMethods:setEarth( centreX, centreY, radius )
	local earth = self.earth

	earth.centreX = centreX
	earth.centreY = centreY
	earth.radius = radius
	earth.surfaceY = centreY - radius

	if not self:isEarthShapeValid() then
		self:rebuildEarth( earth.isFullCircle or false )
	end

	self:placeEarth()
end

-- Returns the sea surface y and its tangent angle in degrees at x, or nil past the Earth's edge.
function worldMethods:getSurfaceAt( x )
	local earth = self.earth
	local offset = x - earth.centreX

	if abs( offset ) >= earth.radius then
		return nil
	end

	return earth.centreY - sqrt( earth.radius * earth.radius - offset * offset ), deg( asin( offset / earth.radius ) )
end

function worldMethods:applyZoom( zoom )
	local settings = config.zoom
	local surfaceY = screen.minY + screen.height * lerp( settings.surfaceClose, settings.surfaceWide, zoom )
	local radius = lerpLog( settings.earthRadiusClose, settings.earthRadiusWide, zoom )

	self.boatScale = lerpLog( settings.boatScaleClose, settings.boatScaleWide, zoom )
	self:setEarth( self.boatX, surfaceY + radius, radius )
end

function worldMethods:updateSky( spaceLevel )
	local sky = self.sky

	sky.deep.alpha = self.speed ^ config.sky.deepCurve
	sky.space.alpha = spaceLevel
end

function worldMethods:updateStarfield( dt, scroll, alpha )
	local starfield = self.starfield
	local settings = config.stars
	local margin = settings.wrapMargin
	local time = self.time

	starfield.group.alpha = alpha

	local scrollSettings = config.scroll
	local fastLevel = clamp01( ( scroll - scrollSettings.base ) / ( scrollSettings.max - scrollSettings.base ) )

	for i = 1, #starfield.nebulae do
		local nebula = starfield.nebulae[i]

		nebula.x = nebula.x - scroll * config.nebulae.parallax * dt

		if nebula.x < screen.minX - nebula.halfWidth then
			nebula.x = screen.maxX + nebula.halfWidth
			nebula.y = screen.minY + random() * screen.height
		end
	end

	for i = 1, #starfield.layers do
		local layer = starfield.layers[i]
		local layerSpeed = scroll * lerp( layer.settings.parallax, layer.settings.parallaxFast, fastLevel )
		local streakLength = layerSpeed * settings.streakTime
		local isStreak = streakLength >= settings.streakMinLength
		local reach = margin + ( isStreak and streakLength or layer.halfSize )

		for index = 1, #layer.stars do
			local star = layer.stars[index]
			local streak = star.streak

			star.x = star.x - layerSpeed * dt

			if star.x < screen.minX - reach then
				star.x = star.x + screen.width + reach * 2
				star.y = screen.minY + random() * screen.height
			end

			-- The twinkle frame shows at the bright peak of the alpha pulse.
			local pulse = sin( time * star.twinkleSpeed + star.twinklePhase )
			local starAlpha = star.baseAlpha * ( 1 - settings.twinkleAmount * ( 0.5 + 0.5 * pulse ) )

			star.isVisible = not isStreak
			streak.isVisible = isStreak

			if isStreak then
				streak.x = star.x
				streak.y = star.y
				streak.xScale = streakLength / streak.baseLength
				streak.alpha = starAlpha

			else
				local frame = ( star.numFrames > 1 and pulse < -settings.glintLevel ) and 2 or 1

				star.alpha = starAlpha

				if frame ~= star.shownFrame then
					star.shownFrame = frame
					star:setFrame( frame )
				end
			end
		end
	end
end

function worldMethods:updateClouds( dt, scroll, alpha )
	local settings = config.clouds
	local cloudScale = lerp( 1, settings.scaleWide, self.zoom )

	self.cloudLayer.isVisible = alpha > 0
	self.cloudLayer.alpha = alpha

	for i = 1, #self.clouds do
		local cloud = self.clouds[i]

		cloud.worldX = cloud.worldX - scroll * cloud.parallax * dt

		if cloud.worldX < screen.minX - settings.halfWidth then
			respawnCloud( cloud, screen.maxX + settings.halfWidth + randomRange( settings.spawnGap ) )
		end

		local surfaceY = self:getSurfaceAt( cloud.worldX )
		cloud.isVisible = surfaceY ~= nil

		if surfaceY then
			cloud.x = cloud.worldX
			cloud.y = surfaceY - cloud.altitude * cloudScale
			cloud.xScale = cloudScale
			cloud.yScale = cloudScale
		end
	end
end

function worldMethods:respawnSpeedLine( line, x )
	local settings = config.speedLines
	local bottom = max( screen.minY + settings.skyTop, self.earth.surfaceY - settings.surfaceGap )

	line.x = x
	line.y = lerp( screen.minY + settings.skyTop, bottom, random() )
	line.speedFactor = randomRange( settings.speedFactor )
end

function worldMethods:updateSpeedLines( dt, scroll, alpha )
	local settings = config.speedLines
	local level = clamp01( ( self.speed - settings.start ) / ( 1 - settings.start ) ) * alpha

	self.speedLineLayer.isVisible = level > 0
	self.speedLineLayer.alpha = level * settings.alpha

	if level <= 0 then
		return
	end

	for i = 1, #self.speedLines do
		local line = self.speedLines[i]

		line.x = line.x - ( scroll * line.speedFactor + settings.extraSpeed ) * dt

		if line.x < screen.minX - line.baseLength then
			self:respawnSpeedLine( line, screen.maxX + line.baseLength + randomRange( settings.spawnGap ) )
		end
	end
end

function worldMethods:updateWaves( dt, scroll, alpha )
	local settings = config.waves
	local margin = settings.wrapMargin
	local zoomScale = lerp( 1, settings.scaleWide, self.zoom )
	local stretch = 1 + settings.stretch * self.speed

	self.waveLayer.isVisible = alpha > 0
	self.waveLayer.alpha = alpha

	for i = 1, #self.waves do
		local wave = self.waves[i]

		wave.worldX = wave.worldX - scroll * wave.parallax * dt

		if wave.worldX < screen.minX - margin then
			respawnWave( wave, screen.maxX + margin + randomRange( settings.spawnGap ) )
		end

		local surfaceY, angle = self:getSurfaceAt( wave.worldX )
		wave.isVisible = surfaceY ~= nil

		if surfaceY then
			local radians = rad( angle )
			local depth = wave.depth * zoomScale

			wave.x = wave.worldX - sin( radians ) * depth
			wave.y = surfaceY + cos( radians ) * depth
			wave.rotation = angle
			wave.xScale = wave.size * zoomScale * stretch
			wave.yScale = wave.size * zoomScale
			wave.alpha = wave.baseAlpha
		end
	end
end

function worldMethods:updateOcean( dt, speedTarget, fireLevel )
	local settings = config.zoom

	self.zoom = approach( self.zoom, speedTarget ^ settings.curve, settings.response, dt )
	self:applyZoom( self.zoom )

	local scroll = self:getSceneryScroll()

	self:updateSky( 0 )
	self:updateStarfield( dt, 0, self:getOceanStarLevel() )
	self:updateSpeedLines( dt, scroll, 1 )
	self:updateClouds( dt, scroll, 1 )
	self:updateWaves( dt, scroll, 1 )

	self.boat:float( self.boatX, self.earth.surfaceY, self.boatScale, self.speed )
	self.boat:update( dt, self.speed, fireLevel, scroll, 1, 0 )
end

function worldMethods:finishLaunch()
	self.state = "space"
	self.isLaunchFinished = true

	self.atmosphereLayer.isVisible = false
	self.earthLayer.isVisible = false
	self.waveLayer.isVisible = false
	self.cloudLayer.isVisible = false
	self.speedLineLayer.isVisible = false

	local _, boatY = self.boat:getPosition()
	self.boat:setPose( self.spaceX, boatY, config.layout.cometScale, 0 )
	self.boat:setMode( "space" )
end

function worldMethods:updateLaunch( dt, fireLevel )
	local settings = config.launch
	local start = self.launchStart

	self.launchTime = self.launchTime + dt

	local progress = clamp01( self.launchTime / settings.duration )
	local eased = smoothstep( progress )
	local fall = progress * progress

	-- The boat flies straight on at its own height while the Earth slides away behind it, so the surface curves down and out from under the hull.
	local x = lerp( start.x, self.spaceX, eased )
	local y = start.y + settings.sag * fall
	local scale = lerpLog( start.scale, config.layout.cometScale, eased )

	self.boat:setPose( x, y, scale, lerp( start.rotation, 0, eased ) )

	-- The centre sits below the screen, so the disc stops touching the screen well before its full width has crossed the left edge.
	local reach = start.radius + config.earth.glowMax
	local below = max( 0, start.earthY - screen.maxY )
	local earthEndX = screen.minX - sqrt( max( 0, reach * reach - below * below ) ) - settings.earthExitMargin

	self:setEarth( lerp( start.earthX, earthEndX, eased ), start.earthY, start.radius )

	local spaceLevel = smoothstep( progress / settings.skyFadeEnd )
	local starLevel = max( self:getOceanStarLevel(), smoothstep( ( progress - settings.starStart ) / settings.starFade ) )
	local waterLevel = 1 - smoothstep( progress / settings.waterFadeEnd )
	local cometLevel = smoothstep( ( progress - settings.cometStart ) / settings.cometFade )
	local scroll = lerp( start.scroll, self:getScrollSpeed(), eased )

	self:updateSky( spaceLevel )
	self:updateStarfield( dt, scroll * cometLevel, starLevel )
	self:updateSpeedLines( dt, scroll, waterLevel )
	self:updateClouds( dt, scroll, waterLevel )
	self:updateWaves( dt, scroll, waterLevel )

	self.boat:update( dt, self.speed, fireLevel, scroll, waterLevel, cometLevel )

	if progress >= 1 then
		self:finishLaunch()
	end
end

function worldMethods:updateSpace( dt, fireLevel )
	local scroll = self:getScrollSpeed()

	self:updateSky( 1 )
	self:updateStarfield( dt, scroll, 1 )
	self.boat:update( dt, self.speed, fireLevel, scroll, 0, 1 )
end

--------------------------------------------------------------------------------------
-- Public functions

function world.new( parentGroup )
	local self = setmetatable( {}, worldMethods )

	self.parent = parentGroup
	self.state = "ocean"
	self.time = 0
	self.knots = 0
	self.speed = 0
	self.zoom = 0
	self.launchTime = 0
	self.isLaunchFinished = false
	self.boatX = screen.minX + screen.width * config.layout.boatX
	self.spaceX = screen.minX + config.layout.spaceOffsetX
	self.earth = {}

	self.sky = newSky( newGroup( parentGroup ) )
	self.starfield = newStarfield( newGroup( parentGroup ) )
	self.speedLineLayer = newGroup( parentGroup )
	self.cloudLayer = newGroup( parentGroup )
	self.atmosphereLayer = newGroup( parentGroup )
	self.obstacleLayer = newGroup( parentGroup )

	local boatBackLayer = newGroup( parentGroup )
	local boatLayer = newGroup( parentGroup )

	-- The sea is drawn over the boat so the hull and paddle wheel sink below the waterline.
	self.earthLayer = newGroup( parentGroup )
	self.earthLayers = { self.atmosphereLayer, self.earthLayer }
	self.waveLayer = newGroup( parentGroup )
	local boatFrontLayer = newGroup( parentGroup )

	self.speedLines = {}

	for i = 1, config.speedLines.count do
		self.speedLines[i] = newSpeedLine( self.speedLineLayer )
	end

	self.clouds = {}

	for i = 1, config.clouds.count do
		local cloud = newCloud( self.cloudLayer )

		respawnCloud( cloud, screen.minX + random() * ( screen.width + config.clouds.halfWidth * 2 ) )
		self.clouds[i] = cloud
	end

	self.waves = {}

	for i = 1, config.waves.count do
		local wave = newWaveCrest( self.waveLayer )

		respawnWave( wave, screen.minX + random() * screen.width )
		self.waves[i] = wave
	end

	self.boat = boatModule.new( {
		back = boatBackLayer,
		body = boatLayer,
		front = boatFrontLayer,
	} )

	self:applyZoom( 0 )

	for i = 1, #self.speedLines do
		self:respawnSpeedLine( self.speedLines[i], screen.minX + random() * screen.width )
	end

	self:update( 0, 0, 0 )

	return self
end

function worldMethods:getBoat()
	return self.boat
end

function worldMethods:getObstacleLayer()
	return self.obstacleLayer
end

function worldMethods:isLaunchDone()
	return self.isLaunchFinished
end

-- Grows with the logarithm of the knots above escape speed, so huge speeds stay playable, and drops below base when the knots fall under escape speed.
function worldMethods:getScrollSpeed()
	local settings = config.scroll
	local ratio = max( 0, self.knots ) / speedConfig.escapeKnots
	local factor

	if ratio >= 1 then
		factor = ( 1 + log( ratio ) ) ^ settings.curve
	else
		factor = ratio ^ settings.slowCurve
	end

	return max( settings.min, min( settings.max, settings.base * factor ) )
end

function worldMethods:startLaunch()
	if self.state ~= "ocean" then
		return
	end

	local boatX, boatY = self.boat:getPosition()
	local earth = self.earth

	self.state = "launch"
	self.launchTime = 0
	self.launchStart = {
		x = boatX,
		y = boatY,
		rotation = self.boat.rotation,
		scale = self.boatScale,
		scroll = self:getSceneryScroll(),
		earthX = earth.centreX,
		earthY = earth.centreY,
		radius = earth.radius,
	}

	-- The whole Earth slides off screen during the launch, so build it once as a full circle and only move it.
	self:rebuildEarth( true )
	self:placeEarth()

	self.boat:setMode( "launch" )
end

function worldMethods:update( dt, knots, fireLevel )
	self.time = self.time + dt
	self.knots = knots

	local speedTarget = clamp01( log( 1 + max( 0, knots ) ) / log( 1 + speedConfig.escapeKnots ) )
	self.speed = approach( self.speed, speedTarget, config.speedResponse, dt )

	if self.state == "ocean" then
		self:updateOcean( dt, speedTarget, fireLevel )

	elseif self.state == "launch" then
		self:updateLaunch( dt, fireLevel )

	else
		self:updateSpace( dt, fireLevel )
	end
end

return world
