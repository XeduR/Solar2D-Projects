return {
	-- Difficulty ramps from easy to hard as log10 of the knots rises from levelStart, near escape speed, to levelEnd.
	levelStart = 4.3,
	levelEnd = 13,

	-- Minimum horizontal free space between waves, in content units, at the easy and hard end of the ramp.
	spacingEasy = 380,
	spacingHard = 190,

	-- Height of the guaranteed passable gap through each wave, at the easy and hard end of the ramp.
	gapEasy = 300,
	gapHard = 190,

	-- Distance past the right edge where the first wave appears after activation.
	firstWaveDistance = 220,

	-- Waves spawn once their left edge is this close beyond the right screen edge.
	spawnLead = 40,

	-- Obstacles are removed once fully this far past the left screen edge.
	removeMargin = 40,

	-- Largest gap between the boat's and an obstacle's collision edges, in content units, that still plays the near-miss whoosh as it passes.
	nearMissDistance = 30,

	-- Gaps stay a boat diameter plus this far from the top and bottom edges.
	gapEdgeMargin = 40,

	-- Largest vertical move between consecutive gap centres, at the easy and hard end of the ramp.
	maxShiftEasy = 260,
	maxShiftHard = 420,

	-- Seconds allowed to react before the boat starts moving to the next gap, and a safety factor on the whole move time for rising scroll speed and human input.
	reactionTime = 0.3,
	shiftTimeSafety = 1.25,

	-- Pattern weights; minLevel is the log10 of the knots at which a pattern joins the mix.
	patterns = {
		{ name = "planet", weight = 4, minLevel = 0 },
		{ name = "belt", weight = 3, minLevel = 0 },
		{ name = "cluster", weight = 2, minLevel = 5 },
		{ name = "planetPair", weight = 3, minLevel = 6.5 },
		{ name = "planetBelt", weight = 2, minLevel = 8.5 },
	},

	family = "space",

	planet = {
		image = "planet",
		ringedImage = "planetRinged",
		bandsSuffix = "Bands",
		cratersSuffix = "Craters",

		radiusMin = 60,
		radiusMax = 135,

		-- Planet radius, in content units, at which the art shows at its own size.
		artRadius = 135,

		-- Planets sit this far beyond the gap edge at most, so most of them still crowd the gap.
		gapSlack = 70,

		-- Hit radius as a share of the drawn radius.
		hitScale = 0.97,

		-- Chances per planet; a silly planet has a face and no ring, bands or craters, and craterChance only applies to planets without bands.
		ringChance = 0.3,
		craterChance = 0.35,
		bandChance = 0.3,
		sillyChance = 0.08,

		-- Glow radius as a multiple of the planet radius.
		glowScale = 1.12,
		glowAlpha = 0.18,

		-- Outer edge of the ring art as a multiple of the planet radius, which sets how much room a ringed planet takes up.
		ringOuterScale = 1.76,

		face = {
			pupilImage = "planetPupil",
			moustacheImage = "planetMoustache",
			moustacheTags = { "left", "right" },

			-- Eye centres in the silly frame, as a share of the planet radius from its centre.
			eyeOffsetX = 42 / 135,
			eyeOffsetY = 24 / 135,

			-- How far the pupils move, as a share of the planet radius, and how fast they glance, in radians per second.
			pupilReach = 0.06,
			pupilWobbleSpeed = 3.1,

			-- Shares of the pupil reach: the rest offset left towards the boat, the left and right swing around it, and the up and down swing.
			pupilGlanceBase = 0.6,
			pupilGlanceSwing = 0.4,
			pupilGlanceVertical = 0.5,

			-- Moustache height below the planet centre as a share of the radius, its twirl speed in radians per second, and its twirl in degrees either way.
			moustacheOffsetY = 0.2,
			moustacheTwirlSpeed = 2.2,
			moustacheTwirlAngle = 6,
		},

		-- Each tag names the plain, ringed and suffixed planet frames; glow is the planet's light colour.
		schemes = {
			{ tag = "orange", glow = { 0.96, 0.64, 0.35 } },
			{ tag = "blue", glow = { 0.6, 0.8, 0.95 } },
			{ tag = "green", glow = { 0.7, 0.95, 0.55 } },
			{ tag = "purple", glow = { 0.9, 0.62, 0.95 } },
			{ tag = "grey", glow = { 0.66, 0.58, 0.49 } },
		},

		sillyScheme = { tag = "silly", glow = { 1, 0.85, 0.55 } },
	},

	asteroid = {
		image = "asteroid",

		radiusMin = 14,
		radiusMax = 30,

		-- Hit radius as a share of the drawn radius.
		hitScale = 0.78,

		-- Asteroid frames with the radius, in content units, each one is drawn for; the nearest one is scaled to fit.
		variants = {
			{ tag = "small", radius = 15 },
			{ tag = "medium", radius = 19.5 },
			{ tag = "large", radius = 24 },
			{ tag = "huge", radius = 30 },
		},

		-- Spin speed range in degrees per second, in a random direction.
		spinMin = 25,
		spinMax = 110,

		-- Belts fill the space outside the gap with asteroids stepped this far apart vertically.
		beltStepMin = 70,
		beltStepMax = 110,

		-- Random sideways spread of belt asteroids.
		beltJitterX = 70,

		-- Belts continue this far past the top and bottom screen edges.
		beltEdgeOverhang = 30,

		-- The first belt asteroid sits up to this share of beltStepMin beyond the gap edge.
		beltFirstJitter = 0.25,

		-- Asteroids per cluster, and how far a cluster spreads sideways and vertically.
		clusterCountMin = 3,
		clusterCountMax = 6,
		clusterSpreadX = 110,
		clusterSpreadY = 150,

		-- Chance that a cluster wave also gets a cluster on the other side of the gap.
		clusterMirrorChance = 0.5,
	},
}
