local palette = require( "data.palette" )
local fonts = require( "data.fonts" )

return {
	-- Bubbles never come closer than this to a screen edge.
	screenMargin = 14,

	-- Rate per second at which a bubble catches up with its target; higher is snappier.
	followRate = 9,

	-- Gap between the captain and the nearest edge of the bubble that follows him.
	tailLength = 70,

	-- A bubble below the anchor flips back above only once there is this much spare room, to avoid flicker.
	flipHysteresis = 24,

	-- Seconds a line stays up: the base plus a share per character, kept between the min and max.
	durationBase = 1.4,
	durationPerCharacter = 0.055,
	durationMin = 2,
	durationMax = 5,

	-- Seconds the line bubble takes to fade out at the end of its line.
	fadeDuration = 0.25,

	-- A milestone line replaced by another line within this many seconds is queued again, so both are seen.
	milestoneRequeueTime = 0.6,

	-- Bubble tier each quip pool speaks in; pools not listed use tier 0.
	poolTiers = {
		fired = 4,
	},

	-- Seconds a new bubble takes to grow in from startScale; a higher overshoot makes it bounce past full size further.
	pop = {
		duration = 0.28,
		startScale = 0.35,
		overshoot = 1.9,
	},

	tail = {
		-- Half the tail's width where it joins the bubble.
		baseHalfWidth = 14,

		-- How far the tail starts inside the bubble edge, so the join shows no gap.
		inset = 10,

		-- How far the tip stops short of the captain.
		tipGap = 6,

		-- How far the tail runs straight out of the bubble before it turns, as a share of its length; 0 is a straight tail.
		bend = 0.45,

		-- Tails shorter than this are not drawn.
		minLength = 8,

		-- Straight pieces along each side of the tail; more is a smoother curve.
		segments = 8,

		-- How far the point the tail aims at must move, relative to the bubble, before the tail is redrawn.
		rebuildThreshold = 3,
	},

	family = "ui",

	-- Nine-slice art stretched to fit the text, with one frame per bubble variant.
	bubbleImage = "speechBubble",
	logoImage = "logo",

	-- Must match the drop shadow drawn into the bubble art, so the tail's shadow lines up with it.
	shadowOffsetX = 3,
	shadowOffsetY = 6,

	-- Must match the outline thickness of the bubble art, so the tail's outline lines up with it.
	edgeWidth = 3,

	-- Must match the bubble art's outline and shadow colours.
	edgeColour = { 0.078, 0.059, 0.059 },
	shadowColour = { 0.078, 0.059, 0.059, 0.28 },

	-- Must match each bubble variant's fill colour in the art.
	tailFillColours = {
		calm = { 0.976, 0.957, 0.89 },
		cross = { 1, 0.878, 0.761 },
		angry = { 1, 0.796, 0.733 },
	},

	-- Bubble style per anger tier; shake is how far the bubble trembles.
	tiers = {
		[0] = {
			font = fonts.regular,
			fontSize = fonts.large,
			padding = 15,
			maxTextWidth = 360,
			textColour = palette.textDark,
			variant = "calm",
			shake = 0,
		},

		[1] = {
			font = fonts.regular,
			fontSize = fonts.large,
			padding = 18,
			maxTextWidth = 390,
			textColour = palette.angerTiers[1],
			variant = "calm",
			shake = 0,
		},

		[2] = {
			font = fonts.bold,
			fontSize = fonts.large,
			padding = 21,
			maxTextWidth = 420,
			textColour = palette.angerTiers[2],
			variant = "cross",
			shake = 0,
		},

		[3] = {
			font = fonts.bold,
			fontSize = fonts.large,
			padding = 24,
			maxTextWidth = 460,
			textColour = palette.angerTiers[3],
			variant = "angry",
			shake = 2.5,
		},

		[4] = {
			font = fonts.bold,
			fontSize = fonts.large,
			padding = 27,
			maxTextWidth = 500,
			textColour = palette.angerTiers[4],
			variant = "angry",
			shake = 4.5,
		},
	},

	-- The title bubble holds the logo with the credit line under it.
	title = {
		variant = "calm",
		padding = 24,
		creditsGap = 12,
		creditsFont = fonts.regular,
		creditsFontSize = fonts.small,
		textColour = palette.textDark,
		shake = 0,

		-- Distance from the top screen edge to the title bubble's top edge.
		topOffset = 69,
	},

	-- How fast a shaking bubble trembles, in radians per second.
	shakeSpeed = 38,

	-- Vertical shake runs at a different speed and smaller size than horizontal, so it never looks like a loop.
	shakeVerticalSpeedRatio = 1.37,
	shakeVerticalAmplitude = 0.6,
}
