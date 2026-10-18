-- The captain's speech bubbles: title, quips, warnings, and speed milestones.

local captain = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local screen = require( "classes.screen" )
local sheets = require( "classes.sheets" )
local drawing = require( "classes.drawing" )
local gameText = require( "classes.gameText" )
local textBlock = require( "classes.textBlock" )
local sound = require( "classes.sound" )
local config = require( "data.captain" )
local lines = require( "data.captainLines" )
local credits = table.concat( require( "data.screens" ).credits, " " )
local pixelScale = require( "data.art" ).pixelScale

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local bubbleMethods = {}
bubbleMethods.__index = bubbleMethods

local captainMethods = {}
captainMethods.__index = captainMethods

--------------------------------------------------------------------------------------
-- Localised functions

local random = math.random
local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local exp = math.exp
local min = math.min
local max = math.max
local abs = math.abs
local ceil = math.ceil

local clamp = drawing.clamp
local clamp01 = drawing.clamp01

--------------------------------------------------------------------------------------
-- Private functions

-- Centred boxes snap up to an even number of art pixels, so both edges land on whole art pixels.
local function snapToPixels( size )
	local step = pixelScale * 2

	return ceil( size / step ) * step
end

local function lineDuration( text )
	local duration = config.durationBase + config.durationPerCharacter * #text

	return clamp( duration, config.durationMin, config.durationMax )
end

local function popScale( progress )
	local pop = config.pop

	if progress >= 1 then
		return 1
	end

	local shifted = progress - 1
	local eased = 1 + ( pop.overshoot + 1 ) * shifted * shifted * shifted + pop.overshoot * shifted * shifted

	return pop.startScale + ( 1 - pop.startScale ) * eased
end

local function newBubbleText( group, text, style )
	local label = textBlock.new( {
		parent = group,
		text = text,
		font = style.font,
		fontSize = style.fontSize,
		width = style.maxTextWidth,
		align = "center",
		colour = style.textColour,
	} )

	return label.blockWidth, label.blockHeight
end

-- The logo with the credit line under it, centred on the group origin.
local function newTitleContent( group, style )
	local logo = sheets.newImage( group, config.family, config.logoImage )
	logo.anchorY = 0

	local creditLine = gameText.new( {
		parent = group,
		text = credits,
		x = 0,
		y = 0,
		font = style.creditsFont,
		fontSize = style.creditsFontSize,
	} )
	creditLine.anchorY = 0
	creditLine:setFillColor( unpack( style.textColour ) )

	-- The logo is drawn scaled up, so its on-screen size is contentWidth and contentHeight, not width and height.
	local logoWidth, logoHeight = logo.contentWidth, logo.contentHeight
	local width = max( logoWidth, creditLine.width )
	local height = snapToPixels( logoHeight + style.creditsGap + creditLine.height )
	local top = -height * 0.5

	logo.y = top
	creditLine.y = top + logoHeight + style.creditsGap

	return width, height
end

-- The drop shadow is drawn into the art on its right and bottom, so the image is that much larger and shifted to keep the outline centred.
local function newBubbleBody( group, width, height, variant )
	local body = sheets.newNineSlice( group, config.family, config.bubbleImage, width + config.shadowOffsetX, height + config.shadowOffsetY, variant )
	body.x = config.shadowOffsetX * 0.5
	body.y = config.shadowOffsetY * 0.5

	return body
end

local function newBubbleTail( group, vertices, colour )
	local tail = drawing.newPolygonAt( group, vertices )
	tail:setFillColor( unpack( colour ) )

	return tail
end

-- Picks the bubble side facing the anchor and the point on it where the tail starts, away from the rounded corners.
local function findTailBase( halfWidth, halfHeight, cornerSize, anchorX, anchorY )
	local reach = config.tail.baseHalfWidth + cornerSize
	local spanX = max( 0, halfWidth - reach )
	local spanY = max( 0, halfHeight - reach )

	if anchorY > halfHeight then
		return clamp( anchorX, -spanX, spanX ), halfHeight, 0, 1
	elseif anchorY < -halfHeight then
		return clamp( anchorX, -spanX, spanX ), -halfHeight, 0, -1
	elseif anchorX > halfWidth then
		return halfWidth, clamp( anchorY, -spanY, spanY ), 1, 0
	elseif anchorX < -halfWidth then
		return -halfWidth, clamp( anchorY, -spanY, spanY ), -1, 0
	end

	return nil
end

-- The tail leaves the bubble edge straight out, curves towards the anchor, and narrows to a point; widen thickens it for the outline.
local function buildTailVertices( baseX, baseY, normalX, normalY, anchorX, anchorY, widen )
	local tail = config.tail
	local towardX = anchorX - baseX
	local towardY = anchorY - baseY
	local distance = sqrt( towardX * towardX + towardY * towardY )

	if distance < tail.minLength + tail.tipGap then
		return nil
	end

	local startX = baseX - normalX * tail.inset
	local startY = baseY - normalY * tail.inset
	local controlX = baseX + normalX * distance * tail.bend
	local controlY = baseY + normalY * distance * tail.bend
	local tipX = anchorX - towardX / distance * ( tail.tipGap - widen )
	local tipY = anchorY - towardY / distance * ( tail.tipGap - widen )

	local leftSide = {}
	local rightSide = {}
	local segments = tail.segments

	for step = 0, segments - 1 do
		local progress = step / segments
		local inverse = 1 - progress
		local pointX = inverse * inverse * startX + 2 * inverse * progress * controlX + progress * progress * tipX
		local pointY = inverse * inverse * startY + 2 * inverse * progress * controlY + progress * progress * tipY
		local tangentX = 2 * inverse * ( controlX - startX ) + 2 * progress * ( tipX - controlX )
		local tangentY = 2 * inverse * ( controlY - startY ) + 2 * progress * ( tipY - controlY )
		local tangentLength = max( sqrt( tangentX * tangentX + tangentY * tangentY ), 0.0001 )
		local halfWidth = tail.baseHalfWidth * inverse + widen
		local offsetX = -tangentY / tangentLength * halfWidth
		local offsetY = tangentX / tangentLength * halfWidth

		leftSide[#leftSide + 1] = { pointX + offsetX, pointY + offsetY }
		rightSide[#rightSide + 1] = { pointX - offsetX, pointY - offsetY }
	end

	local vertices = {}

	for i = 1, #leftSide do
		vertices[#vertices + 1] = leftSide[i][1]
		vertices[#vertices + 1] = leftSide[i][2]
	end

	vertices[#vertices + 1] = tipX
	vertices[#vertices + 1] = tipY

	for i = #rightSide, 1, -1 do
		vertices[#vertices + 1] = rightSide[i][1]
		vertices[#vertices + 1] = rightSide[i][2]
	end

	return vertices
end

local function newBubble( parentGroup )
	local bubble = setmetatable( {}, bubbleMethods )

	bubble.group = display.newGroup()
	parentGroup:insert( bubble.group )

	bubble.isShown = false
	bubble.isBelow = false

	return bubble
end

function bubbleMethods:clear()
	if self.content then
		display.remove( self.content )
		self.content = nil
	end

	self.isShown = false
end

function bubbleMethods:hide()
	self:clear()
end

-- Without text, the bubble shows the logo and credits.
function bubbleMethods:show( text, style )
	self:clear()

	local content = display.newGroup()
	self.group:insert( content )
	self.content = content

	-- Each layer gets its own group, so the tail pieces keep their draw order when they are redrawn.
	local function newSlot()
		local slot = display.newGroup()
		content:insert( slot )

		return slot
	end

	-- The fill tail covers the body outline where it joins, so it draws over the body.
	self.shadowTailSlot = newSlot()
	self.edgeTailSlot = newSlot()
	local bodySlot = newSlot()
	self.fillTailSlot = newSlot()

	local contentWidth, contentHeight

	if text then
		contentWidth, contentHeight = newBubbleText( content, text, style )
	else
		contentWidth, contentHeight = newTitleContent( content, style )
	end

	local edge = config.edgeWidth
	local outerWidth = snapToPixels( contentWidth + style.padding * 2 )
	local outerHeight = snapToPixels( contentHeight + style.padding * 2 )
	local body = newBubbleBody( bodySlot, outerWidth, outerHeight, style.variant )

	self.shadowTailSlot.x = config.shadowOffsetX
	self.shadowTailSlot.y = config.shadowOffsetY

	self.style = style
	self.tailFillColour = config.tailFillColours[style.variant]
	self.cornerSize = body.sheet.nineSlice.columns[1] * pixelScale
	self.halfWidth = outerWidth * 0.5 - edge
	self.halfHeight = outerHeight * 0.5 - edge
	self.outerHalfWidth = outerWidth * 0.5
	self.outerHalfHeight = outerHeight * 0.5
	self.age = 0
	self.tailAnchorX = nil
	self.tailAnchorY = nil
	self.isShown = true
	self.hasPosition = false
	self.group.alpha = 1
end

function bubbleMethods:clearTail()
	local slots = { self.shadowTailSlot, self.edgeTailSlot, self.fillTailSlot }

	for i = 1, #slots do
		local slot = slots[i]

		for child = slot.numChildren, 1, -1 do
			display.remove( slot[child] )
		end
	end
end

function bubbleMethods:updateTail( localAnchorX, localAnchorY )
	local threshold = config.tail.rebuildThreshold

	if self.tailAnchorX and abs( localAnchorX - self.tailAnchorX ) < threshold and abs( localAnchorY - self.tailAnchorY ) < threshold then
		return
	end

	self.tailAnchorX = localAnchorX
	self.tailAnchorY = localAnchorY
	self:clearTail()

	local baseX, baseY, normalX, normalY = findTailBase( self.halfWidth, self.halfHeight, self.cornerSize, localAnchorX, localAnchorY )

	if not baseX then
		return
	end

	local outline = buildTailVertices( baseX, baseY, normalX, normalY, localAnchorX, localAnchorY, config.edgeWidth )
	local fill = buildTailVertices( baseX, baseY, normalX, normalY, localAnchorX, localAnchorY, 0 )

	if not outline or not fill then
		return
	end

	newBubbleTail( self.shadowTailSlot, outline, config.shadowColour )
	newBubbleTail( self.edgeTailSlot, outline, config.edgeColour )
	newBubbleTail( self.fillTailSlot, fill, self.tailFillColour )
end

function bubbleMethods:update( dt, targetX, targetY, anchorX, anchorY )
	if not self.isShown then
		return
	end

	self.age = self.age + dt

	if self.hasPosition then
		local blend = 1 - exp( -config.followRate * dt )

		self.centreX = self.centreX + ( targetX - self.centreX ) * blend
		self.centreY = self.centreY + ( targetY - self.centreY ) * blend
	else
		self.centreX = targetX
		self.centreY = targetY
		self.hasPosition = true
	end

	-- Fits the same box clampToScreen keeps inside the margins, so an oversized bubble is never centred across a screen edge.
	local margin = config.screenMargin
	local boxWidth = self.outerHalfWidth * 2 + max( config.shadowOffsetX, 0 )
	local boxHeight = self.outerHalfHeight * 2 + max( config.shadowOffsetY, 0 )
	local fitScale = min( ( screen.maxX - screen.minX - margin * 2 ) / boxWidth, ( screen.maxY - screen.minY - margin * 2 ) / boxHeight )
	local scale = min( popScale( self.age / config.pop.duration ), fitScale )
	local restX, restY = self:clampToScreen( self.centreX, self.centreY, 1 )

	local shake = self.style.shake
	local shakeAngle = self.age * config.shakeSpeed
	local bubbleX = restX + sin( shakeAngle ) * shake
	local bubbleY = restY + cos( shakeAngle * config.shakeVerticalSpeedRatio ) * shake * config.shakeVerticalAmplitude

	bubbleX, bubbleY = self:clampToScreen( bubbleX, bubbleY, scale )

	local group = self.group
	group.x = bubbleX
	group.y = bubbleY
	group.xScale = scale
	group.yScale = scale

	-- At full size the tail is aimed from the unshaken position, so it shakes along with the bubble instead of being redrawn every frame.
	-- While the bubble pops in, the tail is aimed from its scaled position so the tip stays on the anchor.
	if scale == 1 then
		self:updateTail( anchorX - restX, anchorY - restY )
	else
		self:updateTail( ( anchorX - bubbleX ) / scale, ( anchorY - bubbleY ) / scale )
	end
end

-- Keeps the bubble, drop shadow included, inside the screen margins at the given scale.
function bubbleMethods:clampToScreen( bubbleX, bubbleY, scale )
	local margin = config.screenMargin
	local left = self.outerHalfWidth * scale
	local right = ( self.outerHalfWidth + max( config.shadowOffsetX, 0 ) ) * scale
	local top = self.outerHalfHeight * scale
	local bottom = ( self.outerHalfHeight + max( config.shadowOffsetY, 0 ) ) * scale

	return clamp( bubbleX, screen.minX + margin + left, screen.maxX - margin - right ), clamp( bubbleY, screen.minY + margin + top, screen.maxY - margin - bottom )
end

function bubbleMethods:getBounds()
	local group = self.group
	local halfWidth = self.outerHalfWidth * group.xScale
	local halfHeight = self.outerHalfHeight * group.yScale

	return group.x - halfWidth, group.y - halfHeight, group.x + halfWidth, group.y + halfHeight
end

--------------------------------------------------------------------------------------
-- Public functions

function captain.new( parentGroup )
	local talk = setmetatable( {}, captainMethods )

	talk.group = display.newGroup()
	parentGroup:insert( talk.group )

	talk.titleBubble = newBubble( talk.group )
	talk.lineBubble = newBubble( talk.group )

	talk.anchorX = ( screen.minX + screen.maxX ) * 0.5
	talk.anchorY = ( screen.minY + screen.maxY ) * 0.5
	talk.lastPick = {}
	talk.milestoneIndex = 0
	talk.current = nil
	talk.pending = nil

	return talk
end

function captainMethods:setAnchor( anchorX, anchorY )
	self.anchorX = anchorX
	self.anchorY = anchorY
end

-- The scene alone decides when the title shows; lines never hide or restore it.
function captainMethods:showTitle( isVisible )
	local bubble = self.titleBubble

	if isVisible and not bubble.isShown then
		bubble:show( nil, config.title )
	elseif not isVisible and bubble.isShown then
		bubble:hide()
	end
end

function captainMethods:startLine( text, tier, duration, isMilestone )
	local current = self.current

	-- A line arriving right after a milestone (the launch line at escape velocity) must not swallow it.
	if current and current.isMilestone and current.age < config.milestoneRequeueTime and not self.pending then
		self.pending = { text = current.text }
	end

	local style = config.tiers[tier] or config.tiers[0]

	self.current = {
		text = text,
		tier = tier,
		duration = duration or lineDuration( text ),
		age = 0,
		isMilestone = isMilestone,
	}

	self.lineBubble:show( text, style )

	-- Only anger warnings and the firing line speak; calm quips and milestones stay quiet under the music.
	if tier > 0 then
		sound.babble( tier, #text )
	end
end

function captainMethods:say( text, tier, duration )
	self:startLine( text, tier or 0, duration, false )
end

function captainMethods:pickLine( key, pool )
	local count = #pool
	local index = random( count )

	if count > 1 and index == self.lastPick[key] then
		index = index % count + 1
	end

	self.lastPick[key] = index

	return pool[index]
end

function captainMethods:quip( poolName )
	local pool = lines[poolName]

	if not pool or #pool == 0 then
		return
	end

	self:say( self:pickLine( poolName, pool ), config.poolTiers[poolName] or 0 )
end

function captainMethods:warn( tier )
	local pool = lines.warnings[tier]

	if not pool or #pool == 0 then
		return
	end

	self:say( self:pickLine( "warnings" .. tier, pool ), tier )
end

function captainMethods:checkMilestones( knots )
	local milestones = lines.milestones
	local reached = nil

	while self.milestoneIndex < #milestones and knots >= milestones[self.milestoneIndex + 1].knots do
		self.milestoneIndex = self.milestoneIndex + 1
		reached = milestones[self.milestoneIndex]
	end

	if not reached then
		return
	end

	if self.current then
		self.pending = { text = reached.text }
	else
		self:startLine( reached.text, 0, nil, true )
	end
end

function captainMethods:getFollowTarget( bubble )
	local margin = config.screenMargin
	local halfWidth = bubble.outerHalfWidth
	local halfHeight = bubble.outerHalfHeight
	local lowY = screen.minY + margin + halfHeight
	local highY = screen.maxY - margin - halfHeight
	local aboveY = self.anchorY - config.tailLength - halfHeight
	local belowY = self.anchorY + config.tailLength + halfHeight

	local lowX = screen.minX + margin + halfWidth
	local highX = screen.maxX - margin - halfWidth

	-- With no room above or below, sit beside the anchor, or failing that on the roomier vertical side.
	if aboveY < lowY and belowY > highY then
		local rightX = self.anchorX + config.tailLength + halfWidth
		local leftX = self.anchorX - config.tailLength - halfWidth
		local sideY = clamp( self.anchorY, lowY, highY )

		if rightX <= highX then
			return rightX, sideY
		elseif leftX >= lowX then
			return leftX, sideY
		end

		bubble.isBelow = screen.maxY - self.anchorY > self.anchorY - screen.minY
	elseif bubble.isBelow then
		if aboveY >= lowY + config.flipHysteresis or belowY > highY then
			bubble.isBelow = false
		end
	elseif aboveY < lowY then
		bubble.isBelow = true
	end

	local targetX = clamp( self.anchorX, lowX, highX )
	local targetY = clamp( bubble.isBelow and belowY or aboveY, lowY, highY )

	return targetX, targetY
end

function captainMethods:update( dt, knots )
	self:checkMilestones( knots or 0 )

	local current = self.current

	if current then
		current.age = current.age + dt

		if current.age >= current.duration then
			self.current = nil
			self.lineBubble:hide()

			local pending = self.pending
			self.pending = nil

			if pending then
				self:startLine( pending.text, 0, nil, true )
			end
		else
			self.lineBubble.group.alpha = clamp01( ( current.duration - current.age ) / config.fadeDuration )
		end
	end

	local lineBubble = self.lineBubble

	if lineBubble.isShown then
		local targetX, targetY = self:getFollowTarget( lineBubble )
		lineBubble:update( dt, targetX, targetY, self.anchorX, self.anchorY )
	end

	local titleBubble = self.titleBubble

	if titleBubble.isShown then
		local targetX = ( screen.minX + screen.maxX ) * 0.5
		local targetY = screen.minY + config.title.topOffset + titleBubble.outerHalfHeight
		titleBubble:update( dt, targetX, targetY, self.anchorX, self.anchorY )
	end
end

function captainMethods:isTalking()
	return self.current ~= nil
end

function captainMethods:isTitleShowing()
	return self.titleBubble.isShown == true
end

return captain
