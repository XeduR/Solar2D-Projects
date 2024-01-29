local dialogue = {}

local playerAction = require("classes.playerAction")
local screen = require("classes.screen")
local dialogueCallback = nil
local group = nil

-- How long the player needs to wait before they can dismiss a dialogue box.
local clickDelay = 500
local lastClick = 0
local parent = nil

-- Skipped handling sceneGroup parent issues as it was only realised in the end.
-- This results in the dialogue boxes not being handled by Composer.
function dialogue.setParent( group )
	-- parent = group
end

function dialogue.new( text, source, callback )
	playerAction.suspended = true

	group = display.newGroup()
	-- parent:insert( group )

	local font = "assets/fonts/JosefinSlab-Medium.ttf"
	local fontSize = 26
	local prefix = ""

	if source == "Thought" then
		font = "assets/fonts/JosefinSlab-MediumItalic.ttf"
	elseif source == "Time" then
		font = "assets/fonts/JosefinSlab-Bold.ttf"
		fontSize = 40
	end

	if source ~= "Thought" and source ~= "Time" then
		local name
		if source == "Oldman" then
			name = "Some grandpa"
		else
			name = source
		end
		prefix = name .. ": "
	end

	local text = display.newText({
		parent = group,
		text = prefix .. text,
		x = screen.centerX,
		y = screen.maxY - 80,
		width = screen.width - 80,
		font = font,
		fontSize = fontSize,
		align = "center"
	})

	if source == "Me" then
		text:setFillColor( 1, 0.85, 0 )
	elseif source == "Thought" then
		text:setFillColor( 0.9, 0.75, 0 )
	elseif source == "Child" then
		text:setFillColor( 1, 0, 0.9 )
	elseif source == "Mom" then
		text:setFillColor( 0.2, 0.8, 0.95 )
	elseif source == "Telemarketer" then
		text:setFillColor( 0.95, 0.05, 0 )
	elseif source == "Jo" then
		text:setFillColor( 0.7, 0.25, 0.95 )
	end

	local background = display.newRect( group, text.x, text.y, text.width + 80, text.height + 40 )
	background:setFillColor( 0, 0.85 )
	text:toFront()

	if callback then
		dialogueCallback = callback
	end

	lastClick = system.getTimer()

	Runtime:addEventListener( "touch", dialogue.remove )
end


function dialogue.remove( event )
	if not event or event.phase == "ended" then
		local time = system.getTimer()

		-- Ensure that dialogue boxes aren't removed too quickly by the player,
		-- but allow immediate removal via hardcoded events.
		if group and (not event or time >= lastClick + clickDelay) then
			lastClick = time

			display.remove( group )
			group = nil
			Runtime:removeEventListener( "touch", dialogue.remove )

			playerAction.suspended = false

			if dialogueCallback then
				dialogueCallback()
			end
		end
	end
	return true
end


return dialogue