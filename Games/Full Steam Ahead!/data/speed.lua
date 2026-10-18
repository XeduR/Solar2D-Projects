return {
	-- Knots every shovel adds after the phase growth multiplies the current knots, which also makes it the speed after the first shovel.
	firstShovelKnots = 5,

	-- Earth's real escape velocity, in knots; reaching it launches the boat into space.
	escapeKnots = 21744,

	-- Highest possible speed, in knots, so endless shovelling never overflows to infinity.
	-- Matches the largest unit in data/scores.lua, so raising it needs a larger unit there.
	maxKnots = 1e18,

	-- Per phase, ocean then space: growth multiplies the knots on every shovel, and decay is the exponential rate per second at which they fall off.
	phases = {
		{ growth = 1.62, decay = 1.0 },
		{ growth = 1.25, decay = 0.5 },
	},

	-- Furnace fire level, from 0 to 1, added by each shovel.
	fireGain = 0.12,

	-- Exponential rate per second at which the fire level dies down.
	fireDecay = 0.8,

	-- Share the knots may fall below their recent top speed before the captain starts getting angry.
	angerTolerance = 0.35,

	-- Anger gained per second, on a 0 to 1 scale, from a speed just under that limit up to a full stop.
	angerFillMin = 0.05,
	angerFillMax = 0.25,

	-- Anger lost per second while the speed holds up.
	angerDrain = 0.25,

	-- Anger levels at which warning tiers 1, 2 and 3 begin.
	angerTiers = { 0.25, 0.5, 0.75 },
}
