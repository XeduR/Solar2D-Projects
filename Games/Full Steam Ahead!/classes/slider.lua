-- Labelled 0..1 slider with a percentage readout, dragged by one touch at a time.

local slider = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local sheets = require( "classes.sheets" )
local drawing = require( "classes.drawing" )
local sound = require( "classes.sound" )
local hudConfig = require( "data.hud" )

local config = hudConfig.slider
local family = hudConfig.family

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local sliderMethods = {}
sliderMethods.__index = sliderMethods

--------------------------------------------------------------------------------------
-- Localised functions

local floor = math.floor

local clamp01 = drawing.clamp01

--------------------------------------------------------------------------------------
-- Private functions

local function newTrack( group )
	return sheets.newImage( group, family, config.trackImage )
end

-- The fill shows through a container as wide as the track; sliding the container right reveals more of the fill.
local function newFill( group )
	local sheet = sheets.load( family, config.fillImage )
	local clip = display.newContainer( group, sheet.frameWidth, sheet.frameHeight )
	local fill = sheets.newImage( clip, family, config.fillImage )

	return clip, fill
end

local function newHitArea( group, width, knobWidth )
	local hitArea = display.newRect( group, 0, 0, width + knobWidth, config.hitHeight )
	hitArea.isVisible = false
	hitArea.isHitTestable = true

	return hitArea
end

local function newKnob( group )
	return sheets.newSprite( group, family, config.knobImage, { config.normalTag, config.pressedTag } )
end

local function newLabel( group, text, x, font, anchorX )
	local label = display.newText( {
		parent = group,
		text = text,
		x = x,
		y = config.labelOffsetY,
		font = font,
		fontSize = config.fontSize,
	} )
	label.anchorX = anchorX
	label:setFillColor( unpack( config.textColor ) )

	return label
end

function sliderMethods:refresh()
	local value = self.value
	local left = -self.width * 0.5

	self.knob.x = left + value * self.width
	self.fillClip.x = left + value * self.width - self.width * 0.5
	self.fill.x = self.width - value * self.width
	self.readout.text = string.format( config.percentFormat, floor( value * 100 + 0.5 ) )
end

function sliderMethods:setPressed( isPressed )
	local scale = isPressed and config.knobPressedScale or 1

	self.knob.xScale, self.knob.yScale = scale, scale
	self.knob:setSequence( isPressed and config.pressedTag or config.normalTag )
end

function sliderMethods:valueAt( contentX, contentY )
	local localX = self.group:contentToLocal( contentX, contentY )

	return clamp01( localX / self.width + 0.5 )
end

function sliderMethods:dragTo( contentX, contentY )
	local value = self:valueAt( contentX, contentY )
	if value == self.value then
		return
	end

	self.value = value
	self:refresh()
	sound.play( "tick" )

	if self.onChange then
		self.onChange( value )
	end
end

function sliderMethods:touch( event )
	local phase = event.phase

	if phase == "began" then
		self.activeId = event.id
		display.getCurrentStage():setFocus( event.target, event.id )
		self:setPressed( true )
		self:dragTo( event.x, event.y )

	elseif self.activeId ~= event.id then
		return true

	elseif phase == "moved" then
		self:dragTo( event.x, event.y )

	elseif phase == "ended" or phase == "cancelled" then
		self.activeId = nil
		display.getCurrentStage():setFocus( event.target, nil )
		self:setPressed( false )

		if self.onRelease then
			self.onRelease( self.value )
		end
	end

	return true
end

--------------------------------------------------------------------------------------
-- Public functions

function sliderMethods:getValue()
	return self.value
end

-- params: label, value, onChange( value ), onRelease( value ), optional x and y of the track centre.
function slider.new( parentGroup, params )
	local control = setmetatable( {}, sliderMethods )

	control.width = sheets.load( family, config.trackImage ).frameWidth
	control.value = clamp01( params.value or 0 )
	control.onChange = params.onChange
	control.onRelease = params.onRelease

	local group = display.newGroup()
	parentGroup:insert( group )
	group.x, group.y = params.x or 0, params.y or 0
	control.group = group

	local left = -control.width * 0.5

	control.track = newTrack( group )
	control.fillClip, control.fill = newFill( group )
	control.knob = newKnob( group )
	control.hitArea = newHitArea( group, control.width, control.knob.width )
	control.hitArea:toBack()
	control.label = newLabel( group, params.label or "", left, config.font, 0 )
	control.readout = newLabel( group, "", -left, config.valueFont, 1 )

	local function onTouch( event )
		return control:touch( event )
	end

	control.hitArea:addEventListener( "touch", onTouch )
	control.knob:addEventListener( "touch", onTouch )

	control:refresh()

	return control
end

return slider
