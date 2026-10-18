-- Options panel with the volume sliders and the instructions toggle; a press anywhere outside it closes it.

local optionsPanel = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local gameText = require( "classes.gameText" )
local screen = require( "classes.screen" )
local sheets = require( "classes.sheets" )
local slider = require( "classes.slider" )
local hudConfig = require( "data.hud" )

local config = hudConfig.panel
local family = hudConfig.family
local buttons = hudConfig.buttons

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local panelMethods = {}
panelMethods.__index = panelMethods

--------------------------------------------------------------------------------------
-- Private functions

local function newBlocker( group )
	local blocker = display.newRect( group, screen.centerX, screen.centerY, screen.maxX - screen.minX, screen.maxY - screen.minY )
	blocker.isVisible = false
	blocker.isHitTestable = true

	return blocker
end

-- config.width and config.height size the panel without its shadow, so the image grows by the shadow and shifts by half of it to keep the panel in place.
local function newBackground( group )
	local shadow = config.shadowSize
	local background = sheets.newNineSlice( group, family, config.image, config.width + shadow, config.height + shadow )
	background.x, background.y = shadow * 0.5, shadow * 0.5

	return background
end

local function newTitle( group )
	local title = gameText.new( {
		parent = group,
		text = config.title,
		x = 0,
		y = -config.height * 0.5 + config.titleOffsetY,
		font = config.titleFont,
		fontSize = config.titleFontSize,
	} )
	title:setFillColor( unpack( config.titleColor ) )

	return title
end

local function newToggle( group )
	local toggle = gameText.new( {
		parent = group,
		text = config.toggleUnchecked,
		x = -config.width * 0.5 + config.paddingX,
		y = -config.height * 0.5 + config.toggleOffsetY,
		font = config.toggleFont,
		fontSize = config.toggleFontSize,
	} )
	toggle.anchorX = 0
	toggle:setFillColor( unpack( config.toggleColor ) )

	return toggle
end

function panelMethods:setOpen( isOpen )
	self.isPanelOpen = isOpen
	self.group.isVisible = isOpen
	self.blocker.isHitTestable = isOpen
end

-- The press that closes the panel keeps focus on the blocker until it ends, so the object under it never gets a lone "ended" phase.
function panelMethods:onBlockerTouch( event )
	local phase = event.phase

	if phase == "began" then
		if self.isPanelOpen then
			display.getCurrentStage():setFocus( self.blocker, event.id )
			self.blockerTouchId = event.id
			self:close()
		end

	elseif ( phase == "ended" or phase == "cancelled" ) and self.blockerTouchId == event.id then
		self.blockerTouchId = nil
		display.getCurrentStage():setFocus( self.blocker, nil )
	end

	return true
end

--------------------------------------------------------------------------------------
-- Public functions

function panelMethods:open()
	if not self.isPanelOpen then
		self:setOpen( true )
	end
end

-- Every close that changes state reports onClose, so the scene can unpause from one place.
function panelMethods:close()
	if not self.isPanelOpen then
		return
	end

	self:setOpen( false )

	if self.callbacks.onClose then
		self.callbacks.onClose()
	end
end

function panelMethods:isOpen()
	return self.isPanelOpen
end

function panelMethods:setShowInstructions( showInstructions )
	self.toggle.text = showInstructions and config.toggleChecked or config.toggleUnchecked
end

-- volumes: { master, music, sfx } in 0..1. callbacks: onChange( key, value ), onRelease( key, value ), onToggleInstructions(), onClose().
function optionsPanel.new( parentGroup, volumes, callbacks )
	local panel = setmetatable( {}, panelMethods )

	panel.callbacks = callbacks or {}
	panel.isPanelOpen = false

	local group = display.newGroup()
	parentGroup:insert( group )
	panel.group = group

	panel.blocker = newBlocker( group )

	local body = display.newGroup()
	group:insert( body )
	body.x = screen.minX + buttons.marginX + buttons.width + config.gapBesideButtons + config.width * 0.5
	body.y = screen.minY + buttons.marginY + config.height * 0.5

	panel.background = newBackground( body )
	newTitle( body )

	panel.sliders = {}
	local trackWidth = sheets.load( family, hudConfig.slider.trackImage ).frameWidth

	for i = 1, #config.sliders do
		local entry = config.sliders[i]
		local key = entry.key

		panel.sliders[key] = slider.new( body, {
			label = entry.label,
			value = volumes and volumes[key] or 0,
			x = -config.width * 0.5 + config.paddingX + trackWidth * 0.5,
			y = -config.height * 0.5 + config.firstSliderOffsetY + ( i - 1 ) * config.sliderSpacing,

			onChange = function( value )
				if panel.callbacks.onChange then
					panel.callbacks.onChange( key, value )
				end
			end,

			onRelease = function( value )
				if panel.callbacks.onRelease then
					panel.callbacks.onRelease( key, value )
				end
			end,
		} )
	end

	panel.toggle = newToggle( body )

	panel.toggle:addEventListener( "touch", function( event )
		if event.phase == "began" and panel.callbacks.onToggleInstructions then
			panel.callbacks.onToggleInstructions()
		end

		return true
	end )

	-- Presses on the panel body must not reach the blocker, which would close the panel.
	panel.background:addEventListener( "touch", function()
		return true
	end )

	panel.blocker:addEventListener( "touch", function( event )
		return panel:onBlockerTouch( event )
	end )

	panel:setOpen( false )

	return panel
end

return optionsPanel
