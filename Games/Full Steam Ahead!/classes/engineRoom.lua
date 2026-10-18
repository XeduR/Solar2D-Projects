-- Engine room porthole in the bottom-left screen corner: furnace, flames, coal and the stoker's shovel.

local engineRoom = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local config = require( "data.engineRoom" )
local pixelScale = require( "data.art" ).pixelScale
local palette = require( "data.palette" )
local screen = require( "classes.screen" )
local sheets = require( "classes.sheets" )
local drawing = require( "classes.drawing" )
local textBlock = require( "classes.textBlock" )
local sound = require( "classes.sound" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

-- Contents may tuck under the rim up to its middle, where they stay hidden.
local hiddenRadius = config.radius - config.rim.width * 0.5

local roomMethods = {}
roomMethods.__index = roomMethods

--------------------------------------------------------------------------------------
-- Localised functions

local abs = math.abs
local ceil = math.ceil
local cos = math.cos
local sin = math.sin
local exp = math.exp
local min = math.min
local max = math.max
local rad = math.rad
local sqrt = math.sqrt
local pi = math.pi

local clamp = drawing.clamp
local clamp01 = drawing.clamp01
local lerp = drawing.lerp
local smoothstep = drawing.smoothstep
local newPolygonAt = drawing.newPolygonAt
local randomBetween = drawing.randomBetween
local setColour = drawing.setColour

--------------------------------------------------------------------------------------
-- Private functions

-- Closes rate * dt of the remaining gap, capped at the whole gap so a long frame lands on the target instead of overshooting it.
local function approachLinear( current, target, rate, dt )
	return current + ( target - current ) * min( 1, rate * dt )
end

local function moveToward( current, target, step )
	if current < target then
		return min( target, current + step )
	end

	return max( target, current - step )
end

local function noise( phase )
	local noiseConfig = config.noise
	local weight = noiseConfig.secondWeight

	return sin( phase ) * ( 1 - weight ) + sin( phase * noiseConfig.secondFrequency ) * weight
end

local function setLerpColor( object, from, to, amount )
	object:setFillColor( lerp( from[1], to[1], amount ), lerp( from[2], to[2], amount ), lerp( from[3], to[3], amount ) )
end

-- Angles run counter-clockwise from +x, so 90 degrees points up the screen.
local function appendArc( points, centerX, centerY, radius, fromDegrees, toDegrees )
	local steps = max( 1, ceil( abs( toDegrees - fromDegrees ) / config.arcStepDegrees ) )

	for i = 0, steps do
		local angle = rad( lerp( fromDegrees, toDegrees, i / steps ) )
		points[#points + 1] = centerX + radius * cos( angle )
		points[#points + 1] = centerY - radius * sin( angle )
	end

	return points
end

local function isInside( x, y, radius )
	return x * x + y * y < radius * radius
end

local function newPlacedImage( group, placement )
	local image = sheets.newImage( group, config.families.room, placement.name )
	image.anchorX = 0
	image.anchorY = 0
	image.x = placement.x
	image.y = placement.y

	return image
end

local function newGaugeNeedle( group )
	local gaugeConfig = config.gauge
	local needle = sheets.newImage( group, config.families.room, gaugeConfig.sheet )
	needle.x = gaugeConfig.x
	needle.y = gaugeConfig.y

	return needle
end

local function newEmbers( group )
	local emberConfig = config.embers
	local mouth = config.furnace.mouth
	local family = config.families.effects
	local tag = sheets.load( family, emberConfig.sheet ).tags[emberConfig.tag]
	local embers = {}

	for i = 1, emberConfig.count do
		local offset = lerp( -emberConfig.spread, emberConfig.spread, ( i - 1 ) / max( 1, emberConfig.count - 1 ) )
		local object = sheets.newImage( group, family, emberConfig.sheet, tag.frames[( i - 1 ) % #tag.frames + 1] )
		object.x = mouth.centerX + offset
		object.y = emberConfig.y
		embers[i] = { object = object, phase = randomBetween( 0, 2 * pi ) }
	end

	return embers
end

local function newFurnaceFlames( group )
	local flameConfig = config.flames
	local family = config.families.effects
	local sprite = sheets.newSprite( group, family, flameConfig.sheet )

	sprite.anchorX = flameConfig.anchorX
	sprite.anchorY = flameConfig.anchorY
	sprite.x = config.furnace.mouth.centerX
	sprite.y = flameConfig.baseY
	sprite.isVisible = false

	return drawing.newAnimation( sprite, family, flameConfig.sheet, flameConfig.tiers[1].tag )
end

local function newHalo( group )
	local haloConfig = config.halo
	local mouth = config.furnace.mouth
	local halo = {}

	for i = 1, #haloConfig.radii do
		local circle = display.newCircle( group, mouth.centerX, mouth.targetY, haloConfig.radii[i] )
		setColour( circle, haloConfig.color )
		circle.blendMode = "add"
		circle.alpha = 0
		halo[i] = circle
	end

	return halo
end

local function newSparks( group )
	local sparkConfig = config.sparks
	local family = config.families.effects
	local tag = sheets.load( family, sparkConfig.sheet ).tags[sparkConfig.tag]
	local sparks = {}

	for i = 1, sparkConfig.poolSize do
		local object = sheets.newImage( group, family, sparkConfig.sheet, tag.frames[( i - 1 ) % #tag.frames + 1] )
		object.isVisible = false
		sparks[i] = { object = object, isActive = false }
	end

	return sparks
end

-- The pool cycles through every chunk size in the sheet.
local function newCoalChunks( group )
	local coalConfig = config.coal
	local family = config.families.room
	local frameCount = sheets.load( family, coalConfig.sheet ).frameCount
	local chunks = {}

	for i = 1, coalConfig.poolSize do
		local object = sheets.newImage( group, family, coalConfig.sheet, ( i - 1 ) % frameCount + 1 )
		object.isVisible = false
		chunks[i] = { object = object, isActive = false }
	end

	return chunks
end

local function newFlares( group )
	local flareConfig = config.flare
	local flares = {}

	for i = 1, flareConfig.poolSize do
		local object = display.newCircle( group, 0, 0, flareConfig.radius )
		setColour( object, flareConfig.color )
		object.blendMode = "add"
		object.isVisible = false
		flares[i] = { object = object, isActive = false }
	end

	return flares
end

-- The anchor is the stoker's hands; the blade hangs bladeDistance below it at rotation 0.
local function newShovel( group )
	local shovelConfig = config.shovel
	local sprite = sheets.newSprite( group, config.families.room, shovelConfig.sheet, { shovelConfig.emptyTag, shovelConfig.loadedTag } )
	sprite.anchorX = shovelConfig.anchorX
	sprite.anchorY = shovelConfig.anchorY

	return sprite
end

local function newWarmGlow( group )
	local glowConfig = config.glow
	local glow = newPolygonAt( group, appendArc( { 0, 0 }, 0, 0, hiddenRadius, 0, 90 ) )
	setColour( glow, glowConfig.color )
	glow.blendMode = "add"
	glow.alpha = 0

	return glow
end

local function snapToPixels( size )
	return ceil( size / pixelScale ) * pixelScale
end

local function newTooltip( group )
	local tooltipConfig = config.tooltip
	local tooltip = display.newGroup()
	group:insert( tooltip )

	local label = textBlock.new( {
		parent = tooltip,
		text = tooltipConfig.text,
		width = tooltipConfig.wrapWidth,
		font = tooltipConfig.font,
		fontSize = tooltipConfig.fontSize,
		align = "center",
		colour = palette.textLight,
	} )

	local plateWidth = snapToPixels( label.blockWidth + tooltipConfig.paddingX * 2 )
	local plateHeight = snapToPixels( label.blockHeight + tooltipConfig.paddingY * 2 )
	local plate = sheets.newNineSlice( tooltip, config.families.room, tooltipConfig.plateImage, plateWidth, plateHeight )
	plate.alpha = tooltipConfig.plateAlpha
	plate:toBack()

	tooltip.x = config.radius + tooltipConfig.rimGap + plateWidth * 0.5
	tooltip.y = -( tooltipConfig.bottomMargin + plateHeight * 0.5 )

	tooltip.alpha = 0
	tooltip.isVisible = false

	return tooltip
end

-- Drawn above the rim: these are the only shapes that leave the circle.
local function newBurstFlames( group )
	local burstConfig = config.burst
	local mouth = config.furnace.mouth
	local family = config.families.effects
	local tongues = {}

	for i = 1, #burstConfig.tongues do
		local tongueConfig = burstConfig.tongues[i]
		local sprite = sheets.newSprite( group, family, burstConfig.sheet )

		sprite.anchorX = burstConfig.anchorX
		sprite.anchorY = burstConfig.anchorY
		sprite.x = mouth.centerX
		sprite.y = mouth.targetY
		sprite.isVisible = false

		tongues[i] = {
			animation = drawing.newAnimation( sprite, family, burstConfig.sheet, burstConfig.tag, tongueConfig.startFrame ),
			config = tongueConfig,
			rotation = burstConfig.drawnAngle - tongueConfig.angle,
			phase = randomBetween( 0, 2 * pi ),
		}
	end

	return tongues
end

-- The first segment starts from wherever the shovel is, so a restart never jumps.
local function samplePose( poses, startPose, progress )
	local previous = startPose
	local previousTime = 0

	for i = 1, #poses do
		local pose = poses[i]

		if progress <= pose.time then
			local eased = smoothstep( ( progress - previousTime ) / ( pose.time - previousTime ) )
			return lerp( previous.x, pose.x, eased ), lerp( previous.y, pose.y, eased ), lerp( previous.rotation, pose.rotation, eased )
		end

		previous = pose
		previousTime = pose.time
	end

	return previous.x, previous.y, previous.rotation
end

function roomMethods:placeShovel( x, y, rotation )
	local shovel = self.shovelSprite
	shovel.x = x
	shovel.y = y
	shovel.rotation = rotation

	self.shovelX = x
	self.shovelY = y
	self.shovelRotation = rotation
end

function roomMethods:setShovelLoaded( isLoaded )
	local shovelConfig = config.shovel
	self.shovelSprite:setSequence( isLoaded and shovelConfig.loadedTag or shovelConfig.emptyTag )
end

function roomMethods:getBladePosition()
	local distance = config.shovel.bladeDistance
	local angle = rad( self.shovelRotation )

	return self.shovelX - distance * sin( angle ), self.shovelY + distance * cos( angle )
end

function roomMethods:startSwing()
	local motion = self.motion
	local startPose = motion.startPose

	startPose.x = self.shovelX
	startPose.y = self.shovelY
	startPose.rotation = self.shovelRotation

	motion.isActive = true
	motion.progress = 0
	motion.isLoaded = false
	motion.hasReleased = false
	motion.extraChunks = 0
	self:setShovelLoaded( false )
end

function roomMethods:updateShovel( dt )
	local shovelConfig = config.shovel
	local motion = self.motion
	local speed = min( shovelConfig.maxSpeed, 1 + self.heat * shovelConfig.speedPerHeat )
	self.heat = self.heat * exp( -shovelConfig.heatDecay * dt )

	if not motion.isActive then
		local rest = shovelConfig.restPose
		local bob = sin( motion.idleTime * shovelConfig.idleSpeed )
		motion.idleTime = motion.idleTime + dt
		self:placeShovel( rest.x, rest.y - shovelConfig.idleBob * bob, rest.rotation + shovelConfig.idleTilt * bob )
		return
	end

	motion.progress = min( 1, motion.progress + dt * speed / shovelConfig.cycleDuration )
	self:placeShovel( samplePose( shovelConfig.poses, motion.startPose, motion.progress ) )

	if not motion.isLoaded and not motion.hasReleased and motion.progress >= shovelConfig.loadTime then
		motion.isLoaded = true
		self:setShovelLoaded( true )
	end

	if not motion.hasReleased and motion.progress >= shovelConfig.releaseTime then
		local bladeX, bladeY = self:getBladePosition()
		motion.hasReleased = true
		motion.isLoaded = false
		self:setShovelLoaded( false )
		self:throwCoal( bladeX, bladeY, 1 + motion.extraChunks, speed )
		motion.extraChunks = 0
	end

	if motion.progress >= 1 then
		motion.isActive = false
		motion.idleTime = 0
	end
end

function roomMethods:updateFired( dt )
	local firedConfig = config.fired
	local fall = self.fall

	self.firedTime = self.firedTime + dt
	self.dim = max( firedConfig.dimFloor, 1 - ( 1 - firedConfig.dimFloor ) * self.firedTime / firedConfig.dimTime )

	if not fall.isSettled then
		fall.velocityY = fall.velocityY + firedConfig.gravity * dt
		fall.y = fall.y + fall.velocityY * dt
		fall.x = approachLinear( fall.x, firedConfig.lyingX, firedConfig.slide, dt )

		if fall.y >= firedConfig.restY and fall.velocityY > 0 then
			fall.y = firedConfig.restY

			if fall.bounces < firedConfig.maxBounces then
				fall.bounces = fall.bounces + 1
				fall.velocityY = -fall.velocityY * firedConfig.restitution
				fall.wobble = firedConfig.bounceWobble / fall.bounces
				self:clatter()
			else
				fall.velocityY = 0
				fall.isSettled = true
			end
		end
	end

	fall.wobble = fall.wobble * exp( -firedConfig.wobbleDecay * dt )
	fall.wobblePhase = fall.wobblePhase + dt * firedConfig.wobbleSpeed
	fall.rotation = approachLinear( fall.rotation, firedConfig.lyingRotation, firedConfig.spin, dt )
	self:placeShovel( fall.x, fall.y, fall.rotation + fall.wobble * sin( fall.wobblePhase ) )

	if fall.isSettled and self.firedTime >= firedConfig.completeDelay and self.firedCallback then
		self.isCompletePending = true
	end
end

function roomMethods:clatter()
	local sparkConfig = config.sparks
	local bladeX, bladeY = self:getBladePosition()

	sound.play( "clang" )

	for _ = 1, sparkConfig.clatterCount do
		local angle = rad( randomBetween( sparkConfig.clatterMinAngle, sparkConfig.clatterMaxAngle ) )
		local speed = randomBetween( sparkConfig.clatterMinSpeed, sparkConfig.clatterMaxSpeed )
		self:spawnSpark( bladeX, bladeY, speed * cos( angle ), speed * sin( angle ), sparkConfig.clatterGravity, sparkConfig.clatterLife, sparkConfig.metalColor )
	end
end

local function takeFromPool( pool )
	for i = 1, #pool do
		if not pool[i].isActive then
			return pool[i]
		end
	end

	return nil
end

function roomMethods:takeChunk()
	local chunk = takeFromPool( self.chunks )

	if chunk then
		return chunk
	end

	-- Every press must throw, so a full pool recycles chunks in turn.
	self.chunkCursor = self.chunkCursor % #self.chunks + 1
	return self.chunks[self.chunkCursor]
end

function roomMethods:throwCoal( fromX, fromY, count, speed )
	local coalConfig = config.coal
	local mouth = config.furnace.mouth
	local jitter = coalConfig.releaseJitter

	-- Shared by the chunks of one throw, so only the first to land whoomphs.
	local throw = { hasLanded = false }

	for i = 1, min( count, #self.chunks ) do
		local chunk = self:takeChunk()

		chunk.isActive = true
		chunk.throw = throw
		chunk.elapsed = -( i - 1 ) * coalConfig.stagger
		chunk.duration = coalConfig.flightTime / speed
		chunk.fromX = fromX + randomBetween( -jitter, jitter )
		chunk.fromY = fromY + randomBetween( -jitter, jitter )
		chunk.toX = mouth.centerX + randomBetween( -mouth.targetSpread, mouth.targetSpread )
		chunk.toY = mouth.targetY + randomBetween( -mouth.targetSpread, mouth.targetSpread )
		chunk.spin = randomBetween( -coalConfig.spin, coalConfig.spin )
		chunk.object.isVisible = false
	end
end

function roomMethods:updateChunks( dt )
	local coalConfig = config.coal

	for i = 1, #self.chunks do
		local chunk = self.chunks[i]

		if chunk.isActive then
			local object = chunk.object
			chunk.elapsed = chunk.elapsed + dt

			if chunk.elapsed >= chunk.duration then
				chunk.isActive = false
				object.isVisible = false
				self:landCoal( chunk.toX, chunk.toY, chunk.throw )

			elseif chunk.elapsed >= 0 then
				local progress = chunk.elapsed / chunk.duration
				local scale = lerp( 1, coalConfig.endScale, progress )

				object.isVisible = true
				object.x = lerp( chunk.fromX, chunk.toX, progress )

				-- Parabolic arc that peaks at arcHeight halfway through the flight.
				object.y = lerp( chunk.fromY, chunk.toY, progress ) - coalConfig.arcHeight * 4 * progress * ( 1 - progress )
				object.rotation = object.rotation + chunk.spin * dt
				object.xScale = scale
				object.yScale = scale
			end
		end
	end
end

function roomMethods:landCoal( x, y, throw )
	local flareConfig = config.flare
	self.kick = min( flareConfig.maxKick, self.kick + flareConfig.kick )

	if not throw.hasLanded then
		throw.hasLanded = true
		sound.play( "whoomph", self.level )
	end

	local flare = takeFromPool( self.flares )
	if flare then
		flare.isActive = true
		flare.elapsed = 0
		flare.object.x = x
		flare.object.y = y
	end

	for _ = 1, flareConfig.sparkCount do
		local angle = rad( randomBetween( flareConfig.sparkMinAngle, flareConfig.sparkMaxAngle ) )
		local speed = randomBetween( flareConfig.sparkMinSpeed, flareConfig.sparkMaxSpeed )
		self:spawnSpark( x, y, speed * cos( angle ), speed * sin( angle ), flareConfig.sparkGravity, flareConfig.sparkLife, config.sparks.emberColor )
	end
end

function roomMethods:updateFlares( dt )
	local flareConfig = config.flare

	for i = 1, #self.flares do
		local flare = self.flares[i]

		if flare.isActive then
			local object = flare.object
			flare.elapsed = flare.elapsed + dt
			local progress = flare.elapsed / flareConfig.duration

			if progress >= 1 then
				flare.isActive = false
				object.isVisible = false
			else
				local scale = lerp( flareConfig.startScale, flareConfig.endScale, 1 - ( 1 - progress ) * ( 1 - progress ) )
				object.isVisible = true
				object.xScale = scale
				object.yScale = scale
				object.alpha = flareConfig.alpha * ( 1 - progress )
			end
		end
	end
end

-- Cosmetic only, so a full pool simply drops the spark.
function roomMethods:spawnSpark( x, y, velocityX, velocityY, gravity, life, color )
	local spark = takeFromPool( self.sparks )
	if not spark then
		return
	end

	spark.isActive = true
	spark.x = x
	spark.y = y
	spark.velocityX = velocityX
	spark.velocityY = velocityY
	spark.gravity = gravity
	spark.life = life
	spark.age = 0
	setColour( spark.object, color )
end

function roomMethods:updateSparks( dt )
	local safeRadius = config.safeRadius

	for i = 1, #self.sparks do
		local spark = self.sparks[i]

		if spark.isActive then
			local object = spark.object
			spark.age = spark.age + dt
			spark.velocityY = spark.velocityY + spark.gravity * dt
			spark.x = spark.x + spark.velocityX * dt
			spark.y = spark.y + spark.velocityY * dt

			if spark.age >= spark.life or not isInside( spark.x, spark.y, safeRadius ) then
				spark.isActive = false
				object.isVisible = false
			else
				object.isVisible = true
				object.x = spark.x
				object.y = spark.y
				object.alpha = 1 - spark.age / spark.life
			end
		end
	end
end

function roomMethods:emitAmbientSparks( dt, level )
	local sparkConfig = config.sparks
	local mouth = config.furnace.mouth
	local mouthTop = mouth.bottom - mouth.straightHeight - mouth.halfWidth

	self.sparkTimer = self.sparkTimer + dt * sparkConfig.ambientRate * level * level

	while self.sparkTimer >= 1 do
		self.sparkTimer = self.sparkTimer - 1

		local x = mouth.centerX + randomBetween( -sparkConfig.ambientSpread, sparkConfig.ambientSpread )
		local velocityX = randomBetween( -sparkConfig.ambientDrift, sparkConfig.ambientDrift )
		local velocityY = -randomBetween( sparkConfig.ambientMinSpeed, sparkConfig.ambientMaxSpeed )
		self:spawnSpark( x, mouthTop, velocityX, velocityY, sparkConfig.ambientGravity, sparkConfig.ambientLife, sparkConfig.emberColor )
	end
end

function roomMethods:updateFlames( dt, level, kick )
	local flameConfig = config.flames
	local animation = self.flames
	local sprite = animation.sprite
	local presence = clamp01( ( level - flameConfig.startLevel ) / flameConfig.fadeRange )

	if presence <= 0 then
		sprite.isVisible = false
		return
	end

	local tiers = flameConfig.tiers
	local tagName = tiers[1].tag
	for i = 2, #tiers do
		if level >= tiers[i].fromLevel then
			tagName = tiers[i].tag
		end
	end

	drawing.setAnimationTag( animation, tagName, true )
	drawing.stepAnimation( animation, dt )

	self.flamePhase = self.flamePhase + dt * flameConfig.flickerSpeed * ( 1 + level * flameConfig.flickerSpeedGain )
	local wave = noise( self.flamePhase )

	local height = ( flameConfig.scaleMin + level * flameConfig.scaleRange ) * ( 1 + kick * flameConfig.kickHeight )
	height = height * ( 1 + flameConfig.flickerAmount * wave ) * presence

	local width = ( flameConfig.widthMin + level * flameConfig.widthRange ) * ( 1 - flameConfig.flickerAmount * flameConfig.squash * wave )

	sprite.isVisible = true
	sprite.x = config.furnace.mouth.centerX + flameConfig.sway * sin( self.flamePhase * flameConfig.swayFrequency )
	sprite.xScale = clamp( width, config.minScale, flameConfig.maxScale )
	sprite.yScale = clamp( height, config.minScale, flameConfig.maxScale )
	sprite.alpha = presence * ( 1 - flameConfig.alphaFlicker * ( 1 - wave ) * 0.5 )
end

function roomMethods:updateBurst( dt, level, kick )
	local burstConfig = config.burst
	local intensity = clamp01( ( level - burstConfig.startLevel ) / ( 1 - burstConfig.startLevel ) )

	-- One burst sound per flare-up; it re-arms only once the flames have gone out.
	local isBursting = intensity > 0

	if isBursting and not self.isBursting then
		sound.play( "burst" )
	end

	self.isBursting = isBursting

	for i = 1, #self.burstFlames do
		local tongue = self.burstFlames[i]
		local sprite = tongue.animation.sprite

		if intensity <= 0 then
			sprite.isVisible = false
		else
			local tongueConfig = tongue.config
			tongue.phase = tongue.phase + dt * burstConfig.flickerSpeed * tongueConfig.speedScale
			drawing.stepAnimation( tongue.animation, dt )

			local wave = noise( tongue.phase )
			local length = lerp( burstConfig.minLength, burstConfig.maxLength, intensity ) * tongueConfig.lengthScale
			length = length * ( 1 + burstConfig.flickerAmount * wave ) * ( 1 + kick * burstConfig.kickLength )

			local scale = length / burstConfig.nativeLength
			sprite.isVisible = true
			sprite.rotation = tongue.rotation + burstConfig.wobble * sin( tongue.phase * burstConfig.swayFrequency )
			sprite.xScale = scale
			sprite.yScale = scale
			sprite.alpha = tongueConfig.alpha * sqrt( intensity )
		end
	end
end

function roomMethods:updateFire( dt )
	local glowConfig = config.glow
	local haloConfig = config.halo
	local emberConfig = config.embers
	local gaugeConfig = config.gauge
	local time = self.time

	self.level = approachLinear( self.level, self.targetLevel, config.fire.response, dt )
	self.kick = self.kick * exp( -config.flare.kickDecay * dt )

	local level = self.level * self.dim
	local kick = self.kick * self.dim
	local flicker = 1 + glowConfig.flickerAmount * noise( time * glowConfig.flickerSpeed )

	self:updateFlames( dt, level, kick )
	self:updateBurst( dt, level, kick )
	self:emitAmbientSparks( dt, level )

	for i = 1, #self.embers do
		local ember = self.embers[i]
		local pulse = emberConfig.pulse * sin( time * emberConfig.pulseSpeed + ember.phase )
		local glow = clamp01( emberConfig.baseGlow * self.dim + level * emberConfig.levelGlow + kick * emberConfig.kickGlow + pulse )
		setLerpColor( ember.object, emberConfig.coldColor, emberConfig.hotColor, glow )
	end

	for i = 1, #self.halo do
		local alpha = haloConfig.alphas[i] * ( ( haloConfig.baseLevel + level ) * flicker + kick * haloConfig.kickAlpha )
		self.halo[i].alpha = clamp01( alpha )
	end

	self.warmGlow.alpha = clamp01( glowConfig.baseAlpha + glowConfig.levelAlpha * level * flicker + glowConfig.kickAlpha * kick )

	local jitter = gaugeConfig.jitter * level * sin( time * gaugeConfig.jitterSpeed )
	self.gaugeNeedle.rotation = lerp( gaugeConfig.minRotation, gaugeConfig.maxRotation, level ) + jitter
end

function roomMethods:updateTooltip( dt )
	local tooltipConfig = config.tooltip
	local tooltip = self.tooltip

	self.tooltipAlpha = moveToward( self.tooltipAlpha, self.tooltipTarget, tooltipConfig.fadeSpeed * dt )

	if self.tooltipAlpha <= 0 then
		tooltip.isVisible = false
		return
	end

	self.tooltipPulse = self.tooltipPulse + dt * tooltipConfig.pulseSpeed
	local pulse = 0.5 + 0.5 * sin( self.tooltipPulse )
	local scale = 1 + tooltipConfig.pulseScale * pulse

	tooltip.isVisible = true
	tooltip.alpha = self.tooltipAlpha * lerp( tooltipConfig.pulseMinAlpha, 1, pulse )
	tooltip.xScale = scale
	tooltip.yScale = scale
end

--------------------------------------------------------------------------------------
-- Public functions

function engineRoom.new( parentGroup )
	local room = setmetatable( {}, roomMethods )

	local group = display.newGroup()
	parentGroup:insert( group )
	group.x = screen.minX
	group.y = screen.maxY
	room.group = group

	local sprites = config.sprites
	newPlacedImage( group, sprites.room )
	room.gaugeNeedle = newGaugeNeedle( group )
	room.embers = newEmbers( group )
	room.flames = newFurnaceFlames( group )
	newPlacedImage( group, sprites.front )
	room.halo = newHalo( group )
	room.sparks = newSparks( group )
	room.chunks = newCoalChunks( group )
	room.flares = newFlares( group )
	room.shovelSprite = newShovel( group )
	room.warmGlow = newWarmGlow( group )
	room.tooltip = newTooltip( group )
	newPlacedImage( group, sprites.rim )
	room.burstFlames = newBurstFlames( group )

	room.time = 0
	room.flamePhase = 0
	room.level = 0
	room.targetLevel = 0
	room.kick = 0
	room.dim = 1
	room.heat = 0
	room.sparkTimer = 0
	room.chunkCursor = 0

	room.tooltipAlpha = 0
	room.tooltipTarget = 0
	room.tooltipPulse = 0

	room.isFired = false
	room.isCompletePending = false
	room.isBursting = false

	local restPose = config.shovel.restPose
	room.motion = {
		isActive = false,
		progress = 0,
		idleTime = 0,
		isLoaded = false,
		hasReleased = false,
		extraChunks = 0,
		startPose = { x = restPose.x, y = restPose.y, rotation = restPose.rotation },
	}

	room:placeShovel( restPose.x, restPose.y, restPose.rotation )
	room:updateFire( 0 )

	return room
end

function roomMethods:setFireLevel( level )
	self.targetLevel = clamp01( level or 0 )
end

-- Every press yields a throw: before the release it adds a chunk to the coming throw, after it the swing restarts.
function roomMethods:shovel()
	if self.isFired then
		return
	end

	local motion = self.motion
	self.heat = self.heat + 1

	if motion.isActive and not motion.hasReleased then
		motion.extraChunks = motion.extraChunks + 1
	else
		self:startSwing()
	end
end

function roomMethods:showTooltip( isVisible )
	self.tooltipTarget = isVisible and 1 or 0
end

function roomMethods:playFired( onComplete )
	if self.isFired then
		return
	end

	self.isFired = true
	self.firedCallback = onComplete
	self.firedTime = 0
	self.tooltipTarget = 0
	self.motion.isActive = false
	self:setShovelLoaded( false )

	self.fall = {
		x = self.shovelX,
		y = self.shovelY,
		rotation = self.shovelRotation,
		velocityY = -config.fired.tossSpeed,
		bounces = 0,
		isSettled = false,
		wobble = 0,
		wobblePhase = 0,
	}
end

function roomMethods:containsPoint( x, y )
	return isInside( x - self.group.x, y - self.group.y, config.radius )
end

function roomMethods:getCenter()
	return self.group.x, self.group.y
end

function roomMethods:update( dt )
	self.time = self.time + dt

	if self.isFired then
		self:updateFired( dt )
	else
		self:updateShovel( dt )
	end

	self:updateChunks( dt )
	self:updateFlares( dt )
	self:updateFire( dt )
	self:updateSparks( dt )
	self:updateTooltip( dt )

	-- Called last, so a callback that tears the scene down never meets a half-updated room.
	if self.isCompletePending then
		self.isCompletePending = false
		local callback = self.firedCallback
		self.firedCallback = nil
		callback()
	end
end

return engineRoom
