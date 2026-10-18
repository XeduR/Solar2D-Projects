-- Phase 2 planets and asteroids: spawning, scrolling, and collision.

local obstacles = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local sheets = require( "classes.sheets" )
local drawing = require( "classes.drawing" )
local sound = require( "classes.sound" )
local config = require( "data.obstacles" )
local boatConfig = require( "data.boat" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local fieldMethods = {}
fieldMethods.__index = fieldMethods

--------------------------------------------------------------------------------------
-- Localised functions

local random = math.random
local sqrt = math.sqrt
local sin = math.sin
local log10 = math.log10
local min = math.min
local max = math.max
local abs = math.abs

-- A reversed range means the gap needs more room than the screen has, so clamp centres it.
local clamp = drawing.clamp
local randomBetween = drawing.randomBetween
local randomItem = drawing.randomItem

--------------------------------------------------------------------------------------
-- Private functions

-- scale multiplies the art scale that sheets.newImage already sets.
local function newArt( group, name, tag, x, y, scale )
	local image = sheets.newImage( group, config.family, name, tag )

	image.x = x
	image.y = y
	image.xScale = image.xScale * scale
	image.yScale = image.yScale * scale

	return image
end

local function newPlanetGlow( group, radius, scheme )
	local style = config.planet
	local glow = display.newCircle( group, 0, 0, radius * style.glowScale )

	glow:setFillColor( scheme.glow[1], scheme.glow[2], scheme.glow[3], style.glowAlpha )

	return glow
end

local function newPlanetMoustache( group, radius, scale )
	local face = config.planet.face
	local moustache = display.newGroup()
	group:insert( moustache )

	moustache.y = radius * face.moustacheOffsetY

	newArt( moustache, face.moustacheImage, face.moustacheTags[1], 0, 0, scale )
	newArt( moustache, face.moustacheImage, face.moustacheTags[2], 0, 0, scale )

	return moustache
end

-- The eye whites and mouth are part of the silly planet frame; only the pupils and moustache move.
local function newPlanetFace( group, radius, scale )
	local face = config.planet.face
	local eyeX = radius * face.eyeOffsetX
	local eyeY = -radius * face.eyeOffsetY
	local pupils = {}

	for i = 1, 2 do
		-- -1 for the left eye, 1 for the right.
		local side = i * 2 - 3
		local pupil = newArt( group, face.pupilImage, nil, eyeX * side, eyeY, scale )

		pupil.homeX = eyeX * side
		pupil.homeY = eyeY
		pupils[#pupils + 1] = pupil
	end

	local moustache = newPlanetMoustache( group, radius, scale )

	return { pupils = pupils, moustache = moustache, radius = radius, time = 0 }
end

local function newPlanet( parentGroup, x, y, radius )
	local style = config.planet
	local group = display.newGroup()
	parentGroup:insert( group )

	group.x = x
	group.y = y

	local isSilly = random() < style.sillyChance
	local scheme = isSilly and style.sillyScheme or randomItem( style.schemes )
	local hasRing = not isSilly and random() < style.ringChance
	local scale = radius / style.artRadius
	local obstacle = { kind = "planet", group = group, radius = radius, hitRadius = radius * style.hitScale, extent = radius }

	newPlanetGlow( group, radius, scheme )

	local look = ""

	if not isSilly then
		if random() < style.bandChance then
			look = style.bandsSuffix

		elseif random() < style.craterChance then
			look = style.cratersSuffix
		end
	end

	if hasRing then
		newArt( group, style.ringedImage, scheme.tag .. look, 0, 0, scale )
		obstacle.extent = radius * style.ringOuterScale

	else
		newArt( group, style.image, scheme.tag .. look, 0, 0, scale )
	end

	if isSilly then
		obstacle.face = newPlanetFace( group, radius, scale )
	end

	return obstacle
end

local function newAsteroidRock( group, radius )
	local variants = config.asteroid.variants
	local nearest = variants[1]

	for i = 2, #variants do
		if abs( variants[i].radius - radius ) < abs( nearest.radius - radius ) then
			nearest = variants[i]
		end
	end

	return newArt( group, config.asteroid.image, nearest.tag, 0, 0, radius / nearest.radius )
end

local function newAsteroid( parentGroup, x, y, radius )
	local style = config.asteroid
	local group = display.newGroup()
	parentGroup:insert( group )

	group.x = x
	group.y = y
	group.rotation = randomBetween( 0, 360 )

	newAsteroidRock( group, radius )

	return {
		kind = "asteroid",
		group = group,
		radius = radius,
		hitRadius = radius * style.hitScale,
		extent = radius,
		spinSpeed = randomBetween( style.spinMin, style.spinMax ) * ( random() < 0.5 and -1 or 1 ),
	}
end

-- Every wave obstacle stays fully outside the gap between gapTop and gapBottom.

function fieldMethods:addObstacle( obstacle, wave )
	self.items[#self.items + 1] = obstacle
	wave.right = max( wave.right, obstacle.group.x + obstacle.extent )
end

function fieldMethods:addPlanet( wave, side )
	local style = config.planet
	local radius = randomBetween( style.radiusMin, style.radiusMax )
	local slack = randomBetween( 0, style.gapSlack )
	local y

	if side < 0 then
		y = wave.gapTop - radius - slack

	else
		y = wave.gapBottom + radius + slack
	end

	self:addObstacle( newPlanet( self.group, wave.left + radius, y, radius ), wave )
end

function fieldMethods:addBelt( wave, side )
	local style = config.asteroid
	local limit = side < 0 and screen.minY - style.beltEdgeOverhang or screen.maxY + style.beltEdgeOverhang
	local edge = side < 0 and wave.gapTop or wave.gapBottom
	local radius = randomBetween( style.radiusMin, style.radiusMax )
	local y = edge + side * ( radius + randomBetween( 0, style.beltStepMin * style.beltFirstJitter ) )

	while ( side < 0 and y > limit ) or ( side > 0 and y < limit ) do
		local x = wave.left + style.radiusMax + randomBetween( 0, style.beltJitterX )

		self:addObstacle( newAsteroid( self.group, x, y, radius ), wave )

		radius = randomBetween( style.radiusMin, style.radiusMax )
		y = y + side * randomBetween( style.beltStepMin, style.beltStepMax )
	end
end

function fieldMethods:addCluster( wave, side )
	local style = config.asteroid
	local low = side < 0 and screen.minY or wave.gapBottom
	local high = side < 0 and wave.gapTop or screen.maxY
	local centreY = randomBetween( low, high )
	local count = random( style.clusterCountMin, style.clusterCountMax )

	for _ = 1, count do
		local radius = randomBetween( style.radiusMin, style.radiusMax )
		local x = wave.left + radius + randomBetween( 0, style.clusterSpreadX )
		local y = centreY + randomBetween( -0.5, 0.5 ) * style.clusterSpreadY

		if side < 0 then
			y = min( y, wave.gapTop - radius )

		else
			y = max( y, wave.gapBottom + radius )
		end

		self:addObstacle( newAsteroid( self.group, x, y, radius ), wave )
	end
end

local patternBuilders = {
	planet = function( field, wave, side )
		field:addPlanet( wave, side )
	end,

	belt = function( field, wave )
		field:addBelt( wave, -1 )
		field:addBelt( wave, 1 )
	end,

	cluster = function( field, wave, side )
		field:addCluster( wave, side )

		if random() < config.asteroid.clusterMirrorChance then
			field:addCluster( wave, -side )
		end
	end,

	planetPair = function( field, wave )
		field:addPlanet( wave, -1 )
		field:addPlanet( wave, 1 )
	end,

	planetBelt = function( field, wave, side )
		field:addPlanet( wave, side )
		field:addBelt( wave, -side )
	end,
}

local function choosePattern( level )
	local total = 0

	for i = 1, #config.patterns do
		local pattern = config.patterns[i]

		if level >= pattern.minLevel then
			total = total + pattern.weight
		end
	end

	local roll = random() * total

	for i = 1, #config.patterns do
		local pattern = config.patterns[i]

		if level >= pattern.minLevel then
			roll = roll - pattern.weight

			if roll <= 0 then
				return pattern.name
			end
		end
	end

	return config.patterns[1].name
end

-- Fastest stop-to-stop vertical move of the boat: accelerate, cruise at top speed if reached, brake.
local function verticalTravelTime( distance )
	local space = boatConfig.space
	local acceleration = min( space.thrust, space.gravity )
	local topSpeed = space.maxSpeed
	local rampDistance = topSpeed * topSpeed / acceleration

	if distance <= rampDistance then
		return 2 * sqrt( distance / acceleration )
	end

	return 2 * topSpeed / acceleration + ( distance - rampDistance ) / topSpeed
end

local function shiftTime( distance )
	return ( config.reactionTime + verticalTravelTime( distance ) ) * config.shiftTimeSafety
end

--------------------------------------------------------------------------------------
-- Public functions

function obstacles.new( parentGroup )
	local field = setmetatable( {}, fieldMethods )

	field.group = display.newGroup()
	parentGroup:insert( field.group )

	field.items = {}
	field.waves = {}
	field.isActive = false
	field.lastWaveRight = 0
	field.lastGapY = nil

	return field
end

function fieldMethods:setActive( isActive )
	if isActive and not self.isActive then
		self.lastWaveRight = screen.maxX + config.firstWaveDistance
		self.lastGapY = nil
	end

	self.isActive = isActive
end

function fieldMethods:getDifficulty( knots )
	local level = log10( max( knots or 0, 1 ) )
	local progress = ( level - config.levelStart ) / ( config.levelEnd - config.levelStart )

	return level, min( 1, max( 0, progress ) )
end

function fieldMethods:getSpacing( knots )
	local _, progress = self:getDifficulty( knots )

	return config.spacingEasy + ( config.spacingHard - config.spacingEasy ) * progress
end

function fieldMethods:spawnWave( scrollSpeed, knots )
	local level, progress = self:getDifficulty( knots )
	local gapHeight = config.gapEasy + ( config.gapHard - config.gapEasy ) * progress
	local maxShift = config.maxShiftEasy + ( config.maxShiftHard - config.maxShiftEasy ) * progress
	local halfGap = gapHeight * 0.5

	-- Touching the top or bottom edge kills the boat, so gaps keep a boat diameter plus a margin clear of both.
	local edgeClearance = boatConfig.collisionRadius * 2 + config.gapEdgeMargin + halfGap
	local lowY = screen.minY + edgeClearance
	local highY = screen.maxY - edgeClearance

	local gapY, distance

	if self.lastGapY then
		gapY = clamp( randomBetween( self.lastGapY - maxShift, self.lastGapY + maxShift ), lowY, highY )
		distance = abs( gapY - self.lastGapY )

	else
		-- The boat may be anywhere when obstacles start, so allow for the longest move to the first gap.
		gapY = clamp( randomBetween( lowY, highY ), lowY, highY )

		local boatRadius = boatConfig.collisionRadius
		distance = max( gapY - ( screen.minY + boatRadius ), screen.maxY - boatRadius - gapY )
	end

	-- Clearance is set in time, so faster scrolling stretches it in content units and the boat always has time to move.
	local clearance = max( self:getSpacing( knots ), shiftTime( distance ) * max( scrollSpeed, 0 ) )
	local left = self.lastWaveRight + clearance

	local wave = {
		left = left,
		right = left,
		gapY = gapY,
		gapTop = gapY - halfGap,
		gapBottom = gapY + halfGap,
	}

	local side = random() < 0.5 and -1 or 1
	patternBuilders[choosePattern( level )]( self, wave, side )

	self.waves[#self.waves + 1] = wave
	self.lastGapY = gapY
	self.lastWaveRight = wave.right
end

function fieldMethods:update( dt, scrollSpeed, knots )
	local shift = ( scrollSpeed or 0 ) * dt
	local leftLimit = screen.minX - config.removeMargin

	self.lastWaveRight = self.lastWaveRight - shift

	if self.isActive and self.lastWaveRight + self:getSpacing( knots ) <= screen.maxX + config.spawnLead then
		self:spawnWave( scrollSpeed or 0, knots )
	end

	for i = #self.waves, 1, -1 do
		local wave = self.waves[i]

		wave.left = wave.left - shift
		wave.right = wave.right - shift

		if wave.right < leftLimit then
			table.remove( self.waves, i )
		end
	end

	for i = #self.items, 1, -1 do
		local obstacle = self.items[i]
		local group = obstacle.group

		group.x = group.x - shift

		if group.x + obstacle.extent < leftLimit then
			display.remove( group )
			table.remove( self.items, i )

		else
			if obstacle.spinSpeed then
				group.rotation = group.rotation + obstacle.spinSpeed * dt
			end

			if obstacle.face then
				self:updateFace( obstacle.face, dt )
			end
		end
	end
end

function fieldMethods:updateFace( face, dt )
	local style = config.planet.face

	face.time = face.time + dt

	local reach = face.radius * style.pupilReach
	local glance = sin( face.time * style.pupilWobbleSpeed )

	for i = 1, #face.pupils do
		local pupil = face.pupils[i]

		pupil.x = pupil.homeX - reach * ( style.pupilGlanceBase + style.pupilGlanceSwing * glance )
		pupil.y = pupil.homeY + reach * style.pupilGlanceVertical * glance
	end

	face.moustache.rotation = sin( face.time * style.moustacheTwirlSpeed ) * style.moustacheTwirlAngle
end

-- Tracks each obstacle's closest gap to the boat and plays the near-miss whoosh once it has passed without a hit.
function fieldMethods:trackNearMiss( obstacle, x, radius, distance )
	if obstacle.isPassed then
		return
	end

	local gap = distance - obstacle.hitRadius - radius
	obstacle.closestGap = min( obstacle.closestGap or gap, gap )

	if obstacle.group.x + obstacle.hitRadius < x - radius then
		obstacle.isPassed = true

		if self.isActive and obstacle.closestGap <= config.nearMissDistance then
			sound.play( "whoosh" )
		end
	end
end

function fieldMethods:checkCollision( x, y, radius )
	local hitX, hitY, hitKind

	-- No early return on a hit: every obstacle hit this frame must be marked passed, so none of them whooshes later.
	for i = 1, #self.items do
		local obstacle = self.items[i]
		local offsetX = x - obstacle.group.x
		local offsetY = y - obstacle.group.y
		local reach = obstacle.hitRadius + radius
		local distanceSquared = offsetX * offsetX + offsetY * offsetY
		local distance = sqrt( distanceSquared )

		obstacle.boatDistance = distance

		if distanceSquared < reach * reach then
			obstacle.isPassed = true

			if not hitX then
				hitKind = obstacle.kind

				if distance == 0 then
					hitX, hitY = obstacle.group.x, obstacle.group.y
				else
					local scale = obstacle.hitRadius / distance
					hitX, hitY = obstacle.group.x + offsetX * scale, obstacle.group.y + offsetY * scale
				end
			end
		end
	end

	-- No near misses on a crash frame, so no whoosh plays over the crash.
	if hitX then
		return hitX, hitY, hitKind
	end

	for i = 1, #self.items do
		local obstacle = self.items[i]

		self:trackNearMiss( obstacle, x, radius, obstacle.boatDistance )
	end
end

return obstacles
