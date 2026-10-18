return {
	-- Filled with an effect or loop file name.
	sfxPath = "assets/audio/sfx/%s.wav",

	-- Filled with a tempo from data/bgmTempos.lua.
	bgmPath = "assets/audio/bgm/bgm-%dbpm.wav",

	-- Channels per type; the loop channels come on top, one per layer below, and everything together fills Solar2D's 32 channels.
	channels = {
		music = 2,
		babble = 1,
		sfx = 27,
	},

	-- Per effect: files from the lowest level up, volume 0..1, seconds before a replay (interval), and levels where each later file takes over (thresholds).
	-- Volumes keep every effect well under the music; the jingle plays with the music stopped, so it sits near the music's level.
	effects = {
		whoomph = { files = { "whoomphLow", "whoomphMid", "whoomphHigh" }, thresholds = { 0.35, 0.7 }, volume = 0.17, interval = 0.05 },
		burst = { files = { "burst" }, volume = 0.45, interval = 0.2 },

		launch = { files = { "launch" }, volume = 0.56, interval = 1 },
		crash = { files = { "crash" }, volume = 0.5, interval = 0.5 },
		whoosh = { files = { "whoosh" }, volume = 0.4, interval = 0.15 },

		stinger1 = { files = { "stinger1" }, volume = 0.63, interval = 0.5 },
		stinger2 = { files = { "stinger2" }, volume = 0.53, interval = 0.5 },
		stinger3 = { files = { "stinger3" }, volume = 0.53, interval = 0.5 },
		clang = { files = { "clang" }, volume = 0.67, interval = 0.3 },
		doorSlam = { files = { "doorSlam" }, volume = 0.67, interval = 0.5 },

		click = { files = { "click" }, volume = 0.63, interval = 0.05 },
		tick = { files = { "tick" }, volume = 0.63, interval = 0.04 },
		jingle = { files = { "jingle" }, volume = 1, interval = 1 },
	},

	babble = {
		-- Filled with a voice and a length.
		file = "babble%s%s",

		-- Voice per anger tier 1 to 4; tier 4 is the fired line, and tier 0 lines play no babble.
		voices = { "Cross", "Angry", "Furious", "Furious" },

		lengths = { "Short", "Medium", "Long" },

		-- Line lengths, in characters, from which the Medium and then the Long phrase plays.
		lengthThresholds = { 38, 46 },

		volume = 0.56,
	},

	-- Continuous loops: each plays its file at volume times the level 0..1 that setLayer gives, silent at 0.
	-- Smoothing is the time constant, in seconds, with which the level follows setLayer.
	layers = {
		{ name = "roar", file = "roarMid", volume = 0.71, smoothing = 0.3 },
		{ name = "thrust", file = "thrust", volume = 0.63, smoothing = 0.15 },
	},

	-- Loop gain below which a loop heading for silence stops its channel, and above which a stopped loop starts.
	silentGain = 0.002,

	tempo = {
		-- Knots at which each tempo after the slowest in data/bgmTempos.lua takes over.
		thresholds = { 10, 1e5, 1e6, 1e7, 5e7, 1e8, 2.5e8 },

		-- Share of a threshold the knots must fall below before the music drops back past it, so a speed hovering at a threshold never flaps.
		downFactor = 0.5,

		-- Minimum seconds between two tempo switches; above crossFade, so the two music channels always suffice.
		hold = 0.75,

		-- Seconds over which the old tempo fades out while the new one fades in.
		crossFade = 0.35,
	},

	-- Seconds over which music started by restartMusic or reset fades in.
	musicFadeIn = 1.5,

	-- Seconds from the game-over jingle's start until the music returns, so the jingle plays alone.
	gameOverMusicDelay = 2.5,
}
