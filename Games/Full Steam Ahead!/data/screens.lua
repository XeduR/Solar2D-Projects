local palette = require( "data.palette" )
local fonts = require( "data.fonts" )

return {
	family = "ui",

	credits = "A Game by Eetu Rantanen. Made for Ludum Dare 60",

	firedTransition = {
		duration = 1.3,
		color = { 0 },

		-- The circle overshoots the farthest screen corner by this much so its edge never shows.
		radiusMargin = 40,

		-- Scale the circle grows from.
		minScale = 0.001,
	},

	crashTransition = {
		duration = 0.5,
		color = { 1 },
		radiusMargin = 40,
		minScale = 0.001,

		-- A larger circle behind the main one that fades as it grows; ringScale is its size relative to the main circle.
		ringColor = { 1, 0.93, 0.7 },
		ringAlpha = 0.6,
		ringScale = 1.25,

		-- The flash peaks almost instantly, sags while the circle grows, and ends fully white.
		flashColor = { 1 },
		flashPeakAlpha = 0.9,

		-- Point in the transition where the flash peaks, from 0 at the start to 1 at the end.
		flashPeakTime = 0.08,
		flashFloorAlpha = 0.45,

		-- The sag takes 1 / flashSagSpeed of the time left after the peak.
		flashSagSpeed = 2,
	},

	gameOver = {
		logoImage = "logo",

		fadeInDuration = 0.4,

		themes = {
			fired = {
				background = { 0 },
				text = palette.textLight,
				dimText = { 0.62, 0.62, 0.6 },
				highlightVariant = "ember",
				highlightText = { 1 },
				divider = { 1, 0.18 },
			},

			crash = {
				background = { 1 },
				text = palette.textDark,
				dimText = { 0.42, 0.42, 0.44 },
				highlightVariant = "gold",
				highlightText = palette.textDark,
				divider = { 0, 0.15 },
			},
		},

		-- Each OffsetY is measured down from the top screen edge: to the logo's top edge, and to the centre of every other item.
		logoOffsetY = 69,

		creditsOffsetY = 162,
		creditsFont = fonts.regular,
		creditsFontSize = fonts.small,

		listHeader = "Top speeds",
		listHeaderOffsetY = 195,
		listHeaderFont = fonts.bold,
		listHeaderFontSize = fonts.small,

		dividerWidth = 360,
		dividerHeight = 2,
		dividerOffsetY = 213,

		listOffsetY = 234,
		rowSpacing = 27,
		rowCount = 10,
		rowFont = fonts.regular,
		rowFontSize = fonts.small,
		rowHighlightFont = fonts.bold,

		-- Row columns relative to the screen centre: right-aligned rank, right-aligned value.
		rankColumnX = -130,
		valueColumnX = 160,
		rankFormat = "%d.",
		emptyValue = "-",

		-- Centred on its row, so the art must be wide enough for the widest row, "Your run" included.
		highlightImage = "rowHighlight",

		-- Extra gap above the run's own row, shown when the run did not make the list.
		runGap = 12,
		runLabel = "Your run",

		playAgain = "Play again?",
		playAgainOffsetFromBottom = 42,
		playAgainFont = fonts.bold,
		playAgainFontSize = fonts.large,
		playAgainHitWidth = 300,
		playAgainHitHeight = 64,

		-- Seconds the prompt stays lit and dimmed in each blink.
		blinkOnTime = 0.6,
		blinkOffTime = 0.35,
		blinkDimAlpha = 0.15,

		endingLineOffsetFromBottom = 93,

		-- Lines longer than this wrap.
		endingLineWidth = 820,
		endingLineFont = fonts.bold,
		endingLineFontSize = fonts.small,
	},

	help = {
		heading = "How to play:",
		instructions = {
			"1. Keep tapping the engine room to shovel coal!",
			"2. Press and hold anywhere outside the engine room to go up.",
			"3. Let go and the boat will begin to fall.",
			"4. Don't crash!",
		},
		prompt = "Tap to continue",

		-- Presses before this many seconds are swallowed, so a frantic shovel click cannot skip the card.
		lockout = 0.8,

		dimColor = { 0, 0.55 },

		-- The card art is not stretched, so the text must fit inside it; shadowSize must match the drop shadow drawn into its right and bottom edges.
		image = "helpCard",
		shadowSize = 6,
		paddingX = 36,
		paddingY = 30,

		-- Vertical gaps after the heading, between instructions, and before the prompt.
		headingGap = 15,
		instructionGap = 9,
		promptGap = 24,

		headingFont = fonts.bold,
		headingFontSize = fonts.large,
		headingColor = palette.textDark,

		instructionFont = fonts.regular,
		instructionFontSize = fonts.small,
		instructionColor = palette.textDark,

		promptFont = fonts.bold,
		promptFontSize = fonts.large,
		promptColor = { 0.75, 0.3, 0.1 },
		promptFadeInDuration = 0.25,

		-- Once shown, the prompt pulses; depth is how far it dims, from 0 for none to 1 for fully out.
		promptPulseSpeed = 4,
		promptPulseDepth = 0.35,

		popDuration = 0.25,
		popStartScale = 0.85,
	},
}
