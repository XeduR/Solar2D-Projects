-- Game-wide tuning constants for The Hunt for Red April.

local gameConfig = {}

--------------------------------------------------------------------------------------
-- Submarine physics

gameConfig.submarine = {
	maxSpeed = 0.12, -- px/ms
	turnRate = 0.0008, -- rad/ms
	drag = 0.995, -- velocity multiplier per frame (1 = no drag)
	collisionRadius = 14,
	shape = {
		26, -4,
		28, -1,
		28, 1,
		26, 4,
		20, 6,
		-14, 6,
		-22, 4,
		-26, 2,
		-26, 5,
		-28, 5,
		-28, -5,
		-26, -5,
		-26, -2,
		-22, -4,
		-14, -6,
		20, -6,
	},
	outerHull = {
		26, -4,
		28, -1,
		28, 1,
		26, 4,
		20, 6,
		-14, 6,
		-28, 5,
		-28, -5,
		-14, -6,
		20, -6,
	},
}

--------------------------------------------------------------------------------------
-- Carrier

gameConfig.carrier = {
	maxSpeed = 0.05, -- px/ms
	drag = 0.98,
	collisionRadius = 30,
	hitpoints = 2,
	minimumSpawnDistance = 600, -- carrier won't spawn closer than this to the player
	shape = {
		69, -16,
		76, -6,
		71, 6,
		34, 11,
		-4, 21,
		-48, 21,
		-69, 14,
		-76, 6,
		-76, -19,
		-69, -21,
		34, -21,
	},
	outerHull = {
		76, -6,
		69, -16,
		34, -21,
		-69, -21,
		-76, -19,
		-76, 6,
		-69, 14,
		-48, 21,
		-4, 21,
		71, 6,
	},
}

--------------------------------------------------------------------------------------
-- Destroyer

gameConfig.destroyer = {
	maxSpeed = 0.2, -- px/ms
	turnRate = 0.001, -- rad/ms
	drag = 0.97,
	collisionRadius = 16,
	patrolCount = 3,
	escortCount = 2,
	sonarCooldownMin = 4000, -- ms between pings (lower bound)
	sonarCooldownMax = 6500, -- ms between pings (upper bound)
	sonarRange = 250, -- much smaller than player's 600
	chaseDurationPatrol = 15000, -- ms before patrol gives up chase
	chaseDurationEscort = 10000, -- ms before escort gives up chase
	depthChargeCooldown = 3000, -- ms
	depthChargeDropRange = 150, -- only drops when within this range of target
	depthChargeCount = 3, -- charges per burst
	depthChargeDelay = 300, -- ms between charges in a burst
	predictionFactor = 0.5, -- how far ahead to predict player position
	chaseSpreadRadius = 100, -- random offset for non-lead chasers
	escortRadius = 120, -- orbit distance from carrier
	escortLeashRadius = 400, -- max distance from carrier before escort aborts chase
	separationRadius = 80, -- destroyers steer away from each other within this range
	minimumSpawnDistance = 400, -- patrol destroyers won't spawn closer than this to the player
	shape = {
		41, 0,
		35, -5,
		20, -7,
		-10, -9,
		-31, -6,
		-41, -5,
		-41, 5,
		-31, 6,
		-10, 9,
		20, 7,
		35, 5,
	},
	outerHull = {
		41, 0,
		35, -5,
		20, -7,
		-10, -9,
		-41, -5,
		-41, 5,
		-10, 9,
		20, 7,
		35, 5,
	},
}

--------------------------------------------------------------------------------------
-- Patrol boat

gameConfig.patrol = {
	maxSpeed = 0.28, -- px/ms, much faster than destroyer
	turnRate = 0.002, -- rad/ms, more agile than destroyer
	drag = 0.97,
	collisionRadius = 10,
	patrolCount = 2,
	escortCount = 1,
	chaseDurationPatrol = 12000, -- ms before patrol gives up chase
	chaseDurationEscort = 8000, -- ms before escort gives up chase
	depthChargeCooldown = 4000, -- ms
	depthChargeDropRange = 120, -- only drops when within this range of target
	predictionFactor = 1.5, -- higher than destroyer to get ahead of player
	leadDistance = 100, -- extra distance ahead of predicted position
	chaseSpreadRadius = 60, -- random offset for non-lead chasers
	escortRadius = 160, -- orbit distance from carrier
	escortLeashRadius = 500, -- max distance from carrier before escort aborts chase
	separationRadius = 60, -- patrol boats steer away from each other within this range
	minimumSpawnDistance = 500, -- patrol boats won't spawn closer than this to the player
	shape = {
		20, 0,
		17, -3,
		10, -4,
		-5, -5,
		-16, -3,
		-20, -2,
		-20, 2,
		-16, 3,
		-5, 5,
		10, 4,
		17, 3,
	},
	outerHull = {
		20, 0,
		17, -3,
		10, -4,
		-5, -5,
		-20, -2,
		-20, 2,
		-5, 5,
		10, 4,
		17, 3,
	},
}

--------------------------------------------------------------------------------------
-- Depth charge

gameConfig.depthCharge = {
	radius = 4, -- visual circle size
	fillAlpha = 0.8,
	strokeWidth = 1,
	blastRadius = 60,
	fuseDuration = 2000, -- ms before auto-detonation
	explosionDuration = 400, -- ms, inOutBack scale transition
	explosionScale = 1.3, -- visual overshoot beyond blastRadius
	explosionAlpha = 0.8,
	indicatorRadius = 2,
	indicatorFadeDuration = 800, -- ms, fade out of drop indicator
}

--------------------------------------------------------------------------------------
-- Ping

gameConfig.ping = {
	ringSpeed = 0.4, -- px/ms
	ringMaxRadius = 400,
	ringThickness = 4,
	ringStartAlpha = 0.8,
	revealFadeIn = 100, -- ms
	revealHold = 200, -- ms
	revealFadeOut = 1500, -- ms
	ghostFadeOut = 2500, -- ms
	cooldown = 2000, -- ms between player pings
	ghostAlpha = 0.5,
}

--------------------------------------------------------------------------------------
-- Torpedo

gameConfig.torpedo = {
	speed = 0.25, -- px/ms
	maxTorpedoes = 8,
	collisionRadius = 6,
	cooldown = 8000, -- ms between shots
	trailLength = 12,
	trailAlpha = 1,
	trailStrokeWidth = 4,
	armingDistance = 30,
	fuseDuration = 1500, -- ms before auto-detonation
	blastRadius = 30,
	explosionDuration = 400,
	explosionScale = 1.3,
	explosionAlpha = 0.8,
}

--------------------------------------------------------------------------------------
-- Carrier explosion (victory effect)

gameConfig.carrierExplosion = {
	innerRadius = 30,
	middleRadius = 60,
	outerRadius = 100,
	innerColor = { 1, 1, 0.9 },
	middleColor = { 1, 0.8, 0.3 },
	outerColor = { 1, 0.3, 0.1 },
	layerDelay = 80,
	layerAlpha = 0.9,
	duration = 800,
	scale = 1.5,
}

--------------------------------------------------------------------------------------
-- Submarine explosion (death effect)

gameConfig.submarineExplosion = {
	innerRadius = 12,
	outerRadius = 25,
	layerDelay = 60,
	layerAlpha = 0.9,
	duration = 600,
	scale = 1.3,
	deathDelay = 400, -- ms before death sequence starts after explosion
}

--------------------------------------------------------------------------------------
-- Colors (normalised RGB)

gameConfig.colors = {
	playerPing = { 0.3, 1.0, 0.7 },
	destroyerPing = { 1.0, 0.4, 0.3 },
	playerSub = { 0.4, 0.9, 0.6 },
	carrier = { 1.0, 0, 0 },
	destroyer = { 1.0, 0.3, 0 },
	patrol = { 1.0, 0.3, 0 },
	terrainFill = { 0.025, 0.06, 0.05 },
	terrainStroke = { 0.25, 0.6, 0.5 },
	levelBounds = { 0.5, 0, 0 },
	torpedo = { 0.9, 0.9, 0.5 },
	ghost = { 1.0, 0.3, 0 },
	depthCharge = { 1.0, 0.6, 0.2 },
	explosion = { 1.0, 0.8, 0.3 },
	hudReady = { 0, 0.8, 0 },
	hudCooldown = { 0.8, 0, 0 },
	backgroundGradientTop = { 0, 0.05, 0 },
	backgroundGradientBottom = { 0, 0.02, 0 },
}

--------------------------------------------------------------------------------------
-- HUD

gameConfig.hud = {
	fontRegular = "assets/fonts/Cascadia_Code/CascadiaCode-Regular.ttf",
	fontBold = "assets/fonts/Cascadia_Code/CascadiaCode-Bold.ttf",
	fontSize = 24,
	gameOverFontSize = 36,
	margin = 12,
	pingReadyAlpha = 1,
	pingCooldownAlpha = 1,
}

--------------------------------------------------------------------------------------
-- CRT shader

gameConfig.crt = {
	scanlineIntensity = 0.6,
	scanlineCount = 320,
	curvature = 0.05,
	vignette = 0.5,
	humBarStrength = 0.7,
	humBarSpeed = 0.25,
}

--------------------------------------------------------------------------------------
-- Game flow

gameConfig.restartDelay = 2500 -- ms before restarting after win/lose
gameConfig.winText = "The Red April has been sunk!"
gameConfig.loseText = {
	depthCharge = "You were destroyed by a depth charge.",
	collisionTerrain = "You crashed into terrain and sank.",
	collisionBounds = "You were blown up for leaving the mission area.",
	torpedoes = "You're out of torpedoes."
}

--------------------------------------------------------------------------------------
-- Carrier direction indicator (game start)

gameConfig.carrierIndicator = {
	showDelay = 500, -- ms after game start before showing
	displayDuration = 5000, -- ms the indicator stays visible
	fadeOutDuration = 1000, -- ms for fade out
	fontSize = 24,
}

--------------------------------------------------------------------------------------
-- Title screen

gameConfig.titleScreen = {
	startDelay = 500,
	blinkInterval = 1200,
}

--------------------------------------------------------------------------------------
-- Debug

--------------------------------------------------------------------------------------
-- Audio

gameConfig.audio = {
	masterVolume = 0.45,
	distanceMin = 150, -- full volume at or below this range
	distanceMax = 650, -- silent at or beyond this range
	distanceClose = 200, -- threshold for near/far sound variant
}

--------------------------------------------------------------------------------------
-- Debug

gameConfig.debug = {
	-- NB!  The game "stops" on terrain collisions, so camera and AI freeze
	--		when inside terrain, even if isInvulnerable has been turned on.
	-- isInvulnerable = true,
	-- showCarrierPath = true,
	-- disableShader = true,
	-- revealAll = true,
}

return gameConfig
