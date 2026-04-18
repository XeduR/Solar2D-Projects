-- Straight-line torpedo with fuse timer and detonation.

local gameConfig = require( "data.gameConfig" )

local torpedo = {}

--------------------------------------------------------------------------------------
-- Localised functions

local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt
local max = math.max
local min = math.min

--------------------------------------------------------------------------------------
-- Public functions

function torpedo.new( parentGroup, x, y, heading, owner, opts )
	opts = opts or {}
	local config = gameConfig.torpedo
	local color = gameConfig.colors.torpedo

	local group = display.newGroup()
	parentGroup:insert( group )
	group.x = x
	group.y = y

	-- Visual: faint short line along heading.
	local dx = cos( heading ) * config.trailLength * 0.5
	local dy = sin( heading ) * config.trailLength * 0.5
	local trail = display.newLine( group, -dx, -dy, dx, dy )
	trail:setStrokeColor( color[1], color[2], color[3] )
	trail.strokeWidth = config.trailStrokeWidth
	trail.alpha = config.trailAlpha

	-- State
	group.heading = heading
	group.owner = owner
	group.speed = config.speed
	group.vx = cos( heading ) * config.speed
	group.vy = sin( heading ) * config.speed
	group.distanceTraveled = 0
	group.collisionRadius = config.collisionRadius
	group.isAlive = true
	group.hasExploded = false

	local fuseElapsed = 0
	local fuseDuration = config.fuseDuration

	--------------------------------------------------------------------------------------
	-- Methods

	function group.update( dt )
		if not group.isAlive or group.hasExploded then return end

		local stepX = group.vx * dt
		local stepY = group.vy * dt
		group.x = group.x + stepX
		group.y = group.y + stepY
		group.distanceTraveled = group.distanceTraveled + sqrt( stepX * stepX + stepY * stepY )

		fuseElapsed = fuseElapsed + dt
		if fuseElapsed >= fuseDuration then
			group.detonate()
		end
	end

	function group.checkCollision( targetX, targetY, targetRadius )
		if group.hasExploded then return false end
		local cx = group.x - targetX
		local cy = group.y - targetY
		return sqrt( cx * cx + cy * cy ) < ( group.collisionRadius + targetRadius )
	end

	function group.isOutOfBounds( worldW, worldH )
		return group.x < 0 or group.x > worldW or group.y < 0 or group.y > worldH
	end

	function group.checkRectCollision( rectX, rectY, rectW, rectH )
		if group.hasExploded then return false end
		local halfW = rectW * 0.5
		local halfH = rectH * 0.5
		local closestX = max( rectX - halfW, min( group.x, rectX + halfW ) )
		local closestY = max( rectY - halfH, min( group.y, rectY + halfH ) )
		local cx = group.x - closestX
		local cy = group.y - closestY
		return ( cx * cx + cy * cy ) < ( group.collisionRadius * group.collisionRadius )
	end

	function group.detonate()
		if group.hasExploded then return end
		group.hasExploded = true

		local ex, ey = group.x, group.y

		-- Hide torpedo visual.
		group.alpha = 0
		group.vx = 0
		group.vy = 0

		-- Explosion circle in parent group.
		local explosion = display.newCircle( parentGroup, ex, ey, config.blastRadius )
		explosion:setFillColor( color[1], color[2], color[3] )
		explosion.alpha = config.explosionAlpha

		transition.to( explosion, {
			tag = "game",
			time = config.explosionDuration,
			xScale = config.explosionScale,
			yScale = config.explosionScale,
			alpha = 0,
			transition = easing.inOutBack,
			onComplete = function()
				group.isAlive = false
				display.remove( explosion )
				explosion = nil
			end,
		} )

		if opts.onExplode then
			opts.onExplode( ex, ey )
		end
	end

	function group.destroy()
		group.isAlive = false
		group.hasExploded = true
		display.remove( group )
	end

	return group
end

return torpedo
