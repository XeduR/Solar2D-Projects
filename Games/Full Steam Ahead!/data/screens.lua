local palette = require( "data.palette" )
local fonts = require( "data.fonts" )

return {
	family = "ui",

	-- The title bubble joins the sentences on one line, the game-over screen stacks them.
	credits = {
		"A Game by Eetu Rantanen.",
		"Made for Ludum Dare 60.",
	},

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

		-- The logo's top edge lines up with the top of the HUD's Options button, which stays on top of this screen.
		-- Each OffsetY is measured down from the top screen edge to the item's centre.
		creditsOffsetY = 117,
		creditsFont = fonts.face,
		creditsFontSize = fonts.small,

		listHeader = "Top speeds",
		listHeaderOffsetY = 172,
		listHeaderFont = fonts.face,
		listHeaderFontSize = fonts.large,

		dividerWidth = 360,
		dividerHeight = 2,
		dividerOffsetY = 191,

		listOffsetY = 211,
		rowSpacing = 30,
		rowCount = 10,
		rowFont = fonts.face,
		rowFontSize = fonts.small,
		rowHighlightFont = fonts.face,

		-- Row columns relative to the screen centre: right-aligned rank, right-aligned value.
		rankColumnX = -160,
		valueColumnX = 240,
		rankFormat = "%d.",
		emptyValue = "-",

		-- A nine-slice stretched across its row; the margin is how far it reaches past the rank text's left edge and the value column on the right.
		highlightImage = "rowHighlight",
		highlightMarginX = 18,
		highlightHeight = 33,

		-- Extra gap above the run's own row, shown when the run did not make the list.
		runGap = 12,
		runLabel = "Your run",

		prompt = "Press any key to play again.",

		-- Measured up from the bottom screen edge to the prompt's centre.
		promptOffsetFromBottom = 28,

		-- The ending line centres between the bottom of the run row's highlight slot and this line, measured up from the bottom screen edge.
		endingLineFloorOffset = 43.5,

		-- Ending lines longer than this wrap.
		endingLineWidth = 820,
		endingLineFont = fonts.face,
		endingLineFontSize = fonts.small,
	},

	help = {
		heading = "How to play",
		instructions = {
			"- Hold Up arrow or W to go up, release to fall.",
			"- Keep shovelling, or the captain fires you.",
			"- Don't crash!",
		},
		prompt = "Press any key to continue.",

		-- Seconds before the prompt appears; keys pressed before then are swallowed.
		promptDelay = 1.25,

		-- The toggle reads as checked when the instructions are turned off.
		toggleChecked = "[X] Don't show this next time.",
		toggleUnchecked = "[ ] Don't show this next time.",

		dimColor = { 0, 0.55 },

		-- A nine-slice sized around its text plus the padding; shadowSize must match the drop shadow drawn into its right and bottom edges.
		image = "helpCard",
		shadowSize = 6,
		paddingX = 36,
		paddingY = 42,

		-- Vertical gaps after the heading, between instructions, before the toggle, and before the prompt.
		headingGap = 15,
		instructionGap = 9,
		toggleGap = 30,
		promptGap = 27,

		headingFont = fonts.face,
		headingFontSize = fonts.large,
		headingColor = palette.textDark,

		instructionFont = fonts.face,
		instructionFontSize = fonts.small,
		instructionColor = palette.textDark,

		toggleFont = fonts.face,
		toggleFontSize = fonts.small,
		toggleColor = palette.textDark,

		-- The card is light, so its prompt takes the crash screen's dark text colour.
		promptColor = palette.textDark,

		popDuration = 0.25,
		popStartScale = 0.85,
	},

	-- The "press any key" prompts on the game-over screen and the help card.
	prompt = {
		-- Seconds before the game-over prompt appears; keys pressed before then are swallowed.
		delay = 2.5,

		font = fonts.face,
		fontSize = fonts.large,

		-- Seconds the prompt stays lit and dimmed in each blink.
		blinkOnTime = 0.6,
		blinkOffTime = 0.35,
		blinkDimAlpha = 0.15,
	},
}
