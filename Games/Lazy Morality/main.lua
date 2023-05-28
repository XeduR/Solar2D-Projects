-- The contents of this file were fully generated using ChatGPT and GitHub Copilot. As such, the file looks fairly messy.
-- Only manual changes were to fix minor issues, such as fixing scope related errors or making adjustments to some logic.

-- Hide status bar and set background color to white.
display.setStatusBar( display.HiddenStatusBar )
display.setDefault( "background", 1, 1, 1 )

---------------------------------------------------------

-- Create a function to shuffle the list of indices.
local function shuffle( list )
	local rand = math.random
	local iterations = #list
	local j

	for i = iterations, 2, -1 do
		j = rand( i )
		list[i], list[j] = list[j], list[i]
	end
end

---------------------------------------------------------

-- Load dilemmas from the Data folder.
local dilemmaData = require( "Data.dilemmas" )

-- Create a list of indices for the dilemmas.
local dilemmaList = {}
for i = 1, #dilemmaData do
	dilemmaList[i] = i
end

-- Assign a random number of morality points to each dilemma.
local moralityPoints = {}

---------------------------------------------------------

local gameGroup = display.newGroup()
local overlayGroup = display.newGroup()

-- Set the x coordinate of the left side of the text.
local xText = display.screenOriginX + 20

local nextDilemma

local image, description, options
local dilemmaIndex = 0
local currentOption = 1
local currentChoiceCount = 0

---------------------------------------------------------

-- Create a gradient for the background.
local background = display.newRect( gameGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
background.fill = {
	type = "gradient",
	color1 = { 0.95 },
	color2 = { 0.9 },
	direction = "down"
}

-- Create UI elements for the meter and its needle.
local meter = display.newImageRect( gameGroup, "Images/meter.png", 160, 160 )
meter.x, meter.y = 200, 530

local needle = display.newImageRect( gameGroup, "Images/needle.png", 23, 75 )
needle.anchorY = 1
needle.x, needle.y = meter.x, meter.y + 20

---------------------------------------------------------

-- Create a function to move the morality needle and show next dilemma or end the game.
local function selectOption( event )
	if event.phase == "ended" then
		-- Rotate the needle based on the morality points of the selected dilemma.

		-- To make the game end faster, make the needle more likely to move in the same direction as the previous dilemma.
		local prevDirection = needle.prevRotation and needle.prevRotation < 0 and -1 or 1

		-- Dev note: just to mess with players a bit, increase the probability of the needle moving in the same direction
		-- following every dilemma, meaning the player won't necessarily figure out what they are doing (morally) wrong.
		currentChoiceCount = currentChoiceCount + 1
		prevDirection = math.random() < (0.5 + currentChoiceCount*0.025) and prevDirection or -prevDirection


		needle.rotation = needle.rotation + prevDirection*moralityPoints[dilemmaList[dilemmaIndex]]

		needle.prevRotation = needle.rotation < 0 and -1 or 1

		if math.abs( needle.rotation ) >= 60 then
			transition.to( overlayGroup, { time=200, alpha=1 })
		else
			nextDilemma()
		end
	end
	return true
end

-- Create text button for selecting an answer to the dilemma.
local btnSelect = display.newText({
	parent = gameGroup,
	text = "Select",
	x = meter.x,
	y = meter.y - 80,
	font = "Fonts/Roboto-Bold.ttf",
	fontSize = 20
})
btnSelect:setFillColor( 0, 0, 0 )
btnSelect:addEventListener( "touch", selectOption )

-- Create a function to change between previous and next option to the dilemma.
local function changeOption( event )
	if event.phase == "ended" then
		if event.target.id == "next" then
			currentOption = currentOption + 1
			if currentOption > 3 then
				currentOption = 1
			end
		else
			currentOption = currentOption - 1
			if currentOption < 1 then
				currentOption = 3
			end
		end

		options.text = dilemmaData[dilemmaList[dilemmaIndex]].solutions[currentOption]
		btnSelect.text = "Select ("  .. currentOption .. ")"
	end
	return true
end

-- Create text based buttons for swapping between answers to the dilemma.
local btnPrev = display.newText({
	parent = gameGroup,
	text = "< Previous",
	x = meter.x - 80,
	y = btnSelect.y,
	font = "Fonts/Roboto-Bold.ttf",
	fontSize = 20
})
btnPrev:setFillColor( 0, 0, 0 )
btnPrev.anchorX = 1
btnPrev.id = "prev"
btnPrev:addEventListener( "touch", changeOption )

local btnNext = display.newText({
	parent = gameGroup,
	text = "Next >",
	x = meter.x + 120,
	y = btnSelect.y,
	font = "Fonts/Roboto-Bold.ttf",
	fontSize = 20
})
btnNext:setFillColor( 0, 0, 0 )
btnNext.anchorX = 0
btnNext.id = "next"
btnNext:addEventListener( "touch", changeOption )

-- Make the transitions loop forever and make them a bit chaotic by using slightly different times.
transition.to( btnSelect, { time=725, transition=easing.continuousLoop, iterations=-1, xScale=1.1, yScale=1.1 })
transition.to( btnNext, { time=730, transition=easing.continuousLoop, iterations=-1, xScale=1.1, yScale=1.1 })
transition.to( btnPrev, { time=710, transition=easing.continuousLoop, iterations=-1, xScale=1.1, yScale=1.1 })

-- Make the buttons and the meter/needle transparent for now.
btnSelect.alpha = 0
btnNext.alpha = 0
btnPrev.alpha = 0
meter.alpha = 0
needle.alpha = 0


---------------------------------------------------------

local function reshuffle()
	shuffle( dilemmaList )
	-- Just assign random morality values to each dilemma. The answers don't matter.
	-- I guess this could be interpreted as a meta commentary on the nature of morality.
	local moralityValues = { 5, 8, 13, 15 }
	for i = 1, #dilemmaData do
		moralityPoints[i] = moralityValues[math.random(#moralityValues)]
	end
	-- (Dev note: the comment above about the meta commentary was written by Copilot.)
	dilemmaIndex = 1
end

-- Reshuffle the dilemmas and morality values only at the start and when they have all been shown.
reshuffle()

-- Create a function to display the next dilemma.
function nextDilemma()
	display.remove( image )
	display.remove( description )
	display.remove( options )

	dilemmaIndex = dilemmaIndex + 1
	if dilemmaIndex > #dilemmaList then
		reshuffle()
	end

	local dilemmma = dilemmaList[dilemmaIndex]

	image = display.newImageRect( gameGroup, "Images/" .. dilemmma .. ".jpg", 512, 512 )
	image.x, image.y = display.contentCenterX + 200, display.contentCenterY

	local width = image.x - image.width / 2 - xText - 20

	description = display.newText({
		parent = gameGroup,
		text = dilemmaData[dilemmma].dilemma,
		x = xText,
		y = image.y - image.height / 2,
		width = width,
		align = "left",
		font = "Fonts/Roboto-Bold.ttf",
		fontSize = 23
	})
	description.anchorX, description.anchorY = 0, 0
	description:setFillColor( 0, 0, 0 )

	local yPrev = description.y + description.height + 20
	currentOption = 1

	options = display.newText({
		parent = gameGroup,
		text = dilemmaData[dilemmma].solutions[1],
		x = xText,
		y = yPrev,
		width = width,
		align = "left",
		font = "Fonts/Roboto-Light.ttf",
		fontSize = 21
	})
	options.anchorX, options.anchorY = 0, 0
	options:setFillColor( 0, 0, 0 )

	btnSelect.text = "Select ("  .. currentOption .. ")"

end


local function newgame()
	-- Make the buttons and the meter/needle visible again.
	btnSelect.alpha = 1
	btnNext.alpha = 1
	btnPrev.alpha = 1
	meter.alpha = 1
	needle.alpha = 1

	currentChoiceCount = 0
	needle.rotation = 0

	nextDilemma()
end

-- Call newgame once to create an underlying UI.
newgame()

---------------------------------------------------------

local function pressStart( event )
	if event.phase == "ended" then
		local target = event.target
		if not target.touched then
			target.touched = true

			transition.to( target, { time=200, alpha=0, onComplete=function()
				target.touched = false
				newgame()
			end })
		end
	end
	return true
end

-- Create a rectangle to cover the entire screen.
local overlay = display.newRect( overlayGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
overlay:setFillColor( 0, 0, 0, 0.9 )

local title = display.newText({
	parent = overlayGroup,
	text = "Lazy Morality",
	x = display.contentCenterX,
	y = display.contentCenterY - 200,
	font = "Fonts/Roboto-Bold.ttf",
	fontSize = 64
})

local instructions = display.newText({
	text = "You're presented with 3 answers to each \"moral dilemma\".\n\nPress Previous and Next to switch between answers and press Select to choose an answer.\n\nThe needle will move depending on how \"moral\" your answer is. The goal is to keep the needle balanced near the top of the meter.",
	parent = overlayGroup,
	x = display.contentCenterX,
	y = display.contentCenterY + 40,
	width = display.actualContentWidth - 200,
	font = "Fonts/Roboto-Light.ttf",
	align = "center",
	fontSize = 24
})

local start = display.newText({
	parent = overlayGroup,
	text = "Press to Start",
	x = display.contentCenterX,
	y = display.contentCenterY + 200,
	font = "Fonts/Roboto-Bold.ttf",
	fontSize = 48
})

-- Prevent touches from passing through the overlay.
overlayGroup:addEventListener( "touch", pressStart )

---------------------------------------------------------
