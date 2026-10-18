return {
	face = "assets/fonts/PressStart2P-Regular.ttf",

	-- Press Start 2P draws on an 8-pixel grid, so sizes on multiples of 8 keep its pixels even.
	large = 24,
	small = 16,

	-- Line pitch of multi-line text blocks as a multiple of the font size; the font has no line gap, so at 1 its descenders touch the next line's capitals.
	lineSpacing = 1.375,

	-- Downward text shift per renderer as a fraction of the font size, moving the glyphs to where the HTML5 layout puts them.
	rendererOffsetY = {
		win32 = 0.29,
	},
}
