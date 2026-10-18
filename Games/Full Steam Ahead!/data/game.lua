return {
	-- XXX / TODO - Test: maxFrameTime <- dunno if this works. Maybe, maybe not?
	-- Longest step a single frame may take, in seconds, so a suspended HTML5 tab resumes without one giant step.
	maxFrameTime = 0.1,

	-- Seconds without any bubble in the start view before the title bubble and credits return.
	titleRestoreDelay = 4,

	-- Anger tier from which the captain's sprite takes the angry pose.
	captainAngryTier = 3,

	-- Transition tag for animations that pause with the game, under the options panel and the help card.
	transitionTag = "game",
}
