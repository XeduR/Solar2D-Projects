local palette = require( "data.palette" )
local fonts = require( "data.fonts" )

return {
	family = "ui",

	knots = {
		font = fonts.face,
		fontSize = fonts.small,
		textColor = palette.textLight,
		shadowColor = { 0, 0.55 },

		-- Distance of the text shadow below and to the right of the text, in content units.
		shadowOffset = 2,

		-- Backing plate behind the readout; its art is drawn wide enough for the longest readout.
		plateImage = "knotsReadout",

		-- Space between the plate's left edge and the start of the text.
		platePaddingX = 18,

		plateAlpha = 0.82,

		-- The readout punches (grows and flashes) when one frame raises the knots by this fraction, or the knots pass a new power of ten.
		punchJumpRatio = 0.2,

		-- No punch below this many knots.
		punchMinKnots = 10,

		-- Extra size at the start of a punch, as a fraction of the normal size.
		punchScale = 0.16,

		-- Seconds a punch takes to shrink and fade back to normal.
		punchDuration = 0.35,

		-- Seconds after a punch ends before the next one can start.
		punchCooldown = 0.15,

		-- Text colour at the start of a punch, fading back to textColor.
		punchColor = { 1, 0.86, 0.45 },

		-- Seconds between readout text refreshes; a punch refreshes it at once.
		refreshInterval = 0.1,
	},

	buttons = {
		-- Offset of the button column's top-left corner from the screen's top-left corner.
		marginX = 15,
		marginY = 15,

		-- Space between the two buttons, and between the Options button and the knots readout.
		gap = 12,

		image = "button",
		normalTag = "normal",
		pressedTag = "pressed",

		-- Button size in content units.
		width = 144,
		height = 48,

		optionsLabel = "Options",
		resetLabel = "Reset",

		font = fonts.face,
		fontSize = fonts.small,
		textColor = palette.buttonText,

		pressedScale = 0.94,

		-- Seconds a press keeps the button in its pressed look.
		pressedDuration = 0.14,
	},

	slider = {
		-- The track and fill art set the slider's width.
		trackImage = "sliderGroove",
		fillImage = "sliderLevel",
		knobImage = "sliderKnob",
		normalTag = "normal",
		pressedTag = "pressed",

		knobPressedScale = 1.15,

		-- Height of the invisible press area over the track, so the thin track is easy to grab.
		hitHeight = 40,

		-- Vertical offset of the label and the percentage from the track's centre; negative is up.
		labelOffsetY = -24,

		-- Space between the track's right end and the percentage beside it; covers the knob's overhang at full volume.
		valueGap = 30,

		font = fonts.face,
		valueFont = fonts.face,
		fontSize = fonts.small,
		textColor = palette.textDark,
		percentFormat = "%d%%",
	},

	panel = {
		-- Space between the button column and the panel's left edge.
		gapBesideButtons = 12,

		image = "optionsPanel",

		-- Size of the panel without its drop shadow, in content units.
		width = 552,
		height = 336,

		-- Width of the drop shadow drawn into the image below and to the right of the panel, in content units.
		shadowSize = 6,

		title = "Options",
		titleFont = fonts.face,
		titleFontSize = fonts.large,
		titleColor = palette.textDark,

		-- Distance from the panel's top edge to the title's centre.
		titleOffsetY = 32,

		-- Distance from the panel's top edge to the first slider's track centre.
		firstSliderOffsetY = 104,

		sliderSpacing = 72,

		-- Distance from the panel's left edge to the left end of every slider track, and to the toggle's left edge.
		paddingX = 36,

		-- Distance from the panel's top edge to the instructions toggle's centre; the toggle's left edge lines up with the slider labels.
		toggleOffsetY = 300,

		-- The toggle reads as checked when the instructions are turned on.
		toggleChecked = "[X] show instructions at start",
		toggleUnchecked = "[ ] show instructions at start",

		toggleFont = fonts.face,
		toggleFontSize = fonts.small,
		toggleColor = palette.textDark,

		-- Each key names a volume entry in the save data.
		sliders = {
			{ key = "master", label = "Master volume" },
			{ key = "music", label = "Music" },
			{ key = "sfx", label = "SFX" },
		},
	},
}
