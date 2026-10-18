-- Positions are in room space: origin at the bottom-left screen corner (the circle centre), y negative upwards.

local fonts = require( "data.fonts" )

local restPose = { time = 1, x = 50, y = -152, rotation = -6 }

return {
	radius = 300,

	-- Contents stay inside this radius; the rim covers everything from here to the radius.
	safeRadius = 278,

	-- How finely the porthole and glow arcs are drawn; smaller is smoother.
	arcStepDegrees = 3,

	-- Smallest flame scale, since display objects cannot be scaled to zero.
	minScale = 0.01,

	-- Two summed sines give the flames an irregular flicker.
	noise = {
		secondFrequency = 2.73,
		secondWeight = 0.4,
	},

	fire = {
		-- How quickly the fire level follows its target; higher is faster.
		response = 5,
	},

	rim = {
		width = 22,
	},

	families = {
		room = "engineRoom",
		effects = "effects",
	},

	-- Sheet art placed by its top-left corner.
	sprites = {
		-- Room, gauge face, furnace body and coal pile; the needle and the fire draw on top of it.
		room = { name = "engineRoom", x = 0, y = -300 },

		-- Furnace door, arch and grate, drawn over the flames.
		front = { name = "engineRoomFront", x = 108, y = -114 },

		rim = { name = "rim", x = 0, y = -300 },
	},

	-- The needle pivots on the gauge face centre drawn in the room art.
	gauge = {
		sheet = "meter",
		x = 55.5,
		y = -211.5,
		minRotation = -120,
		maxRotation = 120,

		-- Needle shake in degrees at full fire, and how fast it shakes.
		jitter = 9,
		jitterSpeed = 37,
	},

	furnace = {
		-- The opening has straight sides of straightHeight rising from bottom, topped by an arch of radius halfWidth.
		mouth = {
			centerX = 160,
			bottom = -58,
			halfWidth = 28,
			straightHeight = 20,

			-- Thrown coal lands within targetSpread of this height.
			targetY = -82,
			targetSpread = 8,
		},
	},

	-- The ember art is already fire-coloured, so the tint runs from coldColor up to white, which shows the art as drawn.
	embers = {
		sheet = "particles",
		tag = "ember",
		count = 5,
		y = -61,

		-- How far the outermost embers sit from the mouth centre.
		spread = 20,
		coldColor = { 0.25, 0.04, 0.02 },
		hotColor = { 1, 1, 1 },

		-- Brightness from 0 (coldColor) to 1 (hotColor): baseGlow when cold, plus levelGlow at full fire and kickGlow per unit of coal kick.
		baseGlow = 0.3,
		levelGlow = 0.7,
		kickGlow = 0.3,

		-- Each ember's brightness wobbles by pulse either way.
		pulse = 0.12,
		pulseSpeed = 3,
	},

	flames = {
		sheet = "flamesFurnace",

		-- Anchor on the base of the flames, so they grow upwards.
		anchorX = 0.5,
		anchorY = 1,
		baseY = -60,

		-- The art steps through its tags with the fire level; scale and alpha flicker ride on top.
		tiers = {
			{ tag = "low", fromLevel = 0 },
			{ tag = "mid", fromLevel = 0.3 },
			{ tag = "high", fromLevel = 0.6 },
		},

		-- Fire level where the flames appear, fading in over fadeRange.
		startLevel = 0.02,
		fadeRange = 0.08,

		-- Height and width scales with no fire, and how much each grows by full fire.
		scaleMin = 0.8,
		scaleRange = 0.3,
		widthMin = 0.9,
		widthRange = 0.2,

		-- Keeps the tallest frame's tip inside the safe radius.
		maxScale = 1.12,

		-- Extra height per unit of coal kick.
		kickHeight = 0.35,
		flickerAmount = 0.12,

		-- Share of the height flicker that is taken off the width, so taller flames get narrower.
		squash = 0.4,
		alphaFlicker = 0.15,
		flickerSpeed = 9,

		-- The flicker speeds up by this share at full fire.
		flickerSpeedGain = 1,

		-- Sideways sway in content units.
		sway = 2,
		swayFrequency = 0.7,
	},

	burst = {
		sheet = "flamesBurst",
		tag = "burst",

		-- Anchor on the root of the flame.
		anchorX = 0.05,
		anchorY = 0.94,

		-- The art points this many degrees above horizontal, with a root-to-tip length of about nativeLength.
		drawnAngle = 40,
		nativeLength = 200,

		-- Fire level where the flames start bursting out of the porthole.
		startLevel = 0.8,

		-- Even the shortest burst reaches past the rim.
		minLength = 145,
		maxLength = 250,

		-- Extra length per unit of coal kick.
		kickLength = 0.15,
		flickerAmount = 0.12,
		flickerSpeed = 11,

		-- Rotation wobble in degrees.
		wobble = 4,
		swayFrequency = 0.6,

		-- angle is degrees above horizontal; the scale values multiply the shared length and flicker speed.
		tongues = {
			{ angle = 30, lengthScale = 0.8, speedScale = 1.2, alpha = 0.9, startFrame = 3 },
			{ angle = 52, lengthScale = 0.85, speedScale = 1.4, alpha = 0.9, startFrame = 2 },
			{ angle = 40, lengthScale = 1, speedScale = 0.9, alpha = 1, startFrame = 1 },
		},
	},

	-- Warm light over the whole room: baseAlpha, plus levelAlpha at full fire and kickAlpha per unit of coal kick.
	glow = {
		color = { 1, 0.46, 0.08 },
		baseAlpha = 0.02,
		levelAlpha = 0.17,
		kickAlpha = 0.06,
		flickerAmount = 0.15,
		flickerSpeed = 7,
	},

	-- Rings of light around the furnace mouth, smallest first; their alpha grows with the fire level plus baseLevel.
	halo = {
		radii = { 34, 58, 86 },
		alphas = { 0.2, 0.11, 0.06 },
		color = { 1, 0.46, 0.08 },
		baseLevel = 0.12,
		kickAlpha = 0.6,
	},

	shovel = {
		sheet = "shovel",
		emptyTag = "empty",
		loadedTag = "loaded",

		-- Anchor on the stoker's hands.
		anchorX = 0.5,
		anchorY = 6 / 45,
		bladeDistance = 93,

		-- Seconds per swing at normal speed. A press during the swing speeds it up; rapid presses push the speed towards maxSpeed.
		cycleDuration = 0.5,
		maxSpeed = 3,

		-- Each press adds 1 heat, which fades at heatDecay per second; swing speed is 1 plus heat times speedPerHeat.
		speedPerHeat = 0.5,
		heatDecay = 2.5,

		-- Points in the swing, as a share of it, where the blade picks up coal and throws it.
		loadTime = 0.28,
		releaseTime = 0.55,

		-- Idle sway while the shovel rests: bob in content units, tilt in degrees.
		idleBob = 1.5,
		idleTilt = 1.5,
		idleSpeed = 2.2,

		-- Swing keyframes; time is the share of the swing at which the shovel reaches the pose.
		restPose = restPose,
		poses = {
			{ time = 0.28, x = 38, y = -146, rotation = 10 },
			{ time = 0.45, x = 46, y = -165, rotation = 14 },
			{ time = 0.62, x = 82, y = -150, rotation = -52 },
			{ time = 0.74, x = 84, y = -148, rotation = -57 },
			restPose,
		},
	},

	coal = {
		sheet = "coal",
		poolSize = 16,

		-- Seconds in the air at normal swing speed.
		flightTime = 0.2,
		arcHeight = 22,

		-- Seconds between the chunks of one throw.
		stagger = 0.045,
		releaseJitter = 4,

		-- Fastest spin in degrees per second.
		spin = 540,
		endScale = 0.6,
	},

	flare = {
		poolSize = 6,
		radius = 22,
		color = { 1, 0.7, 0.25 },
		alpha = 0.95,
		duration = 0.28,
		startScale = 0.3,
		endScale = 1.7,

		-- Each landing adds kick, which brightens and lengthens the fire and fades by kickDecay per second.
		kick = 1,
		maxKick = 2,
		kickDecay = 5,

		sparkCount = 5,
		sparkMinSpeed = 60,
		sparkMaxSpeed = 120,

		-- Degrees clockwise from the right on screen, so 270 points straight up.
		sparkMinAngle = 200,
		sparkMaxAngle = 340,
		sparkGravity = 260,
		sparkLife = 0.45,
	},

	-- The spark art is pale, so these tints give the ember or metal colour.
	sparks = {
		sheet = "particles",
		tag = "spark",
		poolSize = 48,
		emberColor = { 1, 0.7, 0.25 },
		metalColor = { 1, 0.95, 0.65 },

		-- Sparks per second rising from the mouth at full fire; negative gravity makes them float up.
		ambientRate = 14,
		ambientSpread = 22,
		ambientMinSpeed = 45,
		ambientMaxSpeed = 75,
		ambientDrift = 20,
		ambientGravity = -40,
		ambientLife = 0.7,

		-- Sparks from the fired shovel hitting the floor; angles work like the flare spark angles.
		clatterCount = 7,
		clatterMinSpeed = 80,
		clatterMaxSpeed = 170,
		clatterMinAngle = 200,
		clatterMaxAngle = 340,
		clatterGravity = 700,
		clatterLife = 0.35,
	},

	tooltip = {
		-- One line at the large size does not fit between the porthole and the screen edge.
		text = "<- Tap in the left corner\nto shovel coal.",

		-- The plate sits right of the porthole, near the bottom and below the burst flames; the gaps also cover the pulse growth.
		rimGap = 24,
		bottomMargin = 12,
		plateImage = "tooltip",

		-- Space between the label and the plate's edges.
		paddingX = 32,
		paddingY = 22,
		plateAlpha = 0.88,
		font = fonts.bold,
		fontSize = fonts.large,

		-- Alpha change per second when showing or hiding.
		fadeSpeed = 6,

		-- The tooltip pulses its size by up to pulseScale and its alpha down to pulseMinAlpha.
		pulseSpeed = 5,
		pulseScale = 0.04,
		pulseMinAlpha = 0.72,
	},

	-- When the stoker is fired, the shovel is tossed up and clatters to the floor while the fire dies down.
	fired = {
		tossSpeed = 260,
		gravity = 1700,

		-- How quickly the shovel slides to lyingX and turns to lyingRotation; higher is faster.
		slide = 6,
		spin = 10,
		lyingX = 22,
		restY = -27,
		lyingRotation = -90,

		-- Share of the falling speed kept on each bounce.
		restitution = 0.38,
		maxBounces = 3,

		-- Rotation wobble in degrees after the first bounce, smaller on each later one.
		bounceWobble = 14,
		wobbleSpeed = 30,
		wobbleDecay = 6,

		-- The fire dims over dimTime seconds down to dimFloor of its brightness.
		dimTime = 1.1,
		dimFloor = 0.08,

		-- Seconds before the fired ending moves on.
		completeDelay = 1.4,
	},
}
