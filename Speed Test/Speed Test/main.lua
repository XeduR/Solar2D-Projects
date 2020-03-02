display.setStatusBar( display.HiddenStatusBar )
math.randomseed( os.time() )
local score, highscore, tapTime, tapTimeMin, increaseTapSpeed = 0, 0, 800, 300, true
local transitions, touchOrder, button, text = {}, {}, {}, {}
local font, fontSize = "font/adventpro-bold.ttf", 28
local playing, gameover, box

local function touchColour(event)
	if playing == true then
		if event.phase == "began" then
			if #touchOrder > score then
				if touchOrder[score+1] == event.target.id then
					score = score+1
					text[1].text, text[2].text = "Score: "..score, "Score: "..score
				else
					gameover(1, event.target.id)
				end
			else
				gameover(1, event.target.id)
			end
		end
		return true
	end
end

display.setDefault( "textureWrapX", "repeat" )
display.setDefault( "textureWrapY", "mirroredRepeat" )
local bg = display.newRect( 160, 240, display.actualContentWidth, display.actualContentHeight )
bg.fill = {
    type = "image",
    filename = "images/metalTexture.png"
}
bg.fill.scaleX, bg.fill.scaleY = 128 / bg.width, 128 / bg.height
display.setDefault( "textureWrapX", "clampToEdge" )
display.setDefault( "textureWrapY", "clampToEdge" )

local title = display.newImageRect( "images/title.png", 256, 128 )
title.x, title.y = 160, display.safeScreenOriginY+title.height*0.5
button[1] = display.newImageRect( "images/buttonRed.png", 128, 128 )
button[1].x, button[1].y = 92, (display.contentHeight-display.actualContentHeight)*0.5+display.actualContentHeight-260
button[2] = display.newImageRect( "images/buttonGreen.png", 128, 128 )
button[2].x, button[2].y = button[1].x+button[1].width, button[1].y+button[1].height*0.5
button[3] = display.newImageRect( "images/buttonOrange.png", 128, 128 )
button[3].x, button[3].y = button[1].x, button[2].y+button[2].height*0.5
button[4] = display.newImageRect( "images/buttonBlue.png", 128, 128 )
button[4].x, button[4].y = button[2].x, button[3].y+button[3].height*0.5

for i = 1, 4 do
	button[i].id = i
	button[i]:addEventListener( "touch", touchColour )
end

local flash = display.newCircle( button[1].x, button[1].y, 53 )
flash.alpha = 0
flash.blendMode = "add"

local misclick = display.newImageRect( "images/misclick.png", 128, 128 )
misclick.x, misclick.y = button[1].x, button[1].y
misclick.alpha = 0

text[1] = display.newText( "Score: "..score, 148, title.y+80, font, fontSize )
text[1]:setFillColor( 0 )
text[2] = display.newText( "Score: "..score, text[1].x-1, text[1].y-1, font, fontSize )
text[2]:setFillColor( 0.898, 0.663, 0.153 )
text[3] = display.newText( "Highscore: "..highscore, text[1].x, text[1].y+30, font, fontSize )
text[3]:setFillColor( 0 )
text[4] = display.newText( "Highscore: "..highscore, text[3].x-1, text[3].y-1, font, fontSize )
text[4]:setFillColor( 0.898, 0.663, 0.153 )

for i = 1, 4 do
	text[i].anchorX = 0
end

local flashColours = {
	{ 0.925, 0.337, 0.337 },
	{ 0.396, 0.933, 0.396 },
	{ 0.933, 0.769, 0.325 },
	{ 0.286, 0.6, 0.808 }
}

local function play()
	if playing == false then
		playing = true
	end

	touchOrder[#touchOrder+1] = math.random(4)
	flash:setFillColor( unpack( flashColours[touchOrder[#touchOrder]] ) )
	flash.x, flash.y = button[touchOrder[#touchOrder]].x, button[touchOrder[#touchOrder]].y

	local time
	if increaseTapSpeed == true then
		time = tapTime - (#touchOrder)^2*0.5
	else
		time = tapTimeMin
	end

	if time <= tapTimeMin then
		increaseTapSpeed = false
	end

	local function fade()
		transitions[4] = transition.to(flash, {time=time*0.5, alpha=0, transition=easing.outExpo, onComplete=play})
	end

	transitions[3] = transition.to(flash, {time=time*0.5, alpha=0.5, transition=easing.outExpo, onComplete=fade})
end

local function newgame(event)
	increaseTapSpeed = true
	score, misclick.alpha = 0, 0
	text[1].text, text[2].text = "Score: "..score, "Score: "..score
	for i = #touchOrder,1,-1 do
	    table.remove(touchOrder,i)
	end

	box:removeEventListener( "touch", newgame )
	transitions[1] = transition.to(box, {time=500,alpha=0})
	transitions[2] = transition.to(text[5], {time=500,alpha=0})
	timer.performWithDelay( 1000, play )
end

function gameover(id, colour)
	playing = false
	if id == 0 then -- 0 is first launch
		box = display.newRect( 160, (button[1].y+button[4].y)*0.5, display.actualContentWidth, 280 )
		box:setFillColor(0)
		box.alpha = 0.8
		text[5] = display.newText( "Tap the lights in the correct order for as long as you can.\n\nTap here to start", 160, box.y+60, 240, 300,  font, fontSize )
		box:addEventListener( "touch", newgame )
	else
		transition.cancel()
		flash.alpha, box.alpha, misclick.alpha = 0, 0, 1
		misclick.x, misclick.y = button[colour].x, button[colour].y

		if score > highscore then
			highscore = score
			text[3].text, text[4].text = "Highscore: "..highscore, "Highscore: "..highscore
		end

		local function addTouch()
			box:addEventListener( "touch", newgame )
		end

		transitions[1] = transition.to(box, {time=500,alpha=0.8})
		transitions[2] = transition.to(text[5], {time=500,alpha=1, onComplete=addTouch})
	end
end

gameover(0)
