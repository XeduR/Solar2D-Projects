-- Depth charge: dropped by destroyers, detonates on contact or after fuse timer.

local depthCharge = {}

local gameConfig = require( "data.gameConfig" )

--------------------------------------------------------------------------------------
-- Localised functions

local sqrt = math.sqrt

--------------------------------------------------------------------------------------
-- Public functions

function depthCharge.new( parentGroup, x, y, opts )
	opts = opts or {}
	local config = gameConfig.depthCharge
	local self = {}

	self.x = x
	self.y = y
	self.isAlive = true
	self.hasExploded = false

	local color = gameConfig.colors.depthCharge
	local explosionColor = gameConfig.colors.explosion

	local circle = display.newCircle( parentGroup, x, y, config.radius )
	circle:setFillColor( color[1], color[2], color[3], config.fillAlpha )
	circle.strokeWidth = config.strokeWidth
	circle:setStrokeColor( color[1], color[2], color[3] )

	self.displayObject = circle

	local fuseTransition

	local function detonate()
		if self.hasExploded then return end
		self.hasExploded = true

		if fuseTransition then
			transition.cancel( fuseTransition )
			fuseTransition = nil
		end

		display.remove( circle )
		circle = nil
		self.displayObject = nil

		-- Explosion visual
		local explosion = display.newCircle( parentGroup, x, y, config.blastRadius )
		explosion:setFillColor( explosionColor[1], explosionColor[2], explosionColor[3] )
		explosion.alpha = config.explosionAlpha

		transition.to( explosion, {
			tag = "game",
			time = config.explosionDuration,
			xScale = config.explosionScale,
			yScale = config.explosionScale,
			alpha = 0,
			transition = easing.inOutBack,
			onComplete = function()
				self.isAlive = false
				display.remove( explosion )
				explosion = nil
			end,
		} )

		if opts.onExplode then
			opts.onExplode( x, y )
		end
	end

	self.detonate = detonate

	-- Fuse timer
	fuseTransition = transition.to( circle, {
		tag = "game",
		time = config.fuseDuration,
		onComplete = detonate,
	} )

	function self.checkCollision( targetX, targetY, targetRadius )
		if self.hasExploded then return false end
		local dx = targetX - self.x
		local dy = targetY - self.y
		return sqrt( dx * dx + dy * dy ) <= ( config.radius + targetRadius )
	end

	function self.destroy()
		self.isAlive = false
		self.hasExploded = true
		if fuseTransition then
			transition.cancel( fuseTransition )
			fuseTransition = nil
		end
		display.remove( circle )
		circle = nil
		self.displayObject = nil
	end

	return self
end

return depthCharge
