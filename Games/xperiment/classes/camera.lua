local camera = {}

local hasStarted = false

local minX, maxX
local targetStartX, groupStartX
local group
local target

local function update()
	local dx = targetStartX - target.x
	local toX = groupStartX + dx

	if toX < minX and toX > maxX then
		group.x = toX
	end
end


function camera.start( trackingTarget, trackedGroup, background )
    if not hasStarted then
        hasStarted = true

		group = trackedGroup
		target = trackingTarget

		-- Calculate the boundaries.
		minX = 0
		maxX = -background.width + display.actualContentWidth

		-- Set the camera to the initial position.
		local cameraX = math.max( math.min( display.contentCenterX - target.x, minX ), maxX )
		group.x = cameraX
		targetStartX = target.x
		groupStartX = group.x

		Runtime:addEventListener("enterFrame", update)
    end
end


function camera.stop()
    if hasStarted then
        hasStarted = false

        Runtime:removeEventListener("enterFrame", update)
    end
end


return camera
