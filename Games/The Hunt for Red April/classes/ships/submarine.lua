local submarine = {}

local gameConfig = require( "data.gameConfig" )

--------------------------------------------------------------------------------------
-- Localised functions

local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin

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
	group.throttle = 0 -- persistent: [-config.reverseRate, 1.0], 0 is neutral
	group.isAlive = true
	group.collisionRadius = config.collisionRadius
	group.isPlayer = opts.isPlayer or false

	body.rotation = math.deg( group.heading )

	--------------------------------------------------------------------------------------
	-- Methods attached to the group

	function group.getHeading()
		return group.heading
	end

	-- Tank-control turn. direction = -1 (left) or 1 (right).
	function group.turn( direction, dt )
		if not group.isAlive then return end
		group.heading = group.heading + direction * config.turnRate * dt
		body.rotation = math.deg( group.heading )
	end

	-- Adjust persistent throttle. direction = 1 (w/up) or -1 (s/down).
	function group.adjustThrottle( direction, dt )
		if not group.isAlive then return end
		group.throttle = group.throttle + direction * config.throttleRate * dt
		if group.throttle > 1 then group.throttle = 1
		elseif group.throttle < -config.reverseRate then group.throttle = -config.reverseRate end
	end

	-- Accelerate toward throttle-driven target velocity, move, apply drag, clamp.
	function group.update( dt, worldW, worldH )
		if not group.isAlive then return end

		local targetSpeed = config.maxSpeed * group.throttle
		local rate = 1 - config.drag
		group.vx = group.vx + ( cos( group.heading ) * targetSpeed - group.vx ) * rate
		group.vy = group.vy + ( sin( group.heading ) * targetSpeed - group.vy ) * rate

		group.x = group.x + group.vx * dt
		group.y = group.y + group.vy * dt

		group.vx = group.vx * config.drag
		group.vy = group.vy * config.drag

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
