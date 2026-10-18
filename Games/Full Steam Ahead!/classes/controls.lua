-- Keyboard input: tracks held keys, ignores auto-repeat, and reports key-downs and thrust changes to the game scene.

local controls = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local config = require( "data.controls" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local actionByKey = {}

for action, keyNames in pairs( config ) do
	for i = 1, #keyNames do
		actionByKey[keyNames[i]] = action
	end
end

local heldKeys = {}
local handlers

--------------------------------------------------------------------------------------
-- Private functions

local function isActionHeld( action )
	for keyName in pairs( heldKeys ) do
		if actionByKey[keyName] == action then
			return true
		end
	end

	return false
end

local function onKey( event )
	local keyName = event.keyName
	local action = actionByKey[keyName]
	local wasThrustHeld = isActionHeld( "thrust" )

	if event.phase == "down" then
		-- A down for a key already held is the OS repeating it.
		if heldKeys[keyName] then
			return action ~= nil
		end

		heldKeys[keyName] = true

		local isHandled = handlers.onKeyDown( action )

		if isActionHeld( "thrust" ) ~= wasThrustHeld then
			handlers.onThrustChange()
		end

		return isHandled or action ~= nil
	end

	heldKeys[keyName] = nil

	if isActionHeld( "thrust" ) ~= wasThrustHeld then
		handlers.onThrustChange()
	end

	return action ~= nil
end

-- Key-ups never arrive for keys held while the window loses focus.
local function onWindowState( event )
	if event.phase == "background" then
		heldKeys = {}
		handlers.onThrustChange()
	end
end

--------------------------------------------------------------------------------------
-- Public functions

-- callbacks: onKeyDown( action ) returns whether it handled the key, action is nil for unbound keys; onThrustChange().
function controls.start( callbacks )
	handlers = callbacks
	heldKeys = {}

	Runtime:addEventListener( "key", onKey )
	Runtime:addEventListener( "windowState", onWindowState )
end

function controls.stop()
	Runtime:removeEventListener( "key", onKey )
	Runtime:removeEventListener( "windowState", onWindowState )

	heldKeys = {}
	handlers = nil
end

function controls.isThrustHeld()
	return isActionHeld( "thrust" )
end

return controls
