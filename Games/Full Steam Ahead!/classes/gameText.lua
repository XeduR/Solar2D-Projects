-- Game-font text objects, shifted per renderer so every platform draws the glyphs where the HTML5 build does.

local gameText = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local fonts = require( "data.fonts" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local offsetY

--------------------------------------------------------------------------------------
-- Public functions

-- The Simulator reports its skin's platform, so a Windows host is told apart by the drive letter of its resource path.
function gameText.detectRenderer( environment, platform, resourcePath )
	if environment == "simulator" then
		if type( resourcePath ) == "string" and resourcePath:find( "^%a:" ) then
			return "win32"
		end

		return "macos"
	end

	return platform
end

-- Takes display.newText's table params. The object's own group carries the shift, so moving, re-anchoring or re-texting the object keeps it.
function gameText.new( params )
	local holder = display.newGroup()

	if params.parent then
		params.parent:insert( holder )
	end

	holder.y = offsetY * params.fontSize

	local textParams = {}

	for key, value in pairs( params ) do
		textParams[key] = value
	end

	textParams.parent = holder

	return display.newText( textParams )
end

function gameText.remove( object )
	if object then
		display.remove( object.parent )
	end
end

function gameText.toFront( object )
	object.parent:toFront()
end

--------------------------------------------------------------------------------------
-- Renderer detection, once per launch

local renderer = gameText.detectRenderer( system.getInfo( "environment" ), system.getInfo( "platform" ), system.pathForFile( nil, system.ResourceDirectory ) )
offsetY = fonts.rendererOffsetY[renderer] or 0

return gameText
