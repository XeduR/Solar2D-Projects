return {
	knotsFormat = "%s knots",
	thousandsSeparator = ",",

	-- Decimal places shown on values such as millions.
	scaledDecimals = 1,

	-- Ascending; values from the first entry up are shown scaled instead of as whole knots.
	magnitudes = {
		{ value = 1e6, name = "million" },
		{ value = 1e9, name = "billion" },
		{ value = 1e12, name = "trillion" },
		{ value = 1e15, name = "quadrillion" },
		{ value = 1e18, name = "quintillion" },
	},
}
