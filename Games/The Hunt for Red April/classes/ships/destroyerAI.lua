-- Destroyer AI: patrol / escort carrier / chase player.

local destroyerAI = {}

local gameConfig = require( "data.gameConfig" )

--------------------------------------------------------------------------------------
-- Localised functions

local atan2 = math.atan2
local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt
local random = math.random

local function angleTo( fromX, fromY, toX, toY )
	return atan2( toY - fromY, toX - fromX )
end

local function distance( ax, ay, bx, by )
	local dx, dy = bx - ax, by - ay
	return sqrt( dx * dx + dy * dy )
end

--------------------------------------------------------------------------------------
-- Constructor

function destroyerAI.new( opts )
	opts = opts or {}
	local self = {}

	local config = opts.config or gameConfig.destroyer
	local ship = opts.ship
	local carrierRef = opts.carrier
	local allShips = opts.allShips

	self.role = opts.role or "patrol"
	ship.role = self.role

	local function randomSonarCooldown()
		return config.sonarCooldownMin + random() * ( config.sonarCooldownMax - config.sonarCooldownMin )
	end

	local state = {
		name = self.role == "escort" and "escort" or "patrol",
		waypoints = opts.waypoints or {},
		waypointIndex = 1,
		target = nil,
		previousTarget = nil,
		chaseTimer = 0,
		chaseOffsetX = 0,
		chaseOffsetY = 0,
		sonarCooldown = randomSonarCooldown(),
		depthChargeCooldown = config.depthChargeCooldown,
		thrust = 0.5,
		desiredHeading = ship.heading or 0,
		wantsToPing = false,
		wantsToDropCharge = false,
		dropX = 0,
		dropY = 0,
		burstRemaining = 0,
		burstDelay = 0,
		escortAngle = opts.escortAngle or 0,
	}

	local defaultState = state.name

	--------------------------------------------------------------------------------------
	-- Signal inputs

	function self.notifyPlayerDetected( x, y )
		if state.name == "dead" then return end

		local now = system.getTimer()

		if state.target then
			state.previousTarget = {
				x = state.target.x,
				y = state.target.y,
				time = state.target.time,
			}
		end

		state.target = {
			x = x,
			y = y,
			time = now,
			vx = 0,
			vy = 0,
		}

		if state.previousTarget then
			local elapsed = now - state.previousTarget.time
			if elapsed > 100 and elapsed < 10000 then
				state.target.vx = ( x - state.previousTarget.x ) / elapsed
				state.target.vy = ( y - state.previousTarget.y ) / elapsed
			end
		end

		-- Direct detection: head straight for predicted position.
		state.chaseOffsetX = 0
		state.chaseOffsetY = 0
		self.transition( "chase" )
	end

	function self.notifyAlert( x, y, alerterRole )
		if state.name == "dead" or state.name == "chase" then return end

		if self.role == "escort" and alerterRole ~= "escort" then return end

		local now = system.getTimer()
		state.target = {
			x = x,
			y = y,
			time = now,
			vx = 0,
			vy = 0,
		}

		-- Alerted destroyers spread around the predicted position.
		local angle = random() * 6.2832
		local dist = random() * config.chaseSpreadRadius
		state.chaseOffsetX = cos( angle ) * dist
		state.chaseOffsetY = sin( angle ) * dist
		self.transition( "chase" )
	end

	--------------------------------------------------------------------------------------
	-- State transitions

	function self.transition( newState )
		if state.name == "dead" then return end
		state.name = newState

		if newState ~= "chase" then
			state.burstRemaining = 0
		end

		if newState == "patrol" then
			state.thrust = 0.5
			state.sonarCooldown = randomSonarCooldown()
		elseif newState == "escort" then
			state.thrust = 0.6
			state.sonarCooldown = randomSonarCooldown()
		elseif newState == "chase" then
			local dur = self.role == "escort" and config.chaseDurationEscort or config.chaseDurationPatrol
			state.chaseTimer = dur
			state.thrust = 0.9
			state.sonarCooldown = randomSonarCooldown()
		elseif newState == "dead" then
			state.thrust = 0
			state.wantsToPing = false
			state.wantsToDropCharge = false
		end
	end

	--------------------------------------------------------------------------------------
	-- Per-state update

	local function updatePatrol()
		local wp = state.waypoints[state.waypointIndex]
		if not wp then return end

		local d = distance( ship.x, ship.y, wp.x, wp.y )
		if d < 50 then
			state.waypointIndex = ( state.waypointIndex % #state.waypoints ) + 1
			wp = state.waypoints[state.waypointIndex]
		end

		state.desiredHeading = angleTo( ship.x, ship.y, wp.x, wp.y )
		state.thrust = 0.5
	end

	local function updateEscort()
		if not carrierRef or not carrierRef.isAlive then
			self.transition( "patrol" )
			return
		end

		local carrierHeading = carrierRef.getHeading()
		local orbitAngle = carrierHeading + state.escortAngle
		local targetX = carrierRef.x + cos( orbitAngle ) * config.escortRadius
		local targetY = carrierRef.y + sin( orbitAngle ) * config.escortRadius

		local d = distance( ship.x, ship.y, targetX, targetY )
		state.desiredHeading = angleTo( ship.x, ship.y, targetX, targetY )

		if d > config.escortRadius * 2.5 then
			state.thrust = 1.0
		elseif d > config.escortRadius * 1.5 then
			state.thrust = 0.8
		elseif d < 30 then
			state.thrust = 0.3
		else
			state.thrust = 0.5
		end
	end

	local function updateChase( dt )
		-- Escort leash: abort chase if the carrier is too far away.
		if self.role == "escort" and carrierRef and carrierRef.isAlive then
			local carrierDist = distance( ship.x, ship.y, carrierRef.x, carrierRef.y )
			if carrierDist > config.escortLeashRadius then
				state.target = nil
				state.previousTarget = nil
				self.transition( "escort" )
				return
			end
		end

		state.chaseTimer = state.chaseTimer - dt

		if state.chaseTimer <= 0 then
			state.target = nil
			state.previousTarget = nil
			self.transition( defaultState )
			return
		end

		if not state.target then
			self.transition( defaultState )
			return
		end

		local now = system.getTimer()
		local age = now - state.target.time
		local predX = state.target.x + state.target.vx * age * config.predictionFactor + state.chaseOffsetX
		local predY = state.target.y + state.target.vy * age * config.predictionFactor + state.chaseOffsetY

		-- Steer away from nearby destroyers to avoid stacking.
		if allShips then
			local sepRadius = config.separationRadius
			local sepX, sepY = 0, 0
			for i = 1, #allShips do
				local other = allShips[i]
				if other ~= ship and other.isAlive then
					local d = distance( ship.x, ship.y, other.x, other.y )
					if d < sepRadius and d > 0 then
						local strength = ( sepRadius - d ) / sepRadius
						local dx, dy = ship.x - other.x, ship.y - other.y
						local invD = 1 / d
						sepX = sepX + dx * invD * strength * sepRadius
						sepY = sepY + dy * invD * strength * sepRadius
					end
				end
			end
			predX = predX + sepX
			predY = predY + sepY
		end

		state.desiredHeading = angleTo( ship.x, ship.y, predX, predY )
		state.thrust = 0.9

		-- Start a depth charge burst when close to predicted position.
		local d = distance( ship.x, ship.y, predX, predY )
		if d < config.depthChargeDropRange and state.depthChargeCooldown <= 0 and state.burstRemaining <= 0 then
			state.burstRemaining = config.depthChargeCount
			state.burstDelay = 0
			state.depthChargeCooldown = config.depthChargeCooldown
		end
	end

	--------------------------------------------------------------------------------------
	-- Main update

	function self.update( dt )
		if state.name == "dead" then return end

		state.wantsToPing = false
		state.wantsToDropCharge = false

		state.sonarCooldown = state.sonarCooldown - dt
		state.depthChargeCooldown = state.depthChargeCooldown - dt

		if state.name == "patrol" then updatePatrol()
		elseif state.name == "escort" then updateEscort()
		elseif state.name == "chase" then updateChase( dt )
		end

		-- Depth charge burst processing.
		if state.burstRemaining > 0 then
			state.burstDelay = state.burstDelay - dt
			if state.burstDelay <= 0 then
				state.wantsToDropCharge = true
				state.dropX = ship.x
				state.dropY = ship.y
				state.burstRemaining = state.burstRemaining - 1
				state.burstDelay = config.depthChargeDelay
			end
		end

		ship.applyHeadingThrust( state.desiredHeading, state.thrust, dt )

		if state.sonarCooldown <= 0 then
			state.wantsToPing = true
			state.sonarCooldown = randomSonarCooldown()
		end
	end

	--------------------------------------------------------------------------------------
	-- Outputs

	function self.getDesiredHeading() return state.desiredHeading end
	function self.getThrust() return state.thrust end
	function self.getState() return state.name end

	function self.consumePingRequest()
		if state.wantsToPing then
			state.wantsToPing = false
			return true
		end
		return false
	end

	function self.consumeDepthChargeRequest()
		if state.wantsToDropCharge then
			state.wantsToDropCharge = false
			return true, state.dropX, state.dropY
		end
		return false
	end

	function self.notifyHit()
		self.transition( "dead" )
	end

	return self
end

return destroyerAI
