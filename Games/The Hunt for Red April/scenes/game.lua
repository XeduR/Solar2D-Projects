local composer = require( "composer" )
local scene = composer.newScene()

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" ) -- luacheck: ignore
local gameConfig = require( "data.gameConfig" )
local controlsConfig = require( "data.controls" )
local map = require( "classes.map" )
local submarine = require( "classes.ships.submarine" )
local carrier = require( "classes.ships.carrier" )
local carrierAI = require( "classes.ships.carrierAI" )
local destroyer = require( "classes.ships.destroyer" )
local destroyerAI = require( "classes.ships.destroyerAI" )
local depthCharge = require( "classes.depthCharge" )
local torpedo = require( "classes.torpedo" )
local sonar = require( "classes.sonar" )
local crtShader = require( "assets.shaders.crt_shader" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local snapshot
local worldGroup, groupSub, groupTerrain, groupShips, groupUI, revealGroup
local activePlayerPing
local playerSub
local carrierShip, carrierController
local destroyerShip, destroyerController
local pingSystem
local torpedoes, depthCharges, destroyerPingTrackers, ghostObjects
local terrainObstacles
local terrainDisplayObjects, wallDisplayObjects
local levelBounds
local mapData
local keysDown = {}
local lastTime
local pingCooldown, fireCooldown
local torpedoesRemaining
local gameOver
local restartTimer
local uiTextPing, uiTextTorpedo, uiTextGameover, uiTextCarrierHit
local uiTextCarrierDir, carrierDirArrow, carrierDirTimer
local carrierHitpoints
local titleGroup, titleStartText
local waitingToStart, readyToStart
local blinkTimer, startDelayTimer

--------------------------------------------------------------------------------------
-- Localised functions

local sqrt = math.sqrt
local atan2 = math.atan2
local abs = math.abs
local cos = math.cos
local sin = math.sin
local deg = math.deg
local pi = math.pi
local remove = table.remove

local function clamp( v, lo, hi )
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function distance( ax, ay, bx, by )
	local dx, dy = bx - ax, by - ay
	return sqrt( dx * dx + dy * dy )
end

local compassDirections = { "east", "southeast", "south", "southwest", "west", "northwest", "north", "northeast" }

local function angleToCompass( rad )
	local d = deg( rad )
	d = ( d % 360 + 360 ) % 360
	return compassDirections[math.floor( ( d + 22.5 ) / 45 ) % 8 + 1]
end

-- Point-in-polygon test against a flat vertex hull rotated by heading around (cx, cy).
local function pointInRotatedHull( px, py, cx, cy, heading, hull )
	local cosH = cos( -heading )
	local sinH = sin( -heading )
	local dx = px - cx
	local dy = py - cy
	local lx = dx * cosH - dy * sinH
	local ly = dx * sinH + dy * cosH

	local n = #hull
	local inside = false
	local jx = hull[n - 1]
	local jy = hull[n]
	for i = 1, n, 2 do
		local ix = hull[i]
		local iy = hull[i + 1]
		if ( iy > ly ) ~= ( jy > ly ) and lx < ( jx - ix ) * ( ly - iy ) / ( jy - iy ) + ix then
			inside = not inside
		end
		jx = ix
		jy = iy
	end
	return inside
end

-- Check if an explosion at (ex, ey) with given radius reaches a rotated hull.
local function explosionHitsHull( ex, ey, cx, cy, heading, hull, radius )
	if pointInRotatedHull( ex, ey, cx, cy, heading, hull ) then
		return true
	end
	local cosH = cos( -heading )
	local sinH = sin( -heading )
	local dx = ex - cx
	local dy = ey - cy
	local lx = dx * cosH - dy * sinH
	local ly = dx * sinH + dy * cosH
	local rSq = radius * radius
	for i = 1, #hull, 2 do
		local vdx = lx - hull[i]
		local vdy = ly - hull[i + 1]
		if vdx * vdx + vdy * vdy <= rSq then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------------
-- Functions

local gameLoop -- forward declaration
local newGame -- forward declaration

local function renderFrame()
	if snapshot then snapshot:invalidate() end
end

local function isAction( action )
	local keys = controlsConfig[action]
	if not keys then return false end
	for i = 1, #keys do
		if keysDown[keys[i]] then return true end
	end
	return false
end

-- Broadcast alert to all destroyers. Filtering by role happens inside each AI.
local function broadcastAlert( x, y, alerterRole )
	for i = 1, #destroyerController do
		if destroyerShip[i].isAlive then
			destroyerController[i].notifyAlert( x, y, alerterRole )
		end
	end
end

-- Spawn a static ghost outline at a ship's position when revealed by sonar.
local function spawnGhost( x, y, heading, tag )
	local color = gameConfig.colors.ghost
	local ghost = display.newPolygon( groupShips, x, y, gameConfig[tag].shape )
	ghost:setFillColor( 0, 0 )
	ghost.strokeWidth = 1
	ghost:setStrokeColor( color[1], color[2], color[3] )
	ghost.alpha = gameConfig.ping.ghostAlpha
	ghost.rotation = deg( heading )

	transition.to( ghost, {
		tag = "game",
		time = gameConfig.ping.ghostFadeOut,
		alpha = 0,
		transition = easing.outQuad,
		onComplete = function()
			display.remove( ghost )
			ghost = nil
		end,
	} )

	ghostObjects[#ghostObjects + 1] = ghost
end

-- Check torpedo against level bounds.
local function checkLevelBoundsCollision( torp )
	for i = 1, #levelBounds do
		local b = levelBounds[i]
		if torp.checkRectCollision( b.x, b.y, b.width, b.height ) then
			return true
		end
	end
	return false
end

-- Stop a ship's movement and fade it out.
local function sinkShip( ship )
	ship.isAlive = false
	ship.vx = 0
	ship.vy = 0
	transition.cancel( ship )
	ship.alpha = 1
	transition.to( ship, {
		tag = "game",
		time = 1000,
		alpha = 0,
		onComplete = function()
			display.remove( ship )
		end,
	} )
end

-- Multi-layer carrier explosion for the victory moment.
local function createCarrierExplosion( x, y )
	local config = gameConfig.carrierExplosion
	local layers = {
		{ radius = config.innerRadius, color = config.innerColor, delay = 0 },
		{ radius = config.middleRadius, color = config.middleColor, delay = config.layerDelay },
		{ radius = config.outerRadius, color = config.outerColor, delay = config.layerDelay * 2 },
	}

	for i = 1, #layers do
		local layer = layers[i]
		local c = layer.color
		local circle = display.newCircle( groupShips, x, y, layer.radius )
		circle:setFillColor( c[1], c[2], c[3] )
		circle.alpha = config.layerAlpha
		transition.to( circle, {
			tag = "game",
			delay = layer.delay,
			time = config.duration,
			xScale = config.scale,
			yScale = config.scale,
			alpha = 0,
			transition = easing.inOutBack,
			onComplete = function()
				display.remove( circle )
				circle = nil
			end,
		} )
	end
end

-- Small explosion on the submarine when destroyed.
local function createSubmarineExplosion( x, y )
	local config = gameConfig.submarineExplosion
	local color = gameConfig.colors.explosion

	local layers = {
		{ radius = config.innerRadius, delay = 0 },
		{ radius = config.outerRadius, delay = config.layerDelay },
	}

	for i = 1, #layers do
		local layer = layers[i]
		local circle = display.newCircle( groupShips, x, y, layer.radius )
		circle:toFront()
		circle:setFillColor( color[1], color[2], color[3] )
		circle.alpha = config.layerAlpha
		transition.to( circle, {
			tag = "game",
			delay = layer.delay,
			time = config.duration,
			xScale = config.scale,
			yScale = config.scale,
			alpha = 0,
			transition = easing.inOutBack,
			onComplete = function()
				display.remove( circle )
				circle = nil
			end,
		} )
	end
end


local function gameover( won, reason, hitX, hitY )
	if gameOver then return end
	if not won and gameConfig.debug.isInvulnerable then return end
	gameOver = true

	Runtime:removeEventListener( "enterFrame", gameLoop )

	local message
	if won then
		message = gameConfig.winText
	else
		message = gameConfig.loseText[reason]
	end

	local function startDeathSequence()
		if not won and playerSub and playerSub.isAlive then
			sinkShip( playerSub )
		end

		local fadeDelay = 500
		if won and carrierShip then
			sinkShip( carrierShip )
			createCarrierExplosion( carrierShip.x, carrierShip.y )
			fadeDelay = 1500
		end

		transition.to( worldGroup, {
			tag = "game",
			delay = fadeDelay,
			time = 1500,
			alpha = 0,
			onComplete = function()
				uiTextGameover.text = message
				transition.to( uiTextGameover, {
					tag = "game",
					time = 500,
					alpha = 1,
					onComplete = function()
						restartTimer = timer.performWithDelay( gameConfig.restartDelay, newGame )
					end,
				} )
			end,
		} )
	end

	if not won and reason ~= "torpedoes" and playerSub then
		createSubmarineExplosion( hitX or playerSub.x, hitY or playerSub.y )
		timer.performWithDelay( gameConfig.submarineExplosion.deathDelay, startDeathSequence )
	else
		startDeathSequence()
	end
end


local function onDepthChargeExplode( x, y )
	if gameOver then return end

	if playerSub and playerSub.isAlive then
		if explosionHitsHull( x, y, playerSub.x, playerSub.y, playerSub.getHeading(), gameConfig.submarine.outerHull, gameConfig.depthCharge.blastRadius ) then
			gameover( false, "depthCharge", x, y )
		end
	end
end


local function onTorpedoExplode( x, y )
	if gameOver then return end

	local blastRadius = gameConfig.torpedo.blastRadius
	local destroyerHull = gameConfig.destroyer.outerHull
	local carrierHull = gameConfig.carrier.outerHull

	for j = 1, #destroyerShip do
		local d = destroyerShip[j]
		if d.isAlive and explosionHitsHull( x, y, d.x, d.y, d.heading, destroyerHull, blastRadius ) then
			destroyerController[j].notifyHit()
			sinkShip( d )
			return
		end
	end

	if carrierShip.isAlive and explosionHitsHull( x, y, carrierShip.x, carrierShip.y, carrierShip.heading, carrierHull, blastRadius ) then
		carrierHitpoints = carrierHitpoints - 1
		if carrierHitpoints <= 0 then
			gameover( true )
		else
			transition.cancel( uiTextCarrierHit )
			uiTextCarrierHit.alpha = 1
			transition.to( uiTextCarrierHit, {
				tag = "game",
				delay = 1500,
				time = 1000,
				alpha = 0,
			} )
		end
	end
end

-- Translate worldGroup to follow the player, clamped to world edges.
local function updateCamera()
	local worldW = mapData.worldWidth
	local worldH = mapData.worldHeight

	worldGroup.x = clamp( -playerSub.x, screen.maxX - worldW - screen.centerX, screen.minX - screen.centerX )
	worldGroup.y = clamp( -playerSub.y, screen.maxY - worldH - screen.centerY, screen.minY - screen.centerY )
end

-- Main game loop.
gameLoop = function()
	if not playerSub then return end

	local now = system.getTimer()
	local dt = now - lastTime
	lastTime = now

	if dt > 50 then dt = 50 end

	if gameOver then return end

	local worldW = mapData.worldWidth
	local worldH = mapData.worldHeight
	local pingConfig = gameConfig.ping
	local destroyerConfig = gameConfig.destroyer

	-- Cooldowns.
	pingCooldown = pingCooldown - dt
	fireCooldown = fireCooldown - dt

	--------------------------------------------------------------------------------------
	-- 1. Player input

	local dx = 0
	local dy = 0
	if isAction( "thrustRight" ) then dx = dx + 1 end
	if isAction( "thrustLeft" ) then dx = dx - 1 end
	if isAction( "thrustDown" ) then dy = dy + 1 end
	if isAction( "thrustUp" ) then dy = dy - 1 end

	local hasInput = dx ~= 0 or dy ~= 0
	if hasInput then
		playerSub.applyHeadingThrust( atan2( dy, dx ), 1.0, dt )
	end

	-- Player's sonar ping.
	if isAction( "ping" ) and pingCooldown <= 0 then
		pingCooldown = pingConfig.cooldown
		local ping = pingSystem.emit( playerSub.x, playerSub.y, { source = "player", group = groupSub } )
		ping.ring:toBack()
		activePlayerPing = ping
		revealGroup.maskX = playerSub.x
		revealGroup.maskY = playerSub.y
		revealGroup.maskScaleX = 0.01
		revealGroup.maskScaleY = 0.01
	end

	-- Player's torpedo.
	if isAction( "fire" ) and fireCooldown <= 0 and torpedoesRemaining > 0 then
		fireCooldown = gameConfig.torpedo.cooldown
		torpedoesRemaining = torpedoesRemaining - 1
		local heading = playerSub.getHeading()
		local spawnDist = gameConfig.submarine.collisionRadius + 5
		local tx = playerSub.x + cos( heading ) * spawnDist
		local ty = playerSub.y + sin( heading ) * spawnDist
		local torp = torpedo.new( groupShips, tx, ty, heading, "player", {
			onExplode = onTorpedoExplode,
		} )
		torpedoes[#torpedoes + 1] = torp
	end

	--------------------------------------------------------------------------------------
	-- 2. Player physics

	playerSub.update( dt, worldW, worldH )

	-- Transform submarine hull to world coordinates for collision.
	local subHeading = playerSub.getHeading()
	local subHull = gameConfig.submarine.outerHull
	local cosH = cos( subHeading )
	local sinH = sin( subHeading )

	-- Terrain collision.
	for i = 1, #terrainObstacles do
		local verts = terrainObstacles[i].vertices
		for j = 1, #subHull, 2 do
			local lx = subHull[j]
			local ly = subHull[j + 1]
			local wx = playerSub.x + lx * cosH - ly * sinH
			local wy = playerSub.y + lx * sinH + ly * cosH
			if map.pointInPolygon( wx, wy, verts ) then
				gameover( false, "collision", wx, wy )
				return
			end
		end
	end

	-- Level bounds collision.
	for i = 1, #levelBounds do
		local b = levelBounds[i]
		local halfW = b.width * 0.5
		local halfH = b.height * 0.5
		for j = 1, #subHull, 2 do
			local lx = subHull[j]
			local ly = subHull[j + 1]
			local wx = playerSub.x + lx * cosH - ly * sinH
			local wy = playerSub.y + lx * sinH + ly * cosH
			if wx >= b.x - halfW and wx <= b.x + halfW and
			   wy >= b.y - halfH and wy <= b.y + halfH then
				gameover( false, "collision", wx, wy )
				return
			end
		end
	end

	--------------------------------------------------------------------------------------
	-- 3. destroyer AI + physics + outputs

	for i = 1, #destroyerShip do
		local ship = destroyerShip[i]
		local ai = destroyerController[i]
		if ship.isAlive then
			ai.update( dt )
			ship.update( dt, worldW, worldH )

			-- Sonar ping request.
			if ai.consumePingRequest() then
				local dPing = pingSystem.emit( ship.x, ship.y, {
					source = "destroyer",
					range = destroyerConfig.sonarRange,
					color = gameConfig.colors.destroyerPing,
					visualOnly = true,
					group = groupShips,
				} )

				dPing.ring:toBack()
				pingSystem.revealSingle( ship )
				spawnGhost( ship.x, ship.y, ship.heading, "destroyer" )
				destroyerPingTrackers[#destroyerPingTrackers + 1] = {
					x = ship.x,
					y = ship.y,
					radius = 0,
					maxRadius = destroyerConfig.sonarRange,
					detected = false,
					aiIndex = i,
				}
			end

			-- Depth charge request.
			local wantsDrop, dropX, dropY = ai.consumeDepthChargeRequest()
			if wantsDrop then
				local dcConfig = gameConfig.depthCharge
				local dc = depthCharge.new( groupShips, dropX, dropY, {
					onExplode = onDepthChargeExplode,
				} )

				pingSystem.registerRevealable( dc.displayObject, {
					width = dcConfig.radius * 2,
					height = dcConfig.radius * 2,
				} )
				depthCharges[#depthCharges + 1] = dc

				-- Brief visible indicator showing a depth charge was dropped.
				local dcColor = gameConfig.colors.depthCharge
				local indicator = display.newCircle( groupShips, dropX, dropY, dcConfig.indicatorRadius )
				indicator:setFillColor( dcColor[1], dcColor[2], dcColor[3] )
				transition.to( indicator, {
					tag = "game",
					time = dcConfig.indicatorFadeDuration,
					alpha = 0,
					onComplete = function()
						display.remove( indicator )
						indicator = nil
					end,
				} )
			end
		end
	end

	--------------------------------------------------------------------------------------
	-- 4. destroyer's sonar ping

	local pingSpeed = pingConfig.ringSpeed
	for i = #destroyerPingTrackers, 1, -1 do
		local tracker = destroyerPingTrackers[i]
		tracker.radius = tracker.radius + pingSpeed * dt

		if not tracker.detected then
			local d = distance( tracker.x, tracker.y, playerSub.x, playerSub.y )
			local band = pingSpeed * dt * 1.5
			if abs( d - tracker.radius ) <= band then
				tracker.detected = true
				local ai = destroyerController[tracker.aiIndex]
				local ship = destroyerShip[tracker.aiIndex]
				if ai and ship and ship.isAlive then
					ai.notifyPlayerDetected( playerSub.x, playerSub.y )
					broadcastAlert( playerSub.x, playerSub.y, ai.role )
				end
			end
		end

		if tracker.radius >= tracker.maxRadius then
			remove( destroyerPingTrackers, i )
		end
	end

	--------------------------------------------------------------------------------------
	-- 5. Update torpedoes

	local torpConfig = gameConfig.torpedo
	local carrierHull = gameConfig.carrier.outerHull
	local destroyerHull = gameConfig.destroyer.outerHull

	for i = #torpedoes, 1, -1 do
		local torp = torpedoes[i]
		torp.update( dt )

		if not torp.isAlive then
			torp.destroy()
			remove( torpedoes, i )
		elseif torp.isOutOfBounds( worldW, worldH ) then
			torp.destroy()
			remove( torpedoes, i )
		elseif not torp.hasExploded and torp.distanceTraveled > torpConfig.armingDistance then
			local detonated = false

			-- Check collision with carrier.
			if carrierShip.isAlive and pointInRotatedHull( torp.x, torp.y, carrierShip.x, carrierShip.y, carrierShip.heading, carrierHull ) then
				torp.detonate()
				detonated = true
			end

			-- Check collision with destroyers.
			if not detonated then
				for j = 1, #destroyerShip do
					local d = destroyerShip[j]
					if d.isAlive and pointInRotatedHull( torp.x, torp.y, d.x, d.y, d.heading, destroyerHull ) then
						torp.detonate()
						detonated = true
						break
					end
				end
			end

			-- Level bounds: detonate on hit.
			if not detonated and checkLevelBoundsCollision( torp ) then
				torp.detonate()
			end
		end
	end

	-- Out of torpedoes: gameover after the final torpedo detonates.
	if torpedoesRemaining <= 0 and #torpedoes == 0 then
		gameover( false, "torpedoes" )
		return
	end

	--------------------------------------------------------------------------------------
	-- 6. Depth charge collision + cleanup

	local subHullDC = gameConfig.submarine.outerHull
	local subHeadingDC = playerSub.getHeading()
	for i = #depthCharges, 1, -1 do
		local dc = depthCharges[i]
		if dc.isAlive and not dc.hasExploded then
			if pointInRotatedHull( dc.x, dc.y, playerSub.x, playerSub.y, subHeadingDC, subHullDC ) then
				dc.detonate()
			end
		end
		if not dc.isAlive then
			remove( depthCharges, i )
		end
	end

	--------------------------------------------------------------------------------------
	-- 7. HUD update

	if pingCooldown > 0 then
		local c = gameConfig.colors.hudPingCooldown
		uiTextPing.text = "PING " .. string.format( "%.1f", pingCooldown * 0.001 ) .. "S"
		uiTextPing:setFillColor( c[1], c[2], c[3] )
		uiTextPing.alpha = gameConfig.hud.pingCooldownAlpha
	else
		local c = gameConfig.colors.hudPingReady
		uiTextPing.text = "PING READY"
		uiTextPing:setFillColor( c[1], c[2], c[3] )
		uiTextPing.alpha = gameConfig.hud.pingReadyAlpha
	end

	local torpText = "TORPEDOES: " .. torpedoesRemaining .. "/" .. gameConfig.torpedo.maxTorpedoes
	if fireCooldown > 0 then
		local c = gameConfig.colors.hudPingCooldown
		uiTextTorpedo.text = torpText .. " " .. string.format( "%.1f", fireCooldown * 0.001 ) .. "S"
		uiTextTorpedo:setFillColor( c[1], c[2], c[3] )
		uiTextTorpedo.alpha = gameConfig.hud.pingCooldownAlpha
	else
		local c = gameConfig.colors.hudPingReady
		uiTextTorpedo.text = torpText
		uiTextTorpedo:setFillColor( c[1], c[2], c[3] )
		uiTextTorpedo.alpha = gameConfig.hud.pingReadyAlpha
	end

	if carrierDirArrow.alpha > 0 and carrierShip and carrierShip.isAlive then
		carrierDirArrow.rotation = deg( atan2( carrierShip.y - playerSub.y, carrierShip.x - playerSub.x ) )
	end

	--------------------------------------------------------------------------------------
	-- 8. Sonar mask

	if activePlayerPing then
		if activePlayerPing.ring then
			local scale = activePlayerPing.radius / 64
			if scale < 0.01 then scale = 0.01 end
			revealGroup.maskScaleX = scale
			revealGroup.maskScaleY = scale
		else
			activePlayerPing = nil
		end
	end

	--------------------------------------------------------------------------------------
	-- 9. Camera

	updateCamera()
end


function newGame()
	-- Cancel active transitions and timers.
	transition.cancel( "game" )
	if restartTimer then
		timer.cancel( restartTimer )
		restartTimer = nil
	end
	if blinkTimer then
		timer.cancel( blinkTimer )
		blinkTimer = nil
	end
	if startDelayTimer then
		timer.cancel( startDelayTimer )
		startDelayTimer = nil
	end
	if carrierDirTimer then
		timer.cancel( carrierDirTimer )
		carrierDirTimer = nil
	end

	Runtime:removeEventListener( "enterFrame", gameLoop )

	-- Clean up previous round projectiles.
	if torpedoes then
		for i = 1, #torpedoes do
			torpedoes[i].destroy()
		end
	end
	if depthCharges then
		for i = 1, #depthCharges do
			depthCharges[i].destroy()
		end
	end

	-- Destroy old ping system.
	if pingSystem then
		pingSystem.destroy()
	end

	-- Clear ship display groups.
	while groupSub.numChildren > 0 do
		display.remove( groupSub[groupSub.numChildren] )
	end
	while groupShips.numChildren > 0 do
		display.remove( groupShips[groupShips.numChildren] )
	end

	-- Create new ping system and re-register terrain.
	pingSystem = sonar.new( worldGroup )

	for i = 1, #terrainDisplayObjects do
		pingSystem.registerRevealable( terrainDisplayObjects[i], { width = terrainObstacles[i].width, height = terrainObstacles[i].height } )
	end
	for i = 1, #wallDisplayObjects do
		pingSystem.registerRevealable( wallDisplayObjects[i], { width = levelBounds[i].width, height = levelBounds[i].height } )
	end

	-- Reset game state.
	torpedoes = {}
	depthCharges = {}
	destroyerPingTrackers = {}
	ghostObjects = {}
	destroyerShip = {}
	destroyerController = {}
	keysDown = {}
	pingCooldown = 0
	fireCooldown = 0
	torpedoesRemaining = gameConfig.torpedo.maxTorpedoes
	gameOver = false

	local colors = gameConfig.colors
	local destroyerConfig = gameConfig.destroyer

	-- Spawn player.
	local spawn = mapData.spawnPoints[math.random( #mapData.spawnPoints )]
	playerSub = submarine.new( groupSub, {
		isPlayer = true,
		heading = 0,
		color = colors.playerSub,
	} )
	playerSub.x = spawn.x
	playerSub.y = spawn.y

	-- Spawn carrier.
	local route = mapData.carrierRoutes[math.random( #mapData.carrierRoutes )]
	local startIdx = math.random( #route )
	local carrierDirection = math.random( 2 ) == 1 and 1 or -1

	carrierShip = carrier.new( groupShips, {
		color = colors.carrier,
	} )
	carrierShip.x = route[startIdx].x
	carrierShip.y = route[startIdx].y

	pingSystem.registerRevealable( carrierShip, { isGhostable = true, tag = "carrier" } )

	carrierController = carrierAI.new( {
		ship = carrierShip,
		waypoints = route,
		startIndex = startIdx,
		direction = carrierDirection,
	} )

	if gameConfig.debug.showCarrierPath then
		for i = 1, #route do
			local j = i % #route + 1
			local line = display.newLine( groupShips, route[i].x, route[i].y, route[j].x, route[j].y )
			line.strokeWidth = 1
		end
	end

	-- Spawn patrol destroyers.
	local patrolWP = mapData.patrolWaypoints
	local minSpawnDist = destroyerConfig.minimumSpawnDistance
	for i = 1, destroyerConfig.patrolCount do
		local wpIndex = ( ( i - 1 ) * 3 ) % #patrolWP + 1
		local spawnWP = patrolWP[wpIndex]
		local sx, sy = spawnWP.x, spawnWP.y

		local dist = distance( sx, sy, playerSub.x, playerSub.y )
		if dist < minSpawnDist and dist > 0 then
			local dx = sx - playerSub.x
			local dy = sy - playerSub.y
			sx = playerSub.x + dx / dist * minSpawnDist
			sy = playerSub.y + dy / dist * minSpawnDist
		end

		local ship = destroyer.new( groupShips, {
			heading = math.random() * pi * 2,
			color = colors.destroyer,
		} )
		ship.x = sx
		ship.y = sy

		pingSystem.registerRevealable( ship, { isGhostable = true, tag = "destroyer" } )

		local ai = destroyerAI.new( {
			ship = ship,
			role = "patrol",
			waypoints = patrolWP,
			config = destroyerConfig,
			allShips = destroyerShip,
		} )

		destroyerShip[#destroyerShip + 1] = ship
		destroyerController[#destroyerController + 1] = ai
	end

	-- Spawn escort destroyers.
	local escortAngles = { pi * 0.75, -pi * 0.75, pi * 0.5, -pi * 0.5 }
	for i = 1, destroyerConfig.escortCount do
		local angle = escortAngles[i] or ( pi * ( i / destroyerConfig.escortCount ) )
		local carrierHeading = carrierShip.heading
		local spawnAngle = carrierHeading + angle
		local spawnX = carrierShip.x + cos( spawnAngle ) * destroyerConfig.escortRadius
		local spawnY = carrierShip.y + sin( spawnAngle ) * destroyerConfig.escortRadius

		local ship = destroyer.new( groupShips, {
			heading = carrierHeading,
			color = colors.destroyer,
		} )
		ship.x = spawnX
		ship.y = spawnY

		pingSystem.registerRevealable( ship, { isGhostable = true, tag = "destroyer" } )

		local ai = destroyerAI.new( {
			ship = ship,
			role = "escort",
			waypoints = patrolWP,
			carrier = carrierShip,
			config = destroyerConfig,
			escortAngle = angle,
			allShips = destroyerShip,
		} )

		destroyerShip[#destroyerShip + 1] = ship
		destroyerController[#destroyerController + 1] = ai
	end

	-- Sonar reveal callback.
	pingSystem.onReveal = function( entry, ping )
		if ping.source == "player" and entry.tag == "destroyer" then
			for i = 1, #destroyerShip do
				if destroyerShip[i] == entry.object and destroyerShip[i].isAlive then
					destroyerController[i].notifyPlayerDetected( ping.x, ping.y )
					broadcastAlert( ping.x, ping.y, destroyerController[i].role )
					break
				end
			end
		end

		if entry.tag == "destroyer" or entry.tag == "carrier" then
			local obj = entry.object
			if obj and obj.isAlive then
				spawnGhost( obj.x, obj.y, obj.heading, entry.tag )
			end
		end
	end

	-- Reset display state.
	worldGroup.alpha = 1
	activePlayerPing = nil
	revealGroup.maskScaleX = 0.01
	revealGroup.maskScaleY = 0.01

	if gameConfig.debug.revealAll then
		pingSystem.setRevealAll( true )
		revealGroup.maskScaleX = 100
		revealGroup.maskScaleY = 100
	end
	uiTextGameover.alpha = 0
	uiTextGameover.text = ""
	carrierHitpoints = gameConfig.carrier.hitpoints
	transition.cancel( uiTextCarrierHit )
	uiTextCarrierHit.alpha = 0
	uiTextCarrierDir.alpha = 0
	uiTextCarrierDir.text = ""
	carrierDirArrow.alpha = 0

	local c = colors.hudPingReady
	uiTextPing.text = "PING READY"
	uiTextPing:setFillColor( c[1], c[2], c[3] )
	uiTextPing.alpha = gameConfig.hud.pingReadyAlpha
	uiTextTorpedo.text = "TORPEDOES: " .. torpedoesRemaining .. "/" .. gameConfig.torpedo.maxTorpedoes

	updateCamera()

	-- Show title screen.
	titleGroup.isVisible = true
	titleStartText.isVisible = false
	waitingToStart = true
	readyToStart = false

	local titleConfig = gameConfig.titleScreen
	startDelayTimer = timer.performWithDelay( titleConfig.startDelay, function()
		readyToStart = true
		titleStartText.isVisible = true
		blinkTimer = timer.performWithDelay( titleConfig.blinkInterval, function()
			titleStartText.isVisible = not titleStartText.isVisible
		end, 0 )
	end )
end


local function startGame()
	waitingToStart = false

	if blinkTimer then
		timer.cancel( blinkTimer )
		blinkTimer = nil
	end
	if startDelayTimer then
		timer.cancel( startDelayTimer )
		startDelayTimer = nil
	end

	titleGroup.isVisible = false
	keysDown = {}
	lastTime = system.getTimer()
	carrierController.start()
	Runtime:addEventListener( "enterFrame", gameLoop )

	local indicatorConfig = gameConfig.carrierIndicator
	carrierDirTimer = timer.performWithDelay( indicatorConfig.showDelay, function()
		if not carrierShip or not carrierShip.isAlive then return end

		local cdx = carrierShip.x - playerSub.x
		local cdy = carrierShip.y - playerSub.y
		local where = angleToCompass( atan2( cdy, cdx ) )
		local heading = angleToCompass( carrierShip.heading )

		uiTextCarrierDir.text = "The Red April was last seen to the " .. where .. ",\nheading " .. heading .. "."
		uiTextCarrierDir.alpha = 1
		carrierDirArrow.alpha = 1
		carrierDirArrow.rotation = deg( atan2( cdy, cdx ) )

		carrierDirTimer = timer.performWithDelay( indicatorConfig.displayDuration, function()
			transition.to( uiTextCarrierDir, {
				tag = "game",
				time = indicatorConfig.fadeOutDuration,
				alpha = 0,
			} )
			transition.to( carrierDirArrow, {
				tag = "game",
				time = indicatorConfig.fadeOutDuration,
				alpha = 0,
			} )
			carrierDirTimer = nil
		end )
	end )

	pingCooldown = gameConfig.ping.cooldown
	local ping = pingSystem.emit( playerSub.x, playerSub.y, { source = "player", group = groupSub } )
	ping.ring:toBack()
	activePlayerPing = ping
	revealGroup.maskX = playerSub.x
	revealGroup.maskY = playerSub.y
	revealGroup.maskScaleX = 0.01
	revealGroup.maskScaleY = 0.01
end


local function onKeyEvent( event )
	if event.phase == "down" then
		if waitingToStart and readyToStart and event.keyName == "space" then
			startGame()
			return true
		end
		keysDown[event.keyName] = true
	elseif event.phase == "up" then
		keysDown[event.keyName] = nil
	end
	return true
end

--------------------------------------------------------------------------------------
-- Scene functions

function scene:create( event )
	local sceneGroup = self.view

	if composer._previousScene == "scenes.launchScreen" then
		composer.removeScene( "scenes.launchScreen" )
	end

	mapData = map.load( "data/maps/map.tmj" )

	local colors = gameConfig.colors
	local terrainColor = colors.terrain

	--------------------------------------------------------------------------------------
	-- CRT snapshot

	snapshot = display.newSnapshot( sceneGroup, screen.width, screen.height )
	snapshot.x = screen.centerX
	snapshot.y = screen.centerY

	if not gameConfig.debug.disableShader then
		crtShader.define()
		local crt = gameConfig.crt
		snapshot.fill.effect = "filter.custom.crt"
		snapshot.fill.effect.scanlineIntensity = crt.scanlineIntensity
		snapshot.fill.effect.scanlineCount = crt.scanlineCount
		snapshot.fill.effect.distortion = { crt.curvature, crt.vignette }
		snapshot.fill.effect.roll = { crt.humBarStrength, crt.humBarSpeed }
	end

	--------------------------------------------------------------------------------------
	-- World group

	worldGroup = display.newGroup()
	snapshot.group:insert( worldGroup )

	groupSub = display.newGroup()
	worldGroup:insert( groupSub )

	revealGroup = display.newGroup()
	worldGroup:insert( revealGroup )

	groupTerrain = display.newGroup()
	revealGroup:insert( groupTerrain )

	local mask = graphics.newMask( "assets/images/mask.png" )
	revealGroup:setMask( mask )

	groupShips = display.newGroup()
	worldGroup:insert( groupShips )
	revealGroup.maskScaleX = 0.01
	revealGroup.maskScaleY = 0.01

	--------------------------------------------------------------------------------------
	-- Terrain

	terrainObstacles = {}
	terrainDisplayObjects = {}
	levelBounds = {}
	wallDisplayObjects = {}

	for i = 1, #mapData.terrain do
		local t = mapData.terrain[i]
		local obj = display.newPolygon( groupTerrain, t.centerX, t.centerY, t.flatVertices )
		obj:setFillColor( 0 )
		obj.strokeWidth = 4
		obj:setStrokeColor( terrainColor[1], terrainColor[2], terrainColor[3] )
		terrainObstacles[#terrainObstacles + 1] = t
		terrainDisplayObjects[#terrainDisplayObjects + 1] = obj
	end

	for i = 1, #mapData.walls do
		local w = mapData.walls[i]
		local obj = display.newRect( groupTerrain, w.x, w.y, w.width, w.height )
		obj:setFillColor( 0 )
		obj.strokeWidth = 2
		obj:setStrokeColor( terrainColor[1], terrainColor[2], terrainColor[3] )
		levelBounds[#levelBounds + 1] = w
		wallDisplayObjects[#wallDisplayObjects + 1] = obj
	end

	--------------------------------------------------------------------------------------
	-- HUD

	groupUI = display.newGroup()
	snapshot.group:insert( groupUI )

	local hudConfig = gameConfig.hud
	local hudColor = colors.hudText

	local hudX = screen.minX + hudConfig.margin - screen.centerX
	local hudBottomY = screen.maxY - hudConfig.margin - screen.centerY

	uiTextTorpedo = display.newText( {
		parent = groupUI,
		text = "",
		x = hudX,
		y = hudBottomY,
		font = hudConfig.font,
		fontSize = hudConfig.fontSize,
	} )
	uiTextTorpedo.anchorX = 0
	uiTextTorpedo.anchorY = 1
	uiTextTorpedo:setFillColor( hudColor[1], hudColor[2], hudColor[3] )

	uiTextPing = display.newText( {
		parent = groupUI,
		text = "",
		x = hudX,
		y = hudBottomY - hudConfig.fontSize - 4,
		font = hudConfig.font,
		fontSize = hudConfig.fontSize,
		align = "left",
	} )
	uiTextPing.anchorX = 0
	uiTextPing.anchorY = 1
	uiTextPing:setFillColor( hudColor[1], hudColor[2], hudColor[3] )

	uiTextGameover = display.newText( {
		parent = groupUI,
		text = "",
		x = 0,
		y = 0,
		font = hudConfig.font,
		fontSize = hudConfig.gameOverFontSize,
	} )
	uiTextGameover.alpha = 0

	local carrierHitColor = colors.carrier
	local hudTopY = screen.minY + hudConfig.margin - screen.centerY
	uiTextCarrierHit = display.newText( {
		parent = groupUI,
		text = "The Red April has been hit!",
		x = 0,
		y = hudTopY,
		font = hudConfig.font,
		fontSize = 24,
	} )
	uiTextCarrierHit.anchorY = 0
	uiTextCarrierHit:setFillColor( carrierHitColor[1], carrierHitColor[2], carrierHitColor[3] )
	uiTextCarrierHit.alpha = 0

	local dirTextY = ( screen.minY - screen.centerY ) * 0.5
	local indicatorFontSize = gameConfig.carrierIndicator.fontSize
	uiTextCarrierDir = display.newText( {
		parent = groupUI,
		text = "",
		x = 0,
		y = dirTextY,
		font = hudConfig.font,
		fontSize = indicatorFontSize,
		align = "center",
	} )
	uiTextCarrierDir:setFillColor( carrierHitColor[1], carrierHitColor[2], carrierHitColor[3] )
	uiTextCarrierDir.alpha = 0

	carrierDirArrow = display.newImageRect( groupUI, "assets/images/direction.png", 32, 16 )
	carrierDirArrow.x = 0
	carrierDirArrow.y = uiTextCarrierDir.y + uiTextCarrierDir.height * 0.5 + carrierDirArrow.height * 0.5 + 26
	carrierDirArrow.alpha = 0
	carrierDirArrow:setFillColor( carrierHitColor[1], carrierHitColor[2], carrierHitColor[3] )

	--------------------------------------------------------------------------------------
	-- Title screen

	titleGroup = display.newGroup()
	snapshot.group:insert( titleGroup )

	--------------------------------------------------------------------------------------
	-- Title screen

	local titleText = display.newText( {
		parent = titleGroup,
		text = "The Hunt for Red April",
		x = 0,
		y = -200,
		font = hudConfig.font,
		fontSize = 50,
		align = "center",
	} )
	titleText:setFillColor( 1, 0, 0 )

	local subtitleObj = display.newText( {
		parent = titleGroup,
		text = "LD59 compo entry by Eetu Rantanen",
		x = 0,
		y = -140,
		font = hudConfig.font,
		fontSize = 24,
		align = "center",
	} )
	subtitleObj:setFillColor( 1, 1, 0 )

	local instructionsObj = display.newText( {
		parent = titleGroup,
		text = "Navigate by sonar. Sink the carrier. Evade the destroyers.\n\nWASD/arrows: Move | Space: Ping sonar | Shift: Fire torpedo",
		x = 0,
		y = 60,
		font = hudConfig.font,
		fontSize = 20,
		width = 600,
		align = "center",
	} )
	instructionsObj.anchorY = 0
	instructionsObj:setFillColor( 1 )

	titleStartText = display.newText( {
		parent = titleGroup,
		text = "Press Space to Start",
		x = 0,
		y = instructionsObj.y + instructionsObj.height + 40,
		font = hudConfig.font,
		fontSize = 24,
	} )
	titleStartText.anchorY = 0
	titleStartText:setFillColor( 0, 1, 0 )
	titleStartText.isVisible = false

	titleGroup.isVisible = false

	--------------------------------------------------------------------------------------
	-- Persistent listeners

	Runtime:addEventListener( "enterFrame", renderFrame )
	Runtime:addEventListener( "key", onKeyEvent )
end

function scene:show( event )
	if event.phase == "will" then
		newGame()
	end
end

--------------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

return scene
