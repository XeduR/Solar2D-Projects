-- Maths, display and sprite animation helpers shared by the game's classes.

local drawing = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local sheets = require( "classes.sheets" )
local art = require( "data.art" )

--------------------------------------------------------------------------------------
-- Localised functions

local exp = math.exp
local max = math.max
local min = math.min
local random = math.random

--------------------------------------------------------------------------------------
-- Public functions

function drawing.clamp01( value )
	return max( 0, min( 1, value ) )
end

-- A reversed range means the value cannot fit, so it gets the range's centre.
function drawing.clamp( value, low, high )
	if low > high then
		return ( low + high ) * 0.5
	end

	return min( max( value, low ), high )
end

function drawing.lerp( from, to, amount )
	return from + ( to - from ) * amount
end

function drawing.smoothstep( amount )
	amount = drawing.clamp01( amount )
	return amount * amount * ( 3 - 2 * amount )
end

-- Exponential approach, so the result does not depend on the frame rate.
function drawing.approach( current, target, rate, dt )
	return current + ( target - current ) * ( 1 - exp( -rate * dt ) )
end

function drawing.randomRange( range )
	return range[1] + random() * ( range[2] - range[1] )
end

function drawing.randomBetween( low, high )
	return low + ( high - low ) * random()
end

function drawing.randomItem( list )
	return list[random( #list )]
end

function drawing.randomSpread( amount )
	return ( random() * 2 - 1 ) * amount
end

function drawing.setColour( object, colour, alpha )
	if alpha then
		object:setFillColor( colour[1], colour[2], colour[3], alpha )
	else
		object:setFillColor( colour[1], colour[2], colour[3] )
	end
end

function drawing.newGroup( parent )
	local group = display.newGroup()
	parent:insert( group )
	return group
end

-- display.newPolygon centres the shape on x, y, so placing it at the vertices' bounding-box centre keeps them where they are.
function drawing.newPolygonAt( group, vertices )
	local minX, maxX = vertices[1], vertices[1]
	local minY, maxY = vertices[2], vertices[2]

	for i = 1, #vertices, 2 do
		minX = min( minX, vertices[i] )
		maxX = max( maxX, vertices[i] )
		minY = min( minY, vertices[i + 1] )
		maxY = max( maxY, vertices[i + 1] )
	end

	return display.newPolygon( group, ( minX + maxX ) * 0.5, ( minY + maxY ) * 0.5, vertices )
end

-- pivot is in art pixels from the frame's top-left corner.
function drawing.setPivot( object, family, name, pivot )
	local sheet = sheets.load( family, name )
	object.anchorX = pivot[1] * art.pixelScale / sheet.frameWidth
	object.anchorY = pivot[2] * art.pixelScale / sheet.frameHeight
end

-- Sprites advance from update rather than play(), so they freeze whenever the game stops updating.
-- position counts through tag.frames from 1 and is also the frame number within the sprite's sequence.
function drawing.newAnimation( sprite, family, name, tagName, startPosition )
	local animation = { sprite = sprite, sheet = sheets.load( family, name ), position = startPosition or 1, elapsed = 0 }
	drawing.setAnimationTag( animation, tagName, true )
	return animation
end

-- A new tag restarts from its first step unless keepPhase carries the current step and elapsed time over.
function drawing.setAnimationTag( animation, tagName, keepPhase )
	if animation.tagName == tagName then
		return
	end

	animation.tagName = tagName
	animation.tag = animation.sheet.tags[tagName]

	if keepPhase then
		animation.position = ( animation.position - 1 ) % #animation.tag.frames + 1
	else
		animation.position = 1
		animation.elapsed = 0
	end

	animation.sprite:setSequence( tagName )
	animation.sprite:setFrame( animation.position )
end

function drawing.stepAnimation( animation, dt )
	local tag = animation.tag
	local position = animation.position
	animation.elapsed = animation.elapsed + dt * 1000

	while animation.elapsed >= tag.durations[position] do
		animation.elapsed = animation.elapsed - tag.durations[position]
		position = position % #tag.frames + 1
	end

	if position ~= animation.position then
		animation.position = position
		animation.sprite:setFrame( position )
	end
end

return drawing
