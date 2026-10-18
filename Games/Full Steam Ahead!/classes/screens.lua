-- The phase 2 help card, the two ending transitions, and the game-over screen.

local screens = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local scores = require( "classes.scores" )
local sheets = require( "classes.sheets" )
local config = require( "data.screens" )
local endingLines = require( "data.endingLines" )

local gameOverConfig = config.gameOver
local helpConfig = config.help

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local overlayMethods = {}
overlayMethods.__index = overlayMethods

--------------------------------------------------------------------------------------
-- Localised functions

local min = math.min
local max = math.max
local sqrt = math.sqrt
local sin = math.sin
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
	local label = display.newText( {
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

local function newHighlight( group, rowY, theme )
	local highlight = sheets.newImage( group, config.family, gameOverConfig.highlightImage, theme.highlightVariant )
	highlight.x, highlight.y = screen.centerX, rowY

	return highlight
end

local function newScoreRow( group, rowY, rankText, valueText, theme, isHighlighted )
	local font = gameOverConfig.rowFont
	local color = theme.text

	if isHighlighted then
		newHighlight( group, rowY, theme )
		font = gameOverConfig.rowHighlightFont
		color = theme.highlightText
	end

	newGameOverText( group, rankText, screen.centerX + gameOverConfig.rankColumnX, rowY, font, gameOverConfig.rowFontSize, color, 1 )
	newGameOverText( group, valueText, screen.centerX + gameOverConfig.valueColumnX, rowY, font, gameOverConfig.rowFontSize, color, 1 )
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
		local rowY = top + gameOverConfig.rowCount * gameOverConfig.rowSpacing + gameOverConfig.runGap

		newScoreRow( group, rowY, gameOverConfig.runLabel, scores.formatKnots( params.runKnots ), theme, true )
	end
end

local function newEndingLine( group, cause, theme )
	local lines = endingLines[cause]

	if not lines or #lines == 0 then
		return nil
	end

	local line = display.newText( {
		parent = group,
		text = lines[random( #lines )],
		x = screen.centerX,
		y = screen.maxY - gameOverConfig.endingLineOffsetFromBottom,
		width = gameOverConfig.endingLineWidth,
		font = gameOverConfig.endingLineFont,
		fontSize = gameOverConfig.endingLineFontSize,
		align = "center",
	} )
	line:setFillColor( unpack( theme.text ) )

	return line
end

-- Heading and numbered instructions share one left edge inside the card art's outline box.
local function newHelpCard( group )
	local card = display.newGroup()
	group:insert( card )
	card.x, card.y = screen.centerX, screen.centerY

	local panel = sheets.newImage( card, config.family, helpConfig.image )

	local heading = newLabel( card, helpConfig.heading, 0, 0, helpConfig.headingFont, helpConfig.headingFontSize, helpConfig.headingColor )
	local lines = { heading }

	for i = 1, #helpConfig.instructions do
		local text = helpConfig.instructions[i]
		lines[#lines + 1] = newLabel( card, text, 0, 0, helpConfig.instructionFont, helpConfig.instructionFontSize, helpConfig.instructionColor )
	end

	local prompt = newLabel( card, helpConfig.prompt, 0, 0, helpConfig.promptFont, helpConfig.promptFontSize, helpConfig.promptColor )
	prompt.anchorY = 0
	prompt.isVisible = false

	local shadow = helpConfig.shadowSize
	local sheet = sheets.load( config.family, helpConfig.image )
	local width = sheet.frameWidth - shadow
	local height = sheet.frameHeight - shadow
	local left = -width * 0.5 + helpConfig.paddingX
	local lineY = -height * 0.5 + helpConfig.paddingY

	for i = 1, #lines do
		local line = lines[i]
		line.anchorX, line.anchorY = 0, 0
		line.x, line.y = left, lineY
		lineY = lineY + line.height + ( i == 1 and helpConfig.headingGap or helpConfig.instructionGap )
	end

	prompt.y = lineY - helpConfig.instructionGap + helpConfig.promptGap

	-- The drop shadow is drawn into the art on its right and bottom, so the image is shifted to keep the outline centred.
	panel.x, panel.y = shadow * 0.5, shadow * 0.5

	return card, prompt
end

-- The press area sits outside the fading content group, so the button works from the first frame.
local function newPlayAgain( hitGroup, labelGroup, theme, onPress )
	local style = gameOverConfig
	local buttonX = screen.centerX
	local buttonY = screen.maxY - style.playAgainOffsetFromBottom

	local hitArea = display.newRect( hitGroup, buttonX, buttonY, style.playAgainHitWidth, style.playAgainHitHeight )
	hitArea.isVisible = false
	hitArea.isHitTestable = true

	local label = newGameOverText( labelGroup, style.playAgain, buttonX, buttonY, style.playAgainFont, style.playAgainFontSize, theme.text )

	hitArea:addEventListener( "touch", function( event )
		if event.phase == "began" then
			onPress()
		end

		return true
	end )

	return label
end

function overlayMethods:updateGameOver( dt )
	local active = self.gameOver

	if not active then
		return
	end

	active.elapsed = active.elapsed + dt
	active.content.alpha = min( 1, active.elapsed / gameOverConfig.fadeInDuration )

	local cycle = gameOverConfig.blinkOnTime + gameOverConfig.blinkOffTime
	local isOn = active.elapsed % cycle < gameOverConfig.blinkOnTime
	active.playAgain.alpha = isOn and 1 or gameOverConfig.blinkDimAlpha
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

	local sincePrompt = active.elapsed - helpConfig.lockout

	if sincePrompt < 0 then
		return
	end

	local fadeIn = min( 1, sincePrompt / helpConfig.promptFadeInDuration )
	local pulse = 1 - helpConfig.promptPulseDepth * ( 0.5 + 0.5 * sin( sincePrompt * helpConfig.promptPulseSpeed ) )

	active.prompt.isVisible = true
	active.prompt.alpha = fadeIn * pulse
end

--------------------------------------------------------------------------------------
-- Public functions

-- The card dismisses on the first press after the lockout; its own background swallows every press.
function overlayMethods:showHelp( onDismiss )
	if self.help then
		self:hideHelp()
	end

	local group = display.newGroup()
	self.group:insert( group )

	-- Takes presses while it is still transparent, so none reach the game before the card shows.
	local dim = newScreenRect( group, helpConfig.dimColor )
	dim.isHitTestable = true

	local card, prompt = newHelpCard( group )

	local help = {
		group = group,
		dim = dim,
		card = card,
		prompt = prompt,
		elapsed = 0,
	}
	self.help = help

	dim:addEventListener( "touch", function( event )
		if event.phase == "began" and self.help == help and help.elapsed >= helpConfig.lockout then
			self:hideHelp()

			if onDismiss then
				onDismiss()
			end
		end

		return true
	end )

	self:updateHelp( 0 )
end

function overlayMethods:isHelpShowing()
	return self.help ~= nil
end

function overlayMethods:playFiredTransition( centreX, centreY, onComplete )
	self:startTransition( function( group )
		return newFiredCover( group, centreX, centreY )
	end, config.firedTransition.duration, animateFired, onComplete )
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

	local logo = sheets.newImage( content, config.family, style.logoImage )
	logo.anchorY = 0
	logo.x, logo.y = centerX, top + style.logoOffsetY

	newGameOverText( content, config.credits, centerX, top + style.creditsOffsetY, style.creditsFont, style.creditsFontSize, theme.dimText )
	newGameOverText( content, style.listHeader, centerX, top + style.listHeaderOffsetY, style.listHeaderFont, style.listHeaderFontSize, theme.text )

	local divider = display.newRect( content, centerX, top + style.dividerOffsetY, style.dividerWidth, style.dividerHeight )
	divider:setFillColor( unpack( theme.divider ) )

	newScoreList( content, params, theme )
	newEndingLine( content, params.cause, theme )

	local hasPressed = false
	local playAgain = newPlayAgain( group, content, theme, function()
		if hasPressed then
			return
		end

		hasPressed = true

		if onPlayAgain then
			onPlayAgain()
		end
	end )

	self.gameOver = {
		content = content,
		playAgain = playAgain,
		elapsed = 0,
	}
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
