local sonar = {}

local gameConfig = require( "data.gameConfig" )

--------------------------------------------------------------------------------------
-- Localised functions

local sqrt = math.sqrt
local abs = math.abs
local min = math.min
local max = math.max
local remove = table.remove

--------------------------------------------------------------------------------------
-- Public functions

function sonar.new( parentGroup, params )
	params = params or {}
	local self = {}

	-- Merge config with optional overrides.
	local pingConfig = gameConfig.ping
	local ringSpeed = params.ringSpeed or pingConfig.ringSpeed
	local ringMaxRadius = params.ringMaxRadius or pingConfig.ringMaxRadius
	local ringThickness = params.ringThickness or pingConfig.ringThickness
	local ringStartAlpha = params.ringStartAlpha or pingConfig.ringStartAlpha
	local revealFadeIn = params.revealFadeIn or pingConfig.revealFadeIn
	local revealHold = params.revealHold or pingConfig.revealHold
	local revealFadeOut = params.revealFadeOut or pingConfig.revealFadeOut
	local ghostFadeOut = params.ghostFadeOut or pingConfig.ghostFadeOut

	local playerColor = gameConfig.colors.playerPing
	local enemyColor = gameConfig.colors.destroyerPing

	-- When true, all registered objects stay at alpha=1 and reveal transitions are skipped.
	local revealAll = false

	-- Revealable objects. Dense array, swap-remove on unregister.
	local revealables = {}

	-- Active sonar pings
	local pings = {}
	local nextPingId = 1

	--------------------------------------------------------------------------------------
	-- Registration

	function self.registerRevealable( obj, params ) -- luacheck: ignore params
		params = params or {}
		obj.alpha = revealAll and 1 or 0

		local entry = {
			object = obj,
			lastRevealedBy = nil,
			isGhostable = params.isGhostable == true,
			tag = params.tag or "terrain",
			tween = nil,
			width = params.width,
			height = params.height,
		}
		revealables[#revealables + 1] = entry
		return #revealables
	end

	-- Swap-remove to keep the array dense.
	function self.unregisterRevealable( index )
		local count = #revealables
		if index < 1 or index > count then return end

		if index < count then
			-- Swap target with last entry.
			revealables[index] = revealables[count]

			for i = 1, #pings do
				local hits = pings[i].hits
				if hits[count] then
					hits[index] = true
					hits[count] = nil
				end
			end
		end
		revealables[count] = nil
	end

	-- Debug: make all registered objects permanently visible.
	function self.setRevealAll( enabled )
		revealAll = enabled
		if enabled then
			for i = 1, #revealables do
				local entry = revealables[i]
				if entry.tween then
					transition.cancel( entry.tween )
					entry.tween = nil
				end
				if entry.object and entry.object.removeSelf then
					entry.object.alpha = 1
				end
			end
		end
	end

	-- Reveal a single registered object without affecting others.
	-- Skips the onReveal callback (used for self-reveals, not game logic).
	function self.revealSingle( targetObj )
		if revealAll then return end
		for i = 1, #revealables do
			local entry = revealables[i]
			if entry.object == targetObj then
				if entry.tween then
					transition.cancel( entry.tween )
					entry.tween = nil
				end
				targetObj.alpha = 1
				entry.tween = transition.to( targetObj, {
					delay = revealHold,
					time = entry.isGhostable and ghostFadeOut or revealFadeOut,
					alpha = 0,
					transition = easing.outQuad,
				} )
				break
			end
		end
	end

	--------------------------------------------------------------------------------------
	-- Emitting a sonar ping

	function self.emit( x, y, emitOpts )
		emitOpts = emitOpts or {}
		local maxR = emitOpts.range or ringMaxRadius

		-- Visible ring: circle with no fill and a colored stroke.
		local ringGroup = emitOpts.group or parentGroup
		local ring = display.newCircle( ringGroup, x, y, 1 )
		ring:setFillColor( 0, 0 )
		ring.strokeWidth = ringThickness

		local color = emitOpts.color
		if color then
			ring:setStrokeColor( color[1], color[2], color[3], ringStartAlpha )
		elseif emitOpts.source == "player" then
			ring:setStrokeColor( playerColor[1], playerColor[2], playerColor[3], ringStartAlpha )
		else
			ring:setStrokeColor( enemyColor[1], enemyColor[2], enemyColor[3], ringStartAlpha )
		end

		local ping = {
			id = nextPingId,
			x = x,
			y = y,
			radius = 1,
			maxRadius = maxR,
			source = emitOpts.source or "unknown",
			ring = ring,
			hits = {},
			visualOnly = emitOpts.visualOnly or false,
		}
		nextPingId = nextPingId + 1
		pings[#pings + 1] = ping

		if emitOpts.onEmit then emitOpts.onEmit( ping ) end

		return ping
	end

	--------------------------------------------------------------------------------------
	-- Reveal logic

	local function revealObject( entry, ping )
		local obj = entry.object
		if not obj or obj.removeSelf == nil then return end
		-- Skip objects that are no longer alive (e.g. sinking ships).
		if obj.isAlive == false then return end

		-- Game-logic callback for ghost spawning, AI notifications, etc.
		if self.onReveal then
			self.onReveal( entry, ping )
		end

		-- In revealAll mode, objects stay at alpha=1. Skip transitions.
		if revealAll then return end

		-- Cancel existing fade so repeated pings refresh the reveal.
		if entry.tween then
			transition.cancel( entry.tween )
			entry.tween = nil
		end

		local fadeOut = entry.isGhostable and ghostFadeOut or revealFadeOut

		-- Fade in fast, hold, then fade out.
		obj.alpha = 0
		entry.tween = transition.to( obj, {
			time = revealFadeIn,
			alpha = 1,
			onComplete = function()
				entry.tween = transition.to( obj, {
					time = revealHold + fadeOut,
					alpha = 0,
					transition = easing.outQuad,
				} )
			end,
		} )

		entry.lastRevealedBy = ping.id
	end

	local function updatePing( ping, dt )
		ping.radius = ping.radius + ringSpeed * dt

		-- Grow the visible ring and fade it as it expands.
		ping.ring.path.radius = ping.radius
		local t = ping.radius / ping.maxRadius
		ping.ring.alpha = ringStartAlpha * ( 1 - t )

		-- Visual-only pings skip object intersection entirely.
		if ping.visualOnly then
			return ping.radius < ping.maxRadius
		end

		-- Ring-vs-object intersection: check if object distance from ping
		-- center falls within a band around the current radius.
		local band = ringSpeed * dt * 1.5

		for i = 1, #revealables do
			local entry = revealables[i]
			if entry and not ping.hits[i] then
				local obj = entry.object
				if obj and obj.removeSelf then
					local dist
					if entry.width then
						-- Closest point on AABB to ping origin.
						local halfW = entry.width * 0.5
						local halfH = entry.height * 0.5
						local cx = max( obj.x - halfW, min( ping.x, obj.x + halfW ) )
						local cy = max( obj.y - halfH, min( ping.y, obj.y + halfH ) )
						local dx = cx - ping.x
						local dy = cy - ping.y
						dist = sqrt( dx * dx + dy * dy )
					else
						local dx = obj.x - ping.x
						local dy = obj.y - ping.y
						dist = sqrt( dx * dx + dy * dy )
					end
					if abs( dist - ping.radius ) <= band then
						ping.hits[i] = true
						revealObject( entry, ping )
					end
				end
			end
		end

		return ping.radius < ping.maxRadius
	end

	--------------------------------------------------------------------------------------
	-- Per-frame update

	local lastTime = system.getTimer()

	local function enterFrame()
		local now = system.getTimer()
		local dt = now - lastTime
		lastTime = now

		-- Iterate in reverse so we can remove in place.
		for i = #pings, 1, -1 do
			local ping = pings[i]
			local alive = updatePing( ping, dt )
			if not alive then
				display.remove( ping.ring )
				ping.ring = nil
				remove( pings, i )
			end
		end
	end

	Runtime:addEventListener( "enterFrame", enterFrame )

	--------------------------------------------------------------------------------------
	-- Cleanup

	function self.destroy()
		Runtime:removeEventListener( "enterFrame", enterFrame )
		for i = 1, #pings do
			display.remove( pings[i].ring )
			pings[i].ring = nil
		end
		pings = {}
		for i = 1, #revealables do
			local entry = revealables[i]
			if entry and entry.tween then
				transition.cancel( entry.tween )
			end
		end
		revealables = {}
	end

	return self
end

return sonar
