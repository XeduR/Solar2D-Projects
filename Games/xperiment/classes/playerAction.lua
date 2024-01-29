local action = {}
action.suspended = false

local playerCharacter = require("classes.playerCharacter")
playerCharacter.characterMoving = false

-- Define the player's movement speed in pixels per second.
local timePerPixel = 3
-- Add a safety padding to the boundaries to prevent the player from getting stuck.
local boundaryPadding = 5
-- Define the distance from the player to the object to activate it.
-- (The use of this variable is just a dirty hack for a game jam project.)
local activationDistance = 500


local hasStarted = false
local actionInProgress = false
local player = nil
local object = nil
local boundary = nil
local group = nil

local abs = math.abs
local zero = 1e-9


-- Check if two lines intersect and return possible intersect coordinates.
local function checkIntersect( x1, y1, x2, y2, x3, y3, x4, y4 )
	local d = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)

	if abs(d) < zero then -- Parallel lines cannot intersect.
		return false
	end

	local ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / d
	local ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / d

	if (ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1) then
		return true, { x=x1 + (ua * (x2 - x1)), y=y1 + (ua * (y2 - y1)) }
	end

	return false
end

local mouseEventBegan = false
local function onEvent( event )
	if event.type == "down" and not mouseEventBegan and not action.suspended then
		-- Accept any mouse button as valid input.
		if event.isPrimaryButtonDown or event.isSecondaryButtonDown or event.isMiddleButtonDown then
			mouseEventBegan = true
			action.cancelEvent()
			actionInProgress = true

			-- Account for changes in the group's position via the camera.
			local realX, realY = event.x - group.x, event.y

			-- Find all intersecting lines and their intersect coordinates.
			local intersect = {}

			for i = 1, #boundary do
				for line = 1, #boundary[i] - 2, 2 do
					local didIntersect, xy = checkIntersect( player.x, player.y, realX, realY, boundary[i][line], boundary[i][line + 1], boundary[i][line + 2], boundary[i][line + 3] )
					if didIntersect then
						intersect[#intersect + 1] = { x=xy.x, y=xy.y }
					end
				end
				-- Check the line between the first and last point.
				local didIntersect, xy = checkIntersect( player.x, player.y, realX, realY, boundary[i][1], boundary[i][2], boundary[i][#boundary[i]-1], boundary[i][#boundary[i]] )
				if didIntersect then
					intersect[#intersect + 1] = { x=xy.x, y=xy.y }
				end
			end

			local toX, toY

			if #intersect == 0 then
				toX, toY = realX, realY
			else
				-- Find the closest intersect point.
				local closest = 1
				local minDistance = math.huge

				for i = 1, #intersect do
					local distance = math.sqrt( (intersect[i].x - player.x)^2 + (intersect[i].y - player.y)^2 )
					minDistance = math.min( minDistance, distance )

					if distance == minDistance then
						closest = i
					end
				end

				toX, toY = intersect[closest].x, intersect[closest].y

				-- Move the player towards the closest intersect point, but add a safety padding.
				local angle = math.atan2( toY - player.y, toX - player.x )
				toX = player.x + math.cos( angle ) * (minDistance - boundaryPadding)
				toY = player.y + math.sin( angle ) * (minDistance - boundaryPadding)

				-- local debugDot = display.newCircle( player.parent, toX, toY, 10 )
				-- timer.performWithDelay( 1000, function() display.remove( debugDot ) end )
			end

			local dir = toX < player.x and -1 or 1
			player.move( dir )

			playerCharacter.characterMoving = true

			-- Move player to the new location.
			transition.to( player, {
				x = toX,
				y = toY,
				time = math.sqrt( (toX - player.x)^2 + (toY - player.y)^2 ) * timePerPixel,
				onComplete = function()
					playerCharacter.characterMoving = false
					actionInProgress = false
					player:stop()

					for i = 1, #object do
						-- Check if the mouse event occurred on top of an object.
						-- (Accounting for the group's position via the camera.)
						local xMin = object[i].x - object[i].width*0.5
						local xMax = object[i].x + object[i].width*0.5
						local yMin = object[i].y - object[i].height*0.5
						local yMax = object[i].y + object[i].height*0.5

						if xMin <= realX and xMax >= realX and yMin <= realY and yMax >= realY then
							-- Check that the player is at least within certain distance from the object to prevent activating
							-- objects from a distance when the player collides with the level boundaries.
							local distance = math.sqrt( (object[i].x - player.x)^2 + (object[i].y - player.y)^2 )
							if distance <= activationDistance and object[i].callback then
								object[i].callback()
							end
						end
					end
				end
			})
		end

	elseif event.type == "up" and mouseEventBegan then
		mouseEventBegan = false

	end
end


function action.start( playerReference, objectReference, groupReference, boundaryReference )
	if not hasStarted then
		hasStarted = true
		player = playerReference
		object = objectReference
		group = groupReference
		boundary = boundaryReference

		Runtime:addEventListener( "mouse", onEvent )
	end
end


function action.stop()
	if hasStarted then
		hasStarted = false
		player = nil
		object = nil
		boundary = nil

		Runtime:removeEventListener( "mouse", onEvent )

		action.cancelEvent()
	end
end


function action.cancelEvent()
	if actionInProgress then
		player:stop()
		transition.cancel( player )
		actionInProgress = false
	end
end


return action