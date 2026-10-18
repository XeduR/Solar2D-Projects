-- The phase 2 help card, the two ending transitions, and the game-over screen.

local screens = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local gameText = require( "classes.gameText" )
local hud = require( "classes.hud" )
local scores = require( "classes.scores" )
local sheets = require( "classes.sheets" )
local sound = require( "classes.sound" )
local textBlock = require( "classes.textBlock" )
local config = require( "data.screens" )
local endingLines = require( "data.endingLines" )

local gameOverConfig = config.gameOver
local helpConfig = config.help
local promptConfig = config.prompt

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local overlayMethods = {}
overlayMethods.__index = overlayMethods

--------------------------------------------------------------------------------------
-- Localised functions

local min = math.min
local max = math.max
local sqrt = math.sqrt
local random = math.random

--------------------------------------------------------------------------------------
-- Private functions

local function swallowTouch()
	return true
end

local function newScreenRect( group, color )
	local rect = display.newRect( group, screen.centerX, screen.centerY, screen.maxX - screen.minX, screen.maxY - screen.minY )
	rect:setFillColor( unpack( color ) )

	return rect
end

local function newLabel( group, text, labelX, labelY, font, fontSize, color )
	local label = gameText.new( {
		parent = group,
		text = text,
		x = labelX,
		y = labelY,
		font = font,
		fontSize = fontSize,
	} )
	label:setFillColor( unpack( color ) )

	return label
end

-- Distance from the circle's centre to the farthest screen corner, so a circle of this radius covers the screen.
local function coverRadius( centreX, centreY, margin )
	local distanceX = max( centreX - screen.minX, screen.maxX - centreX )
	local distanceY = max( centreY - screen.minY, screen.maxY - centreY )

	return sqrt( distanceX * distanceX + distanceY * distanceY ) + margin
end

local function setScale( object, scale )
	object.xScale, object.yScale = scale, scale
end

local function easeInOutCubic( progress )
	if progress < 0.5 then
		return 4 * progress * progress * progress
	end

	local inverse = 2 - 2 * progress

	return 1 - inverse * inverse * inverse * 0.5
end

local function easeOutQuad( progress )
	return 1 - ( 1 - progress ) * ( 1 - progress )
end

local function newFiredCover( group, centreX, centreY )
	local style = config.firedTransition
	local circle = display.newCircle( group, centreX, centreY, coverRadius( centreX, centreY, style.radiusMargin ) )
	circle:setFillColor( unpack( style.color ) )
	setScale( circle, style.minScale )

	return { circle = circle }
end

local function newCrashCover( group, centreX, centreY )
	local style = config.crashTransition
	local radius = coverRadius( centreX, centreY, style.radiusMargin )

	local flash = newScreenRect( group, style.flashColor )
	flash.alpha = 0

	local ring = display.newCircle( group, centreX, centreY, radius * style.ringScale )
	ring:setFillColor( unpack( style.ringColor ) )
	ring.alpha = style.ringAlpha
	setScale( ring, style.minScale )

	local circle = display.newCircle( group, centreX, centreY, radius )
	circle:setFillColor( unpack( style.color ) )
	setScale( circle, style.minScale )

	return { flash = flash, ring = ring, circle = circle }
end

local function animateFired( cover, progress )
	setScale( cover.circle, max( config.firedTransition.minScale, easeInOutCubic( progress ) ) )
end

local function animateCrash( cover, progress )
	local style = config.crashTransition
	local scale = max( style.minScale, easeOutQuad( progress ) )

	setScale( cover.circle, scale )
	setScale( cover.ring, scale )
	cover.ring.alpha = style.ringAlpha * ( 1 - progress )

	if progress < style.flashPeakTime then
		cover.flash.alpha = style.flashPeakAlpha * progress / style.flashPeakTime
	else
		local settle = ( progress - style.flashPeakTime ) / ( 1 - style.flashPeakTime )
		local sag = style.flashPeakAlpha + ( style.flashFloorAlpha - style.flashPeakAlpha ) * min( 1, settle * style.flashSagSpeed )
		cover.flash.alpha = sag + ( 1 - sag ) * settle * settle
	end
end

function overlayMethods:startTransition( cover, duration, animate, onComplete )
	display.remove( self.transitionGroup )

	-- The cover stays up after completion, so the game-over screen fades in over a solid colour.
	local group = display.newGroup()
	self.group:insert( group )
	group:addEventListener( "touch", swallowTouch )
	self.transitionGroup = group

	self.transition = {
		cover = cover( group ),
		duration = duration,
		animate = animate,
		onComplete = onComplete,
		elapsed = 0,
	}

	animate( self.transition.cover, 0 )
end

function overlayMethods:updateTransition( dt )
	local active = self.transition

	if not active then
		return
	end

	active.elapsed = min( active.duration, active.elapsed + dt )
	active.animate( active.cover, active.elapsed / active.duration )

	if active.elapsed >= active.duration then
		self.transition = nil

		if active.onComplete then
			active.onComplete()
		end
	end
end

local function newGameOverText( group, text, labelX, labelY, font, fontSize, color, anchorX )
	local label = newLabel( group, text, labelX, labelY, font, fontSize, color )
	label.anchorX = anchorX or 0.5

	return label
end

-- Spans both of the row's right-aligned labels, from the rank text's left edge to the value column, and goes behind them.
local function newHighlight( group, rankLabel, valueLabel, theme )
	local left = rankLabel.x - rankLabel.width - gameOverConfig.highlightMarginX
	local right = valueLabel.x + gameOverConfig.highlightMarginX

	local width = right - left
	local highlight = sheets.newNineSlice( group, config.family, gameOverConfig.highlightImage, width, gameOverConfig.highlightHeight, theme.highlightVariant )
	highlight.x, highlight.y = ( left + right ) * 0.5, rankLabel.y

	gameText.toFront( rankLabel )
	gameText.toFront( valueLabel )

	return highlight
end

local function newScoreRow( group, rowY, rankText, valueText, theme, isHighlighted )
	local font = gameOverConfig.rowFont
	local color = theme.text

	if isHighlighted then
		font = gameOverConfig.rowHighlightFont
		color = theme.highlightText
	end

	local rankLabel = newGameOverText( group, rankText, screen.centerX + gameOverConfig.rankColumnX, rowY, font, gameOverConfig.rowFontSize, color, 1 )
	local valueLabel = newGameOverText( group, valueText, screen.centerX + gameOverConfig.valueColumnX, rowY, font, gameOverConfig.rowFontSize, color, 1 )

	if isHighlighted then
		newHighlight( group, rankLabel, valueLabel, theme )
	end
end

-- The run's own row sits below the list, past an extra gap.
local function runRowY()
	return screen.minY + gameOverConfig.listOffsetY + gameOverConfig.rowCount * gameOverConfig.rowSpacing + gameOverConfig.runGap
end

local function newScoreList( group, params, theme )
	local list = params.list or {}
	local top = screen.minY + gameOverConfig.listOffsetY

	for i = 1, gameOverConfig.rowCount do
		local rowY = top + ( i - 1 ) * gameOverConfig.rowSpacing
		local valueText = list[i] and scores.formatKnots( list[i] ) or gameOverConfig.emptyValue

		newScoreRow( group, rowY, string.format( gameOverConfig.rankFormat, i ), valueText, theme, params.rank == i )
	end

	if not params.rank and params.runKnots then
		newScoreRow( group, runRowY(), gameOverConfig.runLabel, scores.formatKnots( params.runKnots ), theme, true )
	end
end

local function newEndingLine( group, cause, theme )
	local lines = endingLines[cause]

	if not lines or #lines == 0 then
		return nil
	end

	local style = gameOverConfig

	-- The run row's highlight slot is used even when the run made the list, so the line never moves.
	local above = runRowY() + style.highlightHeight * 0.5
	local below = screen.maxY - style.endingLineFloorOffset

	local line = textBlock.new( {
		parent = group,
		text = lines[random( #lines )],
		x = screen.centerX,
		y = ( above + below ) * 0.5,
		width = style.endingLineWidth,
		font = style.endingLineFont,
		fontSize = style.endingLineFontSize,
		align = "center",
		colour = theme.text,
	} )

	return line
end

local function helpToggleText( showInstructions )
	return showInstructions and helpConfig.toggleUnchecked or helpConfig.toggleChecked
end

-- Heading, instructions, and the toggle share one left edge; the card is sized around all of its lines, prompt included.
local function newHelpCard( group, showInstructions )
	local card = display.newGroup()
	group:insert( card )
	card.x, card.y = screen.centerX, screen.centerY

	local heading = newLabel( card, helpConfig.heading, 0, 0, helpConfig.headingFont, helpConfig.headingFontSize, helpConfig.headingColor )
	local lines = { heading }

	for i = 1, #helpConfig.instructions do
		local text = helpConfig.instructions[i]
		lines[#lines + 1] = newLabel( card, text, 0, 0, helpConfig.instructionFont, helpConfig.instructionFontSize, helpConfig.instructionColor )
	end

	local toggle = newLabel( card, helpToggleText( showInstructions ), 0, 0, helpConfig.toggleFont, helpConfig.toggleFontSize, helpConfig.toggleColor )
	local prompt = newLabel( card, helpConfig.prompt, 0, 0, promptConfig.font, promptConfig.fontSize, helpConfig.promptColor )
	prompt.isVisible = false

	local lineY = 0

	for i = 1, #lines do
		lines[i].y = lineY
		lineY = lineY + lines[i].height + ( i == 1 and helpConfig.headingGap or helpConfig.instructionGap )
	end

	toggle.y = lineY - helpConfig.instructionGap + helpConfig.toggleGap
	prompt.y = toggle.y + toggle.height + helpConfig.promptGap

	lines[#lines + 1] = toggle
	lines[#lines + 1] = prompt

	local contentWidth = 0
	for i = 1, #lines do
		contentWidth = max( contentWidth, lines[i].width )
	end

	local width = contentWidth + helpConfig.paddingX * 2
	local height = prompt.y + prompt.height + helpConfig.paddingY * 2
	local left = -width * 0.5 + helpConfig.paddingX
	local top = -height * 0.5 + helpConfig.paddingY

	for i = 1, #lines do
		local line = lines[i]
		line.anchorX, line.anchorY = 0, 0
		line.x, line.y = left, line.y + top
	end

	-- The drop shadow is drawn into the art on its right and bottom, so the image grows by it and shifts to keep the outline centred.
	local shadow = helpConfig.shadowSize
	local panel = sheets.newNineSlice( card, config.family, helpConfig.image, width + shadow, height + shadow )
	panel.x, panel.y = shadow * 0.5, shadow * 0.5
	panel:toBack()

	return card, prompt, toggle
end

-- Hidden until the delay passes, then blinks between lit and dim, starting lit.
local function updatePrompt( prompt, elapsed, delay )
	local sinceShown = elapsed - delay

	prompt.isVisible = sinceShown >= 0

	if sinceShown < 0 then
		return
	end

	local cycle = promptConfig.blinkOnTime + promptConfig.blinkOffTime
	local isOn = sinceShown % cycle < promptConfig.blinkOnTime

	prompt.alpha = isOn and 1 or promptConfig.blinkDimAlpha
end

function overlayMethods:updateGameOver( dt )
	local active = self.gameOver

	if not active then
		return
	end

	active.elapsed = active.elapsed + dt
	active.content.alpha = min( 1, active.elapsed / gameOverConfig.fadeInDuration )

	updatePrompt( active.prompt, active.elapsed, promptConfig.delay )
end

function overlayMethods:hideHelp()
	display.remove( self.help.group )
	self.help = nil
end

function overlayMethods:updateHelp( dt )
	local active = self.help

	if not active then
		return
	end

	active.elapsed = active.elapsed + dt

	local pop = min( 1, active.elapsed / helpConfig.popDuration )
	local scale = helpConfig.popStartScale + ( 1 - helpConfig.popStartScale ) * easeOutQuad( pop )

	setScale( active.card, scale )
	active.card.alpha = pop
	active.dim.alpha = pop

	updatePrompt( active.prompt, active.elapsed, helpConfig.promptDelay )
end

--------------------------------------------------------------------------------------
-- Public functions

-- The card closes through dismissHelp; its own background swallows every press.
-- toggle: optional { showInstructions, onToggle() }; pressing the toggle text reports onToggle and leaves the card open.
function overlayMethods:showHelp( onDismiss, toggle )
	if self.help then
		self:hideHelp()
	end

	local group = display.newGroup()
	self.group:insert( group )

	-- Takes presses while it is still transparent, so none reach the game before the card shows.
	local dim = newScreenRect( group, helpConfig.dimColor )
	dim.isHitTestable = true

	local showInstructions = true
	local onToggle

	if toggle then
		showInstructions = toggle.showInstructions
		onToggle = toggle.onToggle
	end

	local card, prompt, toggleLabel = newHelpCard( group, showInstructions )

	local help = {
		group = group,
		dim = dim,
		card = card,
		prompt = prompt,
		toggle = toggleLabel,
		elapsed = 0,
		onDismiss = onDismiss,
	}
	self.help = help

	dim:addEventListener( "touch", function()
		return true
	end )

	toggleLabel:addEventListener( "touch", function( event )
		if event.phase == "began" and onToggle then
			onToggle()
		end

		return true
	end )

	self:updateHelp( 0 )
end

function overlayMethods:setShowInstructions( showInstructions )
	if self.help then
		self.help.toggle.text = helpToggleText( showInstructions )
	end
end

-- A key press closes the card only once its prompt shows; returns whether it closed.
function overlayMethods:dismissHelp()
	local help = self.help

	if not help or help.elapsed < helpConfig.promptDelay then
		return false
	end

	sound.play( "click" )
	self:hideHelp()

	if help.onDismiss then
		help.onDismiss()
	end

	return true
end

function overlayMethods:isHelpShowing()
	return self.help ~= nil
end

function overlayMethods:playFiredTransition( centreX, centreY, onComplete )
	self:startTransition( function( group )
		return newFiredCover( group, centreX, centreY )
	end, config.firedTransition.duration, animateFired, function()
		sound.play( "doorSlam" )

		if onComplete then
			onComplete()
		end
	end )
end

function overlayMethods:playCrashTransition( centreX, centreY, onComplete )
	self:startTransition( function( group )
		return newCrashCover( group, centreX, centreY )
	end, config.crashTransition.duration, animateCrash, onComplete )
end

-- params: theme (a gameOver.themes key), cause (an endingLines key), list (top speeds, highest first), rank (the run's place on the list, or nil), runKnots.
function overlayMethods:showGameOver( params, onPlayAgain )
	display.remove( self.gameOverGroup )

	local theme = gameOverConfig.themes[params.theme] or gameOverConfig.themes.fired

	local group = display.newGroup()
	self.group:insert( group )
	self.gameOverGroup = group

	local background = newScreenRect( group, theme.background )
	background:addEventListener( "touch", swallowTouch )

	local content = display.newGroup()
	group:insert( content )
	content.alpha = 0

	local centerX = screen.centerX
	local top = screen.minY
	local style = gameOverConfig

	local buttons = hud.buttonLayout()
	local logo = sheets.newImage( content, config.family, style.logoImage )
	logo.x, logo.y = centerX, buttons.top + logo.contentHeight * 0.5

	textBlock.new( {
		parent = content,
		text = table.concat( config.credits, "\n" ),
		x = centerX,
		y = top + style.creditsOffsetY,
		font = style.creditsFont,
		fontSize = style.creditsFontSize,
		align = "center",
		colour = theme.dimText,
	} )

	newGameOverText( content, style.listHeader, centerX, top + style.listHeaderOffsetY, style.listHeaderFont, style.listHeaderFontSize, theme.text )

	local divider = display.newRect( content, centerX, top + style.dividerOffsetY, style.dividerWidth, style.dividerHeight )
	divider:setFillColor( unpack( theme.divider ) )

	newScoreList( content, params, theme )
	newEndingLine( content, params.cause, theme )

	-- Outside the fading content group, so the blink alone decides how it shows.
	local promptY = screen.maxY - style.promptOffsetFromBottom
	local prompt = newGameOverText( group, style.prompt, centerX, promptY, promptConfig.font, promptConfig.fontSize, theme.text )

	self.gameOver = {
		content = content,
		prompt = prompt,
		elapsed = 0,
		onPlayAgain = onPlayAgain,
	}

	updatePrompt( prompt, 0, promptConfig.delay )
end

-- Any key plays again once the prompt shows; earlier keys are swallowed. Returns whether it played again.
function overlayMethods:pressGameOverKey()
	local active = self.gameOver

	if not active or active.hasPlayedAgain or active.elapsed < promptConfig.delay then
		return false
	end

	active.hasPlayedAgain = true

	if active.onPlayAgain then
		active.onPlayAgain()
	end

	-- After onPlayAgain, since starting a new game stops every effect.
	sound.play( "click" )

	return true
end

function overlayMethods:update( dt )
	self:updateHelp( dt )
	self:updateTransition( dt )
	self:updateGameOver( dt )
end

function screens.new( parentGroup )
	local overlay = setmetatable( {}, overlayMethods )

	local group = display.newGroup()
	parentGroup:insert( group )
	overlay.group = group

	return overlay
end

return screens
