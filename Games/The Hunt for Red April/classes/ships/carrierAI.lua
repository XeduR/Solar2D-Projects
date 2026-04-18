-- Carrier AI: transition-based waypoint following.

local carrierAI = {}

local gameConfig = require( "data.gameConfig" )

--------------------------------------------------------------------------------------
-- Localised functions

local atan2 = math.atan2
local sqrt = math.sqrt

--------------------------------------------------------------------------------------
-- Constructor

function carrierAI.new( params )
	local self = {}

	local ship = params.ship
	local waypoints = params.waypoints
	local waypointIndex = params.startIndex or 1
	local direction = params.direction or 1
	local speed = gameConfig.carrier.maxSpeed
	local heading = ship.heading or 0

	local function advanceIndex()
		waypointIndex = waypointIndex + direction
		if waypointIndex > #waypoints then
			waypointIndex = 1
		elseif waypointIndex < 1 then
			waypointIndex = #waypoints
		end
	end

	local function moveToNextWaypoint()
		if not ship.isAlive then return end

		local wp = waypoints[waypointIndex]
		local dx = wp.x - ship.x
		local dy = wp.y - ship.y
		local dist = sqrt( dx * dx + dy * dy )

		if dist < 1 then
			advanceIndex()
			moveToNextWaypoint()
			return
		end

		heading = atan2( dy, dx )
		ship.setHeading( heading )

		local time = dist / speed

		transition.to( ship, {
			tag = "game",
			x = wp.x,
			y = wp.y,
			time = time,
			onComplete = function()
				advanceIndex()
				moveToNextWaypoint()
			end,
		} )
	end

	function self.start()
		advanceIndex()
		moveToNextWaypoint()
	end

	function self.getHeading()
		return heading
	end

	return self
end

return carrierAI
