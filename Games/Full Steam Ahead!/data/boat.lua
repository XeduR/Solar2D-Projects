-- Positions are boat units with the waterline at y = 0 and the bow facing right; pivots are art pixels from a frame's top-left corner.
return {
	family = "boat",

	-- Body centre used for the captain anchor once the boat is tiny, and for the collision circle.
	centre = { x = 0, y = -50 },

	collisionRadius = 16,

	-- Smallest particle scale, since display objects cannot be scaled to zero.
	particleMinScale = 0.01,

	body = {
		name = "boat",
		pivot = { 51, 74 },
	},

	chimney = {
		x = -54,
		topY = -219,
	},

	chimneyFlame = {
		family = "effects",
		name = "flamesChimney",
		tag = "chimney",
		pivot = { 7.5, 30 },

		-- Fire level where chimney smoke starts turning into flames, and the span over which it completes.
		start = 0.75,
		range = 0.15,

		-- Height scale as the flame first appears; it reaches full height as the flame completes.
		minHeight = 0.6,

		-- Backward lean in degrees at full speed.
		lean = 35,

		-- Share of the smoke that a full chimney flame replaces.
		smokeCut = 0.8,
	},

	paddleWheel = {
		name = "wheel",
		x = -178,
		y = -18,
		pivot = { 21.5, 21.5 },

		-- Spin rate in degrees per second; the running spin is replaced only once the target rate moves spinStep away from it.
		spinIdle = 18.75,
		spinMax = 300,
		spinStep = 15,

		-- Circle over the wheel that fades in with speed to suggest motion blur.
		blurRadius = 58,
		blurColour = { 0.925, 0.898, 0.816 },
		blurAlpha = 0.3,
	},

	captain = {
		name = "captain",
		tags = { "idle", "shout", "angry" },
		startTag = "idle",
		x = 112,
		y = -34,
		pivot = { 10, 24 },

		-- Face height above his feet, where the speech bubble points.
		headY = -51,

		-- Below this boat scale the captain is too small to anchor a bubble on.
		minScale = 0.3,

		-- Rotations in degrees: leanMax backwards at full speed, swayAmount for the constant rocking.
		leanMax = 14,
		swaySpeed = 2,
		swayAmount = 1.5,
	},

	cometGlow = {
		x = 0,
		y = -50,
		layers = {
			{ radius = 300, colour = { 1, 0.459, 0.078 }, alpha = 0.18 },
			{ radius = 200, colour = { 1, 0.698, 0.251 }, alpha = 0.32 },
			{ radius = 120, colour = { 1, 0.949, 0.651 }, alpha = 0.55 },
		},

		-- The glow's size pulses by pulseAmount either way.
		pulseSpeed = 13,
		pulseAmount = 0.08,
	},

	float = {
		bobSpeed = 1.6,
		bobAmount = 4,

		-- Share of the bobbing and rocking that calms down at full speed.
		bobCalm = 0.5,

		-- Rocking in degrees, at this fraction of the bob speed.
		tiltAmount = 1.4,
		tiltSpeedRatio = 0.7,

		-- Degrees the bow lifts at full speed.
		pitchUp = 4,

		-- The full-speed engine shake multiplies two sines at these speeds.
		shakeSpeedA = 37,
		shakeSpeedB = 23,
		shakeAmount = 2.5,
	},

	-- Phase 2 flight: vertical accelerations in units per second squared, thrust upwards and gravity downwards.
	space = {
		thrust = 1500,
		gravity = 950,
		maxSpeed = 520,

		-- Nose tilt in degrees at maxSpeed, and how quickly the boat turns towards it.
		tiltMax = 22,
		tiltResponse = 10,
	},

	-- Particle speeds are content units at boat scale 1, trail values content units at any scale.
	-- Each particle steps once through its tag's frames over its life; scale multiplies the art size.
	smoke = {
		count = 46,
		family = "effects",
		name = "smoke",
		tags = { "light", "dark" },

		-- The fire level is the chance that a puff is dark.
		lightTag = "light",
		darkTag = "dark",

		life = { 1.6, 2.4 },
		scaleStart = 1,
		scaleEnd = 1.75,
		alpha = 0.75,

		-- Alpha follows the remaining share of life raised to this power, so higher values fade out sooner.
		fadePower = 1.3,
		gravity = -10,

		-- Share of the sideways speed lost per second.
		drag = 0.4,

		-- Particles per second, plus ratePerSpeed more at full speed.
		rate = 8,
		ratePerSpeed = 30,
		x = -54,
		y = -222,
		jitter = 6,
		rise = { 50, 90 },
		drift = { 10, 30 },

		-- Share of the scenery scroll speed the particles are carried back with.
		scrollFactor = 0.8,
	},

	flames = {
		count = 40,
		family = "effects",
		name = "trail",
		tags = { "flame" },
		life = { 0.25, 0.5 },
		scaleStart = 0.7,
		scaleEnd = 0.35,
		alpha = 0.95,
		fadePower = 1,
		gravity = 0,
		drag = 0,
		rate = 60,
		x = -54,
		y = -230,
		jitter = 8,
		rise = { 200, 380 },
		spread = { -40, 40 },
		scrollFactor = 0.5,
	},

	wake = {
		count = 50,
		family = "effects",
		name = "particles",
		tags = { "wake" },
		life = { 0.8, 1.6 },
		scaleStart = 1,
		scaleEnd = 2,
		alpha = 0.8,
		fadePower = 1.2,
		gravity = 0,
		drag = 0,
		rate = 10,
		ratePerSpeed = 50,
		sourceX = { -225, -135 },
		offsetY = { -2, 6 },
		drift = { 10, 40 },
		scrollFactor = 1,
	},

	-- Drops thrown up from the bow and the paddle wheel, alternately.
	spray = {
		count = 60,
		family = "effects",
		name = "particles",
		tags = { "drop" },
		life = { 0.5, 1 },
		scaleStart = 1,
		scaleEnd = 1,
		alpha = 0.9,
		fadePower = 1,
		gravity = 700,
		drag = 0,

		-- The rate grows with the speed level raised to speedPower, so there is little spray at low speed.
		ratePerSpeed = 90,
		speedPower = 1.5,
		bowX = 176,
		bowY = -4,
		bowVelocityX = { -40, 120 },
		bowVelocityY = { -260, -120 },
		wheelX = -212,
		wheelY = -30,
		wheelVelocityX = { -260, -80 },
		wheelVelocityY = { -220, -80 },
		scrollFactor = 0.3,

		-- Launch velocities are multiplied by speedBoost plus the speed level.
		speedBoost = 0.5,
	},

	trail = {
		count = 90,
		family = "effects",
		name = "trail",
		tags = { "trail" },
		life = { 0.45, 0.85 },
		scaleStart = 0.85,
		scaleEnd = 0.4,
		alpha = 0.95,
		fadePower = 1,
		gravity = 0,
		drag = 0,
		rate = 70,

		-- Rate multiplier while thrusting in phase 2.
		thrustBoost = 1.6,
		x = -100,
		y = -40,
		jitter = 40,
		speed = { 120, 260 },
		spread = { -50, 50 },

		-- Share of the boat's vertical speed the trail moves against.
		climbInfluence = 0.3,
		scrollFactor = 0.6,
	},

	-- The spark frames are pale, so a tint shifts them from colourStart to colourEnd over their life.
	sparks = {
		count = 30,
		family = "effects",
		name = "particles",
		tags = { "spark" },
		life = { 0.4, 0.9 },
		scaleStart = 1.5,
		scaleEnd = 0.5,
		alpha = 1,
		fadePower = 1,
		gravity = 0,
		drag = 1.5,
		colourStart = { 1, 0.949, 0.651 },
		colourEnd = { 0.851, 0.102, 0.02 },
	},

	-- Blobs come from the trail pool and sparks from the sparks pool; size scales the blobs.
	explosion = {
		blobCount = 30,
		sparkCount = 30,
		speed = { 80, 360 },
		sparkSpeed = { 160, 520 },
		size = { 0.8, 1.6 },
	},
}
