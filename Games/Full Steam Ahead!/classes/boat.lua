-- Steamboat and comet visuals, phase 2 flight, and their particle effects.

local boat = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local sheets = require( "classes.sheets" )
local drawing = require( "classes.drawing" )
local config = require( "data.boat" )
local gameConfig = require( "data.game" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local boatMethods = {}
boatMethods.__index = boatMethods

--------------------------------------------------------------------------------------
-- Localised functions

local abs = math.abs
local cos = math.cos
local floor = math.floor
local max = math.max
local min = math.min
local pi = math.pi
local rad = math.rad
local random = math.random
local sin = math.sin

local clamp01 = drawing.clamp01
local lerp = drawing.lerp
local randomRange = drawing.randomRange
local randomSpread = drawing.randomSpread
local setColour = drawing.setColour
local newGroup = drawing.newGroup
local setPivot = drawing.setPivot

--------------------------------------------------------------------------------------
-- Private functions

local function newParticlePool( group, settings )
	local pool = {
		settings = settings,
		particles = {},
		nextIndex = 1,
		carry = 0,
		frameCounts = {},
	}

	local tags = sheets.load( settings.family, settings.name ).tags
	for i = 1, #settings.tags do
		pool.frameCounts[settings.tags[i]] = #tags[settings.tags[i]].frames
	end

	for i = 1, settings.count do
		local object = sheets.newSprite( group, settings.family, settings.name, settings.tags )
		object.isVisible = false

		pool.particles[i] = {
			object = object,
			life = 0,
			maxLife = 1,
			velocityX = 0,
			velocityY = 0,
			size = 1,
			frame = 1,
			frameCount = 1,
		}
	end

	return pool
end

-- tag picks one of the pool's tags and defaults to the first.
local function emitParticle( pool, x, y, velocityX, velocityY, size, tag )
	local settings = pool.settings
	local particle = pool.particles[pool.nextIndex]
	pool.nextIndex = pool.nextIndex % #pool.particles + 1

	particle.maxLife = randomRange( settings.life )
	particle.life = particle.maxLife
	particle.velocityX = velocityX
	particle.velocityY = velocityY
	particle.size = size
	particle.frame = 1

	tag = tag or settings.tags[1]
	particle.frameCount = pool.frameCounts[tag]

	local object = particle.object
	object:setSequence( tag )
	object.x = x
	object.y = y
	object.isVisible = true
end

-- Turns an emission rate into a whole particle count for this frame, carrying the remainder.
local function takeEmissionCount( pool, rate, dt )
	pool.carry = pool.carry + max( 0, rate ) * dt
	local count = floor( pool.carry )
	pool.carry = pool.carry - count
	return count
end

local function updateParticlePool( pool, dt )
	local settings = pool.settings
	local colourStart = settings.colourStart
	local colourEnd = settings.colourEnd

	for i = 1, #pool.particles do
		local particle = pool.particles[i]

		if particle.life > 0 then
			local object = particle.object
			particle.life = particle.life - dt

			if particle.life <= 0 then
				object.isVisible = false

			else
				local remaining = particle.life / particle.maxLife
				local age = 1 - remaining
				local scale = max( config.particleMinScale, particle.size * lerp( settings.scaleStart, settings.scaleEnd, age ) )
				local alpha = settings.alpha * remaining ^ settings.fadePower
				local frame = min( particle.frameCount, floor( age * particle.frameCount ) + 1 )

				particle.velocityY = particle.velocityY + settings.gravity * dt
				particle.velocityX = particle.velocityX * ( 1 - settings.drag * dt )
				object.x = object.x + particle.velocityX * dt
				object.y = object.y + particle.velocityY * dt

				if frame ~= particle.frame then
					particle.frame = frame
					object:setFrame( frame )
				end

				object.xScale = scale
				object.yScale = scale

				if colourStart then
					object:setFillColor(
						lerp( colourStart[1], colourEnd[1], age ),
						lerp( colourStart[2], colourEnd[2], age ),
						lerp( colourStart[3], colourEnd[3], age ),
						alpha
					)
				else
					object.alpha = alpha
				end
			end
		end
	end
end

local function newCometGlow( group )
	local settings = config.cometGlow
	local glow = newGroup( group )
	glow.x = settings.x
	glow.y = settings.y

	for i = 1, #settings.layers do
		local layer = settings.layers[i]
		local circle = display.newCircle( glow, 0, 0, layer.radius )
		setColour( circle, layer.colour, layer.alpha )
	end

	glow.alpha = 0
	glow.isVisible = false

	return glow
end

local function newBoatImage( group, settings, x, y )
	local image = sheets.newImage( group, config.family, settings.name )
	setPivot( image, config.family, settings.name, settings.pivot )
	image.x = x
	image.y = y

	return image
end

local function newChimneyFlame( group )
	local settings = config.chimneyFlame
	local flame = sheets.newSprite( group, settings.family, settings.name, { settings.tag } )
	setPivot( flame, settings.family, settings.name, settings.pivot )
	flame.x = config.chimney.x
	flame.y = config.chimney.topY
	flame.isVisible = false

	return flame, drawing.newAnimation( flame, settings.family, settings.name, settings.tag )
end

local function newPaddleWheel( group )
	local settings = config.paddleWheel
	local wheel = newGroup( group )
	wheel.x = settings.x
	wheel.y = settings.y

	local image = sheets.newImage( wheel, config.family, settings.name )
	setPivot( image, config.family, settings.name, settings.pivot )

	local blur = display.newCircle( wheel, 0, 0, settings.blurRadius )
	setColour( blur, settings.blurColour, settings.blurAlpha )
	blur.alpha = 0

	return {
		image = image,
		blur = blur,
		rate = 0,
	}
end

-- The captain group's origin is at his feet, so leaning pivots there.
local function newCaptain( group )
	local settings = config.captain
	local captain = newGroup( group )
	captain.x = settings.x
	captain.y = settings.y

	local sprite = sheets.newSprite( captain, config.family, settings.name, settings.tags )
	setPivot( sprite, config.family, settings.name, settings.pivot )
	captain.animation = drawing.newAnimation( sprite, config.family, settings.name, settings.startTag )

	return captain
end

-- Converts a point in boat units to the layer coordinates the particles live in.
function boatMethods:localToLayer( localX, localY )
	local radians = rad( self.rotation )
	local cosine = cos( radians )
	local sine = sin( radians )
	local scale = self.scale

	return self.x + ( localX * cosine - localY * sine ) * scale, self.y + ( localX * sine + localY * cosine ) * scale
end

-- A coasting boat keeps its velocity and tilt and ignores the screen edges, so it carries on along its trajectory.
function boatMethods:updateSpace( dt )
	if self.isCoasting then
		self:setPose( self.x, self.y + self.velocityY * dt, self.scale, self.rotation )
		return
	end

	local settings = config.space
	local acceleration = self.isThrusting and -settings.thrust or settings.gravity
	local velocityY = max( -settings.maxSpeed, min( settings.maxSpeed, self.velocityY + acceleration * dt ) )
	local tilt = drawing.approach( self.rotation, velocityY / settings.maxSpeed * settings.tiltMax, settings.tiltResponse, dt )

	self.velocityY = velocityY
	self:setPose( self.x, self.y + velocityY * dt, self.scale, tilt )
	self:checkEdgeHit()
end

-- The screen edges are deadly: the boat stops where its circle first touches one, so the scene sees the hit that same frame.
function boatMethods:checkEdgeHit()
	local x, y, radius = self:getCollisionCircle()
	local overlap = 0

	if y - radius <= screen.minY then
		self.edgeHit = "top"
		self.edgeHitY = screen.minY
		overlap = y - radius - screen.minY

	elseif y + radius >= screen.maxY then
		self.edgeHit = "bottom"
		self.edgeHitY = screen.maxY
		overlap = y + radius - screen.maxY
	end

	if self.edgeHit then
		self.edgeHitX = x
		self.velocityY = 0
		self:setPose( self.x, self.y - overlap, self.scale, self.rotation )
	end
end

function boatMethods:emitSmoke( dt, speed, fireLevel, scroll, rateLevel )
	local settings = config.smoke
	local count = takeEmissionCount( self.smoke, ( settings.rate + settings.ratePerSpeed * speed ) * rateLevel, dt )

	for _ = 1, count do
		local x, y = self:localToLayer( settings.x + randomSpread( settings.jitter ), settings.y )
		local velocityX = -( scroll * settings.scrollFactor + randomRange( settings.drift ) * self.scale )
		local velocityY = -randomRange( settings.rise ) * self.scale
		local tag = random() < fireLevel and settings.tags[2] or settings.tags[1]
		emitParticle( self.smoke, x, y, velocityX, velocityY, self.scale, tag )
	end
end

function boatMethods:emitFlames( dt, scroll, rateLevel )
	local settings = config.flames
	local count = takeEmissionCount( self.flames, settings.rate * rateLevel, dt )

	for _ = 1, count do
		local x, y = self:localToLayer( settings.x + randomSpread( settings.jitter ), settings.y )
		local velocityX = randomRange( settings.spread ) * self.scale - scroll * settings.scrollFactor
		local velocityY = -randomRange( settings.rise ) * self.scale
		emitParticle( self.flames, x, y, velocityX, velocityY, self.scale )
	end
end

function boatMethods:emitWake( dt, speed, scroll, rateLevel )
	local settings = config.wake
	local count = takeEmissionCount( self.wake, ( settings.rate + settings.ratePerSpeed * speed ) * rateLevel, dt )

	for _ = 1, count do
		local x = self:localToLayer( randomRange( settings.sourceX ), 0 )
		local y = self.waterY + randomRange( settings.offsetY ) * self.scale
		local velocityX = -( scroll * settings.scrollFactor + randomRange( settings.drift ) * self.scale )
		emitParticle( self.wake, x, y, velocityX, 0, self.scale )
	end
end

function boatMethods:emitSprayFrom( localX, localY, rangeX, rangeY, boost, scroll )
	local settings = config.spray
	local x, y = self:localToLayer( localX, localY )
	local velocityX = randomRange( rangeX ) * boost * self.scale - scroll * settings.scrollFactor
	local velocityY = randomRange( rangeY ) * boost * self.scale
	emitParticle( self.spray, x, y, velocityX, velocityY, self.scale )
end

function boatMethods:emitSpray( dt, speed, scroll, rateLevel )
	local settings = config.spray
	local count = takeEmissionCount( self.spray, settings.ratePerSpeed * speed ^ settings.speedPower * rateLevel, dt )
	local boost = settings.speedBoost + speed

	for i = 1, count do
		if i % 2 == 0 then
			self:emitSprayFrom( settings.bowX, settings.bowY, settings.bowVelocityX, settings.bowVelocityY, boost, scroll )
		else
			self:emitSprayFrom( settings.wheelX, settings.wheelY, settings.wheelVelocityX, settings.wheelVelocityY, boost, scroll )
		end
	end
end

function boatMethods:emitTrail( dt, scroll, rateLevel )
	local settings = config.trail
	local rate = settings.rate * rateLevel

	if self.isThrusting and self.mode == "space" then
		rate = rate * settings.thrustBoost
	end

	local count = takeEmissionCount( self.trail, rate, dt )

	for _ = 1, count do
		local x, y = self:localToLayer( settings.x, settings.y + randomSpread( settings.jitter ) )
		local velocityX = -( randomRange( settings.speed ) + scroll * settings.scrollFactor )
		local velocityY = randomRange( settings.spread ) - self.velocityY * settings.climbInfluence
		emitParticle( self.trail, x, y, velocityX, velocityY, 1 )
	end
end

function boatMethods:animateParts( speed, fireLevel, cometLevel )
	local time = self.time

	local captain = config.captain
	self.captain.rotation = -captain.leanMax * speed + sin( time * captain.swaySpeed ) * captain.swayAmount

	local flameSettings = config.chimneyFlame
	local flameLevel = clamp01( ( fireLevel - flameSettings.start ) / flameSettings.range )
	local flame = self.chimneyFlame
	flame.isVisible = flameLevel > 0
	flame.alpha = flameLevel
	flame.yScale = lerp( flameSettings.minHeight, 1, flameLevel )
	flame.rotation = -flameSettings.lean * speed

	local glowSettings = config.cometGlow
	local glow = self.glow
	glow.isVisible = cometLevel > 0
	glow.alpha = cometLevel

	local pulse = 1 + sin( time * glowSettings.pulseSpeed ) * glowSettings.pulseAmount
	glow.xScale = pulse
	glow.yScale = pulse

	return flameLevel
end

function boatMethods:stopPaddleWheel()
	local wheel = self.wheel
	if wheel.spin then
		transition.cancel( wheel.spin )
		wheel.spin = nil
	end
end

-- An endless transition turns the wheel, so a new speed means restarting it from the current angle.
function boatMethods:spinPaddleWheel( speed )
	local settings = config.paddleWheel
	local wheel = self.wheel
	wheel.blur.alpha = speed

	local rate = lerp( settings.spinIdle, settings.spinMax, speed )
	if wheel.spin and abs( rate - wheel.rate ) < settings.spinStep then
		return
	end

	self:stopPaddleWheel()

	local image = wheel.image
	image.rotation = image.rotation % 360
	wheel.rate = rate
	wheel.spin = transition.to( image, { rotation = image.rotation + 360, time = 360 / rate * 1000, iterations = 0, tag = gameConfig.transitionTag } )
end

--------------------------------------------------------------------------------------
-- Public functions

-- layers.back sits behind the boat (smoke, flames, trail), layers.body holds the boat, layers.front sits in front of the sea (wake, spray).
function boat.new( layers )
	local self = setmetatable( {}, boatMethods )

	self.mode = "ocean"
	self.time = 0
	self.x = 0
	self.y = 0
	self.waterY = 0
	self.scale = 1
	self.rotation = 0
	self.velocityY = 0
	self.isThrusting = false
	self.isCoasting = false

	self.backLayer = layers.back
	self.smoke = newParticlePool( layers.back, config.smoke )
	self.flames = newParticlePool( layers.back, config.flames )
	self.trail = newParticlePool( layers.back, config.trail )
	self.sparks = newParticlePool( layers.back, config.sparks )

	local body = newGroup( layers.body )
	self.body = body
	self.glow = newCometGlow( body )
	newBoatImage( body, config.body, 0, 0 )
	self.wheel = newPaddleWheel( body )
	self.captain = newCaptain( body )
	self.chimneyFlame, self.chimneyFlameAnimation = newChimneyFlame( body )

	self.wake = newParticlePool( layers.front, config.wake )
	self.spray = newParticlePool( layers.front, config.spray )

	return self
end

function boatMethods:setMode( mode )
	self.mode = mode
	self.velocityY = 0
end

function boatMethods:setPose( x, y, scale, rotation )
	self.x = x
	self.y = y
	self.scale = scale
	self.rotation = rotation

	local body = self.body
	body.x = x
	body.y = y
	body.xScale = scale
	body.yScale = scale
	body.rotation = rotation
end

function boatMethods:getPosition()
	return self.x, self.y
end

-- Places the boat on the water with its own bobbing; speed is the 0 to 1 speed level.
function boatMethods:float( x, waterY, scale, speed )
	local settings = config.float
	local time = self.time
	local calm = 1 - settings.bobCalm * speed
	local shake = sin( time * settings.shakeSpeedA ) * sin( time * settings.shakeSpeedB ) * settings.shakeAmount * speed
	local bob = sin( time * settings.bobSpeed ) * settings.bobAmount * calm + shake
	local tilt = sin( time * settings.bobSpeed * settings.tiltSpeedRatio ) * settings.tiltAmount * calm - settings.pitchUp * speed + shake

	self.waterY = waterY
	self:setPose( x, waterY + bob * scale, scale, tilt )
end

-- Gravity, thrust and edge hits stop acting while coasting, as during the fired ending.
function boatMethods:setCoasting( isCoasting )
	self.isCoasting = isCoasting and true or false
end

function boatMethods:setThrust( isHeld )
	self.isThrusting = isHeld and true or false
end

-- pose is one of config.captain.tags.
function boatMethods:setCaptainPose( pose )
	drawing.setAnimationTag( self.captain.animation, pose )
end

function boatMethods:getCaptainPoint()
	if self.mode == "exploded" or self.scale < config.captain.minScale then
		return self.body:localToContent( config.centre.x, config.centre.y )
	end

	return self.captain:localToContent( 0, config.captain.headY )
end

function boatMethods:getCollisionCircle()
	local x, y = self.body:localToContent( config.centre.x, config.centre.y )
	return x, y, config.collisionRadius
end

-- Returns nil, or "top"/"bottom" with the contact point in content coordinates once the boat touches a screen edge in phase 2.
function boatMethods:getEdgeHit()
	if self.mode ~= "space" or not self.edgeHit then
		return nil
	end

	return self.edgeHit, self.edgeHitX, self.edgeHitY
end

function boatMethods:explode( x, y )
	if self.mode == "exploded" then
		return
	end

	self.mode = "exploded"
	self.isThrusting = false
	self.body.isVisible = false
	self:stopPaddleWheel()

	local settings = config.explosion
	local layerX, layerY = self.backLayer:contentToLocal( x, y )

	for _ = 1, settings.blobCount do
		local angle = random() * 2 * pi
		local speed = randomRange( settings.speed )
		emitParticle( self.trail, layerX, layerY, cos( angle ) * speed, sin( angle ) * speed, randomRange( settings.size ) )
	end

	for _ = 1, settings.sparkCount do
		local angle = random() * 2 * pi
		local speed = randomRange( settings.sparkSpeed )
		emitParticle( self.sparks, layerX, layerY, cos( angle ) * speed, sin( angle ) * speed, 1 )
	end
end

-- speed is the 0 to 1 speed level, scroll the scenery speed in content units per second, waterLevel and cometLevel fade the sea and comet effects.
function boatMethods:update( dt, speed, fireLevel, scroll, waterLevel, cometLevel )
	self.time = self.time + dt

	if self.mode == "space" and not self.edgeHit then
		self:updateSpace( dt )
	end

	if self.mode ~= "exploded" then
		self:spinPaddleWheel( speed )
		drawing.stepAnimation( self.captain.animation, dt )
		drawing.stepAnimation( self.chimneyFlameAnimation, dt )

		local flameLevel = self:animateParts( speed, fireLevel, cometLevel )
		local smokeLevel = ( 1 - flameLevel * config.chimneyFlame.smokeCut ) * ( 1 - cometLevel )

		self:emitSmoke( dt, speed, fireLevel, scroll, smokeLevel )
		self:emitFlames( dt, scroll, flameLevel )
		self:emitWake( dt, speed, scroll, waterLevel )
		self:emitSpray( dt, speed, scroll, waterLevel )
		self:emitTrail( dt, scroll, cometLevel )
	end

	updateParticlePool( self.smoke, dt )
	updateParticlePool( self.flames, dt )
	updateParticlePool( self.trail, dt )
	updateParticlePool( self.wake, dt )
	updateParticlePool( self.spray, dt )
	updateParticlePool( self.sparks, dt )
end

return boat
