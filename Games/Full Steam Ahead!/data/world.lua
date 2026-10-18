-- Screen shares use the real screen size, parallax is a share of the scroll speed, pivots are art pixels from a frame's top-left, sizes are content units.
return {
	family = "world",

	layout = {
		-- Phase 1 boat x as a share of the screen width.
		boatX = 0.55,

		-- Phase 2 boat x from the left screen edge, clear of the engine room circle.
		spaceOffsetX = 340,

		-- Boat scale once it flies through space as a comet.
		cometScale = 0.12,
	},

	-- How quickly the 0 to 1 speed level that drives the visuals catches up with the knots; it follows the logarithm of the knots, reaching 1 at escape speed.
	speedResponse = 4,

	zoom = {
		-- Above 1, the camera stays close for longer before zooming out as the speed rises.
		curve = 1.5,

		-- How quickly the camera zoom catches up with the speed.
		response = 1.6,

		-- At the closest and widest zoom: boat scale, Earth radius, and sea surface height as a share of the screen height from the top.
		boatScaleClose = 1,
		boatScaleWide = 0.18,
		earthRadiusClose = 50000,
		earthRadiusWide = 760,
		surfaceClose = 0.64,
		surfaceWide = 0.54,
	},

	earth = {
		-- Polygon segments for the visible arc of the Earth, and for the full circle drawn during the launch.
		segments = 72,
		circleSegments = 128,

		-- How far the Earth shape reaches past the screen edges, so no gap shows at the sides or bottom.
		edgeMargin = 60,

		-- The drawn Earth is scaled between rebuilds and rebuilt once its scale leaves this range.
		minScale = 0.8,
		maxScale = 1.25,

		oceanTop = { 0.13, 0.45, 0.72 },
		oceanBottom = { 0.03, 0.14, 0.34 },

		rimColour = { 0.859, 0.949, 1 },
		rimAlpha = 0.85,
		rimWidth = 3,

		glowColour = { 0.6, 0.8, 0.949 },
		glowInnerAlpha = 0.35,
		glowOuterAlpha = 0.16,

		-- Width of the inner glow as a share of the outer glow.
		glowInnerRatio = 0.5,

		-- Width of the outer glow as a share of the Earth radius, kept between glowMin and glowMax.
		glowRatio = 0.07,
		glowMin = 10,
		glowMax = 46,
	},

	sky = {
		-- How far the sky rectangles reach past each screen edge.
		margin = 40,

		-- The calm gradient shows at rest and the deep one fades in over it as the speed rises; a higher deepCurve holds it back until higher speeds.
		calmTop = { 0.38, 0.64, 0.92 },
		calmBottom = { 0.8, 0.91, 0.98 },
		deepTop = { 0.059, 0.071, 0.188 },
		deepBottom = { 0.28, 0.4, 0.74 },
		deepCurve = 1.4,

		space = { 0.059, 0.071, 0.188 },
	},

	streakImage = "speedStreaks",

	-- Art widths of the streak frames; every frame shares the long streak's canvas, so the image width does not give the length.
	streakLengths = { long = 64, short = 28 },

	stars = {
		image = "stars",

		-- Far to near; each layer moves from parallax to parallaxFast as the scroll rises from scroll.base to scroll.max.
		-- streak names the streak frame a layer's stars turn into.
		layers = {
			{ count = 70, tags = { "smallWhite", "smallBlue", "smallPurple" }, streak = "short", parallax = 0.12, parallaxFast = 0.06, alpha = 0.55 },
			{ count = 40, tags = { "mediumWhite", "mediumBlue", "mediumPurple" }, streak = "short", parallax = 0.35, parallaxFast = 0.4, alpha = 0.8 },
			{ count = 18, tags = { "largeWhite", "largeBlue", "largePurple" }, streak = "long", parallax = 0.8, parallaxFast = 1.4, alpha = 1 },
		},

		-- A layer turns into speed streaks once the distance it covers in streakTime seconds reaches streakMinLength.
		streakTime = 0.04,
		streakMinLength = 24,
		streakPivot = { 0, 0.5 },

		-- Range of the twinkle pulse speed, in radians per second.
		twinkleSpeed = { 1.5, 4 },

		-- Share of a star's alpha that the twinkle takes away at its dimmest.
		twinkleAmount = 0.35,

		-- Stars with a second frame show it near the brightest point of the twinkle; closer to 1 keeps the glint shorter.
		glintLevel = 0.9,

		-- How far past the left screen edge a star travels before it wraps to the right.
		wrapMargin = 4,

		-- Faint stars show in the deepening phase 1 sky: oceanAlpha is their alpha at escape speed, and a higher oceanCurve hides them until closer to it.
		oceanAlpha = 0.35,
		oceanCurve = 4,
	},

	nebulae = {
		image = "nebula",
		count = 4,
		tags = { "drift", "clump" },

		-- Each nebula picks one of these scales at random.
		scales = { 1, 2 },
		alpha = 0.5,
		parallax = 0.04,
	},

	-- Phase 1 scroll speed per second rises from idleScroll at rest by up to maxScroll at escape speed; a higher curve holds it back at low speed.
	scenery = {
		idleScroll = 18,
		maxScroll = 1400,
		curve = 2,
	},

	clouds = {
		image = "cloud",
		count = 7,
		sizes = { "large", "medium", "small" },
		pivot = { 21, 21 },
		alpha = 0.92,

		-- Range of cloud heights above the sea surface at the closest zoom.
		altitude = { 110, 360 },
		parallax = { 0.12, 0.4 },

		-- Cloud scale and altitude at the widest zoom, as a share of their closest zoom values.
		scaleWide = 0.35,

		-- Extra distance past the right screen edge at which a cloud respawns, picked from this range.
		spawnGap = { 40, 320 },

		-- Half a cloud's width, so clouds wrap only once fully off screen.
		halfWidth = 60,
	},

	speedLines = {
		count = 14,

		-- Speed level at which speed lines start fading in; they reach full alpha at escape speed.
		start = 0.4,
		alpha = 0.55,
		streaks = { "long", "short" },
		pivot = { 0, 0.5 },

		-- Line speed as a multiple of the scroll speed, picked from this range, plus extraSpeed in content units per second.
		speedFactor = { 1.6, 2.6 },
		extraSpeed = 300,

		-- Lines spawn between skyTop below the screen top and surfaceGap above the sea surface.
		skyTop = 10,
		surfaceGap = 30,

		-- Extra distance past the right screen edge at which a line respawns, picked from this range.
		spawnGap = { 0, 400 },
	},

	waves = {
		image = "waveCrest",
		count = 28,

		-- Crest lengths from far to near.
		tags = { "short", "medium", "long" },
		alpha = { 0.35, 0.7 },

		-- Each crest gets a random distance from far to near, and its depth below the surface line, parallax and size all follow it.
		depth = { 6, 250 },
		parallaxFar = 0.55,
		parallaxNear = 1.4,
		sizeFar = 0.7,
		sizeNear = 1.2,

		-- Crest scale and depth at the widest zoom, as a share of their closest zoom values.
		scaleWide = 0.4,

		-- Extra horizontal stretch of the crests at escape speed, so they read as motion blur.
		stretch = 2.5,

		-- Extra distance past the right screen edge at which a crest respawns, picked from this range.
		spawnGap = { 20, 120 },

		-- How far past the left screen edge a crest travels before it respawns.
		wrapMargin = 40,
	},

	-- Phase 2 scroll speed per second: base at escape speed, curve shapes the growth above it and slowCurve the drop below it, kept within min and max.
	scroll = {
		base = 180,
		curve = 0.9,
		slowCurve = 0.5,
		min = 60,
		max = 1800,
	},

	-- Launch progress points are fractions of the duration.
	launch = {
		-- Launch length in seconds.
		duration = 1.75,

		-- Downward drift of the boat over the launch, and the gap left between the screen edge and the departed Earth's glow.
		sag = 12,
		earthExitMargin = 40,

		-- Progress at which the sky has turned to space and the sea has faded out.
		skyFadeEnd = 0.6,
		waterFadeEnd = 0.4,

		-- Progress at which the stars and the comet effects start fading in, and how long each fade lasts.
		starStart = 0.2,
		starFade = 0.55,
		cometStart = 0.3,
		cometFade = 0.5,
	},
}
