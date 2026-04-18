local destroyer = {}

local gameConfig = require( "data.gameConfig" )

--------------------------------------------------------------------------------------
-- Localised functions

local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt
local pi = math.pi

--------------------------------------------------------------------------------------
-- Private functions

local function clamp( v, lo, hi )
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function angleDiff( from, to )
	local diff = to - from
	while diff > pi do diff = diff - 2 * pi end
	while diff < -pi do diff = diff + 2 * pi end
	return diff
end

--------------------------------------------------------------------------------------
-- Public functions

function destroyer.new( parentGroup, opts )
	opts = opts or {}
	local config = gameConfig.destroyer

	local group = display.newGroup()
	parentGroup:insert( group )

	-- Ship's shape
	local halfL = config.bodyLength * 0.5
	local halfW = halfL * 0.35
	local vertices = {
		halfL, 0,
		0, -halfW,
		-halfL, 0,
		0, halfW,
	}

	local color = opts.color or gameConfig.colors.destroyer
	local body = display.newPolygon( group, 0, 0, vertices )
	body:setFillColor( color[1], color[2], color[3] )
	body.strokeWidth = config.strokeWidth
	body:setStrokeColor( color[1], color[2], color[3] )

	-- State
	group.vx = 0
	group.vy = 0
	group.heading = opts.heading or 0
	group.isAlive = true
	group.collisionRadius = config.collisionRadius
	group.role = nil -- set by AI after creation

	body.rotation = math.deg( group.heading )

	--------------------------------------------------------------------------------------
	-- Methods

	function group.setHeading( heading )
		group.heading = heading
		body.rotation = math.deg( heading )
	end

	function group.getHeading()
		return group.heading
	end

	function group.applyHeadingThrust( heading, thrust, dt )
		if not group.isAlive then return end

		local diff = angleDiff( group.heading, heading )
		local maxTurn = config.turnRate * dt
		if diff > maxTurn then diff = maxTurn
		elseif diff < -maxTurn then diff = -maxTurn end
		group.heading = group.heading + diff
		body.rotation = math.deg( group.heading )

		local speed = config.maxSpeed * thrust
		group.vx = cos( group.heading ) * speed
		group.vy = sin( group.heading ) * speed
	end

	function group.update( dt, worldW, worldH )
		if not group.isAlive then return end

		group.x = group.x + group.vx * dt
		group.y = group.y + group.vy * dt

		group.vx = group.vx * config.drag
		group.vy = group.vy * config.drag

		local r = config.collisionRadius
		group.x = clamp( group.x, r, worldW - r )
		group.y = clamp( group.y, r, worldH - r )
	end

	function group.getSpeed()
		return sqrt( group.vx * group.vx + group.vy * group.vy )
	end

	function group.destroy()
		group.isAlive = false
		display.remove( group )
	end

	return group
end

return destroyer
