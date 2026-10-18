---------------------------------------------------------------------------
--     _____                  _         ______                           --
--    / ___/____  __  _______(_)____   / ____/___ _____ ___  ___  _____  --
--    \__ \/ __ \/ / / / ___/ / ___/  / / __/ __ `/ __ `__ \/ _ \/ ___/  --
--   ___/ / /_/ / /_/ / /  / / /__   / /_/ / /_/ / / / / / /  __(__  )   --
--  /____/ .___/\__, /_/  /_/\___/   \____/\__,_/_/ /_/ /_/\___/____/    --
--      /_/    /____/                                                    --
--                                                                       --
--  © 2020-2022 Spyric Games Ltd.         Last Updated: 13 October 2022  --
---------------------------------------------------------------------------
--  License: MIT                                                         --
---------------------------------------------------------------------------

local performance = {}

----------------------------------------------
-- Default visual parameters:
----------------------------------------------
-- NB! These should be edited only via passing
-- a table as an argument to start() function.
----------------------------------------------
local style = {
	paddingHorizontal = 20,
	paddingVertical = 10,
	fontColor = { 1, 0.9 },
	bgColor = { 0, 0.9 },
	fontSize = 24,
	fontOffsetY = 0,
	anchorX = 0.5,
	anchorY = 0,
	x = display.contentCenterX,
	y = display.screenOriginY,
	font = native.systemFont,
	framesBetweenUpdate = 3
}
----------------------------------------------

-- If you need to access the performance meter UI in your
-- scenes, you can do so via the performance.meter property.
performance.meter = nil
local counter = nil
local bg = nil

-- Localising global functions.
local getTimer = system.getTimer
local getInfo = system.getInfo
local format = string.format
local floor = math.floor
local cg = collectgarbage

-- Constant is multiplied by 100 to allow for the use of floor() later on.
local C = 100 / 1024^2
local isActive = false
local prevTime = 0
local maxWidth = 0
local paddingHorizontal = 0
local framesBetweenUpdate = 3
local frameCount = 0
local FPS

-- Reset all necessary variables.
local function reset()
	isActive = true
	frameCount = 0
	prevTime = getTimer()
end

local function updateMeter()
	local curTime = getTimer()
	local curFPS = floor( 1000 / (curTime - prevTime))
	frameCount = frameCount+1
	FPS[frameCount] = curFPS

	-- Run garbage collection and update text every frame by default.
	if frameCount > framesBetweenUpdate then
		frameCount = 0

		-- Calculate the average FPS and update the performance meter.
		local avgFPS = 0
		for i = 1, framesBetweenUpdate do
			avgFPS = avgFPS + FPS[i]
		end
		avgFPS = floor(avgFPS/framesBetweenUpdate)

		counter.text = avgFPS .. "   " ..                   -- FPS (average)
		floor(getInfo( "textureMemoryUsed" ) * C) * 0.01 .. -- Texture memory
		format( "MB   %.2fKB", cg( "count" ) )              -- Lua memory

		-- Adjust the performance meter's width if necessary.
		local currentWidth = counter.width
		if currentWidth > maxWidth then
			maxWidth = currentWidth
			bg.width = currentWidth + paddingHorizontal
		end
	end
	prevTime = curTime
end


local function toggleMeter( event )
	if event.phase == "began" then
		cg( "collect" )

		if isActive then
			isActive = false
			Runtime:removeEventListener( "enterFrame", updateMeter )
		else
			reset()
			Runtime:addEventListener( "enterFrame", updateMeter )
		end
		counter.isVisible = isActive
		bg.isVisible = isActive
	end
end


function performance.stop()
	if isActive then
		toggleMeter({phase="began"})
	end
end


function performance.destroy()
	performance.stop()
	display.remove(performance.meter)
	performance.meter = nil
	counter = nil
	bg = nil
end

-- Creates and/or starts an existing performance meter that tracks FPS, texture memory & Lua memory usage.
-- Two optional parameters are: startVisible (boolean) and params (table) for visual customisation.
function performance.start(...)
	cg( "collect" )

	if performance.meter then
		if not isActive then
			toggleMeter({phase="began"})
		end
	else
		local t = {...}
		local startVisible = type(t[1]) ~= "boolean" or t[1]
		local customStyle = type(t[#t]) == "table" and t[#t] or {}

		performance.meter = display.newGroup()
		performance.meter.anchorChildren = true
		if customStyle.parent then
			customStyle.parent:insert(performance.meter)
		end

		-- Update style with user input.
		for i, v in pairs( customStyle ) do
			style[i] = v
		end
		performance.meter.x, performance.meter.y = style.x, style.y
		performance.meter.anchorX, performance.meter.anchorY = style.anchorX, style.anchorY
		paddingHorizontal = style.paddingHorizontal*2
		framesBetweenUpdate = style.framesBetweenUpdate

		FPS = {}
		for i = 1, framesBetweenUpdate do
			FPS[i] = 0
		end

		counter = display.newText( performance.meter, "00   0.00MB   0.00KB", 0, style.fontOffsetY, style.font, style.fontSize )
		counter.fill = style.fontColor
		maxWidth = counter.width

		bg = display.newRect( performance.meter, 0, 0, counter.width + paddingHorizontal, counter.height + style.paddingVertical*2 )
		bg:addEventListener( "touch", toggleMeter )
		bg.fill = style.bgColor
		bg.isHitTestable = true

		counter:toFront()

		counter.isVisible = startVisible
		bg.isVisible = startVisible

		if startVisible then
			reset()
			Runtime:addEventListener( "enterFrame", updateMeter )
		end
	end
end


return performance
