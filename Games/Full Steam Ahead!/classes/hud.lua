-- The knots readout and the Reset and Options buttons.

local hud = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local scores = require( "classes.scores" )
local sheets = require( "classes.sheets" )
local config = require( "data.hud" )

local knotsConfig = config.knots
local buttonConfig = config.buttons
local family = config.family

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local hudMethods = {}
hudMethods.__index = hudMethods

--------------------------------------------------------------------------------------
-- Localised functions

local floor = math.floor
local log10 = math.log10
local max = math.max

--------------------------------------------------------------------------------------
-- Private functions

local function newKnotsPlate( group )
	local plate = sheets.newImage( group, family, knotsConfig.plateImage )
	plate.anchorX = 0
	plate.alpha = knotsConfig.plateAlpha

	return plate
end

local function newKnotsText( group, color, offset )
	local text = display.newText( {
		parent = group,
		text = "",
		x = knotsConfig.platePaddingX + offset,
		y = offset,
		font = knotsConfig.font,
		fontSize = knotsConfig.fontSize,
	} )
	text.anchorX = 0
	text:setFillColor( unpack( color ) )

	return text
end

local function newButtonBackground( group )
	return sheets.newNineSlice( group, family, buttonConfig.image, buttonConfig.width, buttonConfig.height, buttonConfig.normalTag )
end

local function newButtonLabel( group, text )
	local label = display.newText( {
		parent = group,
		text = text,
		x = 0,
		y = 0,
		font = buttonConfig.font,
		fontSize = buttonConfig.fontSize,
	} )
	label:setFillColor( unpack( buttonConfig.textColor ) )

	return label
end

local function setButtonPressed( button, isPressed )
	local scale = isPressed and buttonConfig.pressedScale or 1

	button.group.xScale, button.group.yScale = scale, scale
	button.background:setFrame( isPressed and buttonConfig.pressedTag or buttonConfig.normalTag )
end

-- The pressed look ends on a timer in update() and the button takes no touch focus, so a callback that rebuilds the HUD leaves no focus behind.
local function newButton( parentGroup, text, x, y, onPress )
	local button = {}

	local group = display.newGroup()
	parentGroup:insert( group )
	button.group = group

	button.background = newButtonBackground( group )
	button.label = newButtonLabel( group, text )
	button.pressedTime = 0

	group.x, group.y = x, y

	group:addEventListener( "touch", function( event )
		if event.phase == "began" then
			button.pressedTime = buttonConfig.pressedDuration
			setButtonPressed( button, true )

			if onPress then
				onPress()
			end
		end

		return true
	end )

	return button
end

local function updateButton( button, dt )
	if button.pressedTime <= 0 then
		return
	end

	button.pressedTime = button.pressedTime - dt
	if button.pressedTime <= 0 then
		setButtonPressed( button, false )
	end
end

local function decadeOf( knots )
	return floor( log10( max( knots, 1 ) ) )
end

-- Text objects re-render their texture on every change, which is costly on HTML5, so the readout refreshes at a capped rate.
function hudMethods:refreshKnotsText()
	self.refreshTime = knotsConfig.refreshInterval
	self.isRefreshForced = false

	local text = scores.formatKnots( self.knots )
	if text == self.knotsText.text then
		return
	end

	self.knotsText.text = text
	self.knotsShadow.text = text
end

function hudMethods:checkPunch( knots, previous )
	if knots < knotsConfig.punchMinKnots or self.punchCooldown > 0 then
		return
	end

	local decade = decadeOf( knots )
	local isJump = previous > 0 and knots >= previous * ( 1 + knotsConfig.punchJumpRatio )

	if isJump or decade > self.punchDecade then
		self.punchDecade = max( self.punchDecade, decade )
		self.punchTime = knotsConfig.punchDuration
		self.punchCooldown = knotsConfig.punchCooldown + knotsConfig.punchDuration
		self.isRefreshForced = true
	end
end

function hudMethods:updatePunch( dt )
	self.punchCooldown = max( 0, self.punchCooldown - dt )

	if self.punchTime <= 0 and self.isPunchSettled then
		return
	end

	self.punchTime = max( 0, self.punchTime - dt )
	self.isPunchSettled = self.punchTime <= 0

	local progress = self.punchTime / knotsConfig.punchDuration
	local strength = progress * progress

	local scale = 1 + knotsConfig.punchScale * strength
	self.knotsGroup.xScale, self.knotsGroup.yScale = scale, scale

	local base = knotsConfig.textColor
	local flash = knotsConfig.punchColor
	self.knotsText:setFillColor(
		base[1] + ( flash[1] - base[1] ) * strength,
		base[2] + ( flash[2] - base[2] ) * strength,
		base[3] + ( flash[3] - base[3] ) * strength
	)
end

--------------------------------------------------------------------------------------
-- Public functions

function hudMethods:setKnots( knots )
	local previous = self.knots
	self.knots = knots

	self:checkPunch( knots, previous )
end

function hudMethods:showKnots( isVisible )
	self.knotsGroup.isVisible = isVisible
end

function hudMethods:update( dt )
	self.refreshTime = self.refreshTime - dt

	if self.isRefreshForced or self.refreshTime <= 0 then
		self:refreshKnotsText()
	end

	self:updatePunch( dt )

	for i = 1, #self.buttons do
		updateButton( self.buttons[i], dt )
	end
end

-- callbacks: onReset(), onOptions().
function hud.new( parentGroup, callbacks )
	local bar = setmetatable( {}, hudMethods )
	callbacks = callbacks or {}

	local group = display.newGroup()
	parentGroup:insert( group )
	bar.group = group

	-- The readout scales from its left edge, so the punch grows away from the Options button.
	local knotsGroup = display.newGroup()
	group:insert( knotsGroup )
	bar.knotsGroup = knotsGroup

	local columnLeft = screen.minX + buttonConfig.marginX
	local buttonX = columnLeft + buttonConfig.width * 0.5
	local optionsY = screen.minY + buttonConfig.marginY + buttonConfig.height * 0.5

	bar.knotsPlate = newKnotsPlate( knotsGroup )
	knotsGroup.x = columnLeft + buttonConfig.width + buttonConfig.gap
	knotsGroup.y = optionsY

	bar.knotsShadow = newKnotsText( knotsGroup, knotsConfig.shadowColor, knotsConfig.shadowOffset )
	bar.knotsText = newKnotsText( knotsGroup, knotsConfig.textColor, 0 )

	bar.knots = 0
	bar.punchTime = 0
	bar.punchCooldown = 0
	bar.isPunchSettled = true
	bar.punchDecade = decadeOf( knotsConfig.punchMinKnots ) - 1

	local optionsButton = newButton( group, buttonConfig.optionsLabel, buttonX, optionsY, function()
		if callbacks.onOptions then
			callbacks.onOptions()
		end
	end )

	local resetY = optionsY + buttonConfig.height + buttonConfig.gap
	local resetButton = newButton( group, buttonConfig.resetLabel, buttonX, resetY, function()
		if callbacks.onReset then
			callbacks.onReset()
		end
	end )

	bar.buttons = { optionsButton, resetButton }

	bar:refreshKnotsText()

	return bar
end

return hud
