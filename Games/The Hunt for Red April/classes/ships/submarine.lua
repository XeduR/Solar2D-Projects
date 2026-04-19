local submarine = {}

local gameConfig = require( "data.gameConfig" )

--------------------------------------------------------------------------------------
-- Localised functions

local sqrt = math.sqrt

--------------------------------------------------------------------------------------
-- Private functions

local function clamp( v, lo, hi )
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

--------------------------------------------------------------------------------------
-- Public functions

function submarine.new( parentGroup, opts )
	local config = gameConfig.submarine
	opts = opts or {}

	local group = display.newGroup()
	parentGroup:insert( group )

	local color = opts.color or gameConfig.colors.playerSub
	local body = display.newPolygon( group, 0, 0, config.shape )
	body:setFillColor( color[1], color[2], color[3] )
	body.strokeWidth = config.strokeWidth
	body:setStrokeColor( color[1], color[2], color[3] )

	-- State
	group.vx = 0
	group.vy = 0
	group.heading = opts.heading or 0
	group.isAlive = true
	group.collisionRadius = config.collisionRadius
	group.isPlayer = opts.isPlayer or false

	body.rotation = math.deg( group.heading )

	--------------------------------------------------------------------------------------
	-- Methods attached to the group

	function group.setHeading( heading )
		group.heading = heading
		body.rotation = math.deg( heading )
	end

	function group.getHeading()
		return group.heading
	end

	-- Apply thrust in a given direction and update velocity.
	function group.applyThrust( thrustX, thrustY, thrust )
		if not group.isAlive then return end

		local speed = config.maxSpeed * thrust
		local rate = 1 - config.drag
		group.vx = group.vx + ( thrustX * speed - group.vx ) * rate
		group.vy = group.vy + ( thrustY * speed - group.vy ) * rate
	end

	-- Move sub by velocity, apply drag, clamp to world bounds.
	function group.update( dt, worldW, worldH )
		if not group.isAlive then return end

		group.x = group.x + group.vx * dt
		group.y = group.y + group.vy * dt

		-- Drag
		group.vx = group.vx * config.drag
		group.vy = group.vy * config.drag

		-- Clamp to world
		local r = config.collisionRadius
		group.x = clamp( group.x, r, worldW - r )
		group.y = clamp( group.y, r, worldH - r )
	end

	-- Returns current speed magnitude (for engine hum volume).
	function group.getSpeed()
		return sqrt( group.vx * group.vx + group.vy * group.vy )
	end

	function group.destroy()
		group.isAlive = false
		display.remove( group )
	end

	return group
end

return submarine
