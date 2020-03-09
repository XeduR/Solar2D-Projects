display.setStatusBar( display.HiddenStatusBar )
display.setDefault( "fillColor", 0 )
math.randomseed( os.time() )
-- A bit of "cheeky grouping" with the variable declarations in order to fit everything to within 100 lines, as per personal constraints.
local startTime, runnerTimer, startTransition, score, integral, fractional, currentSpeed
local text, spawnSpeed, startSpeed, maximumSpeed, highscore, font, fontSize = {}, 500, 4000, 1200, 0, "assets/adventpro-bold.ttf", 15
local groupBG = display.newGroup()
local groupRunners = display.newGroup()

local options = {
    width = 60,
    height = 60,
    numFrames = 3,
    sheetContentWidth = 180,
    sheetContentHeight = 60
}
local runnerSheet = graphics.newImageSheet( "assets/runner.png", options )
local runnerAnimation = { time=400, frames={1,1,2,3,3} }

local ground = display.newImageRect( groupBG, "assets/ground.png", display.actualContentWidth, 256 ) -- will warp the ground image a bit
ground.x, ground.y, ground.anchorY = 240, (display.contentHeight-display.actualContentHeight)*0.5+display.actualContentHeight, 1

local sky = display.newRect( groupBG, 240, display.screenOriginY, display.actualContentWidth, display.actualContentHeight - ground.height )
sky.anchorY = 0
sky.fill = {
    type = "gradient",
    color1 = { 0.6, 0.9, 0.9 },
    color2 = { 0, 0.7, 1 },
    direction = "up"
}

local title = display.newImageRect( groupBG, "assets/title.png", 196, 56 )
title.x, title.y = 100, display.safeScreenOriginY+title.height*0.5

local startButton = display.newImageRect( groupBG, "assets/start.png", 128, 64 )
startButton.x, startButton.y = 240, 220
startTransition = transition.blink( startButton, {time=3500} )

text[1] = display.newText( groupBG, "Stop all runners from reaching the finish line!", title.x + 100, title.y - 10, font, fontSize )
text[2] = display.newText( groupBG, "Score: 0:00", text[1].x + 30, title.y + 20, font, fontSize )
text[3] = display.newText( groupBG, "Highscore: 0:00", text[2].x + 100, text[2].y, font, fontSize )
for i = 1, 3 do
	text[i].anchorX = 0
end

local function updateScore()
	score = system.getTimer()-startTime
	integral, fractional = math.modf(score*0.001)
	text[2].text = "Score: "..integral..":"..math.floor(fractional*100)
end

local function gameover()
	transition.cancel() -- cancels all transitions
	timer.cancel( runnerTimer )
	Runtime:removeEventListener( "enterFrame", updateScore )
	if score > highscore then
		highscore = score
		integral, fractional = math.modf(score*0.001)
		text[3].text = "Highscore: "..integral..":"..math.floor(fractional*100)
	end
	transition.to( groupRunners, {time=250, alpha=0, onComplete=function()
		display.remove( groupRunners )
		groupRunners = display.newGroup()
		startButton.alpha = 1
		startTransition = transition.blink( startButton, {time=3500} )
	end})
end

local function removeRunner( event )
    if event.phase == "began" then
		transition.cancel( event.target.transition )
		display.remove( event.target )
    end
    return true
end

local function addRunner()
	local runner = display.newSprite( groupRunners, runnerSheet, runnerAnimation )
	runner.x, runner.y, runner.xScale, runner.yScale = math.random(60,420), ground.y-ground.height, 0.1, 0.1
	runner:addEventListener( "touch", removeRunner )
	runner:toBack()
	runner:play()
	currentSpeed = startSpeed+(startTime-system.getTimer())*0.1
	if currentSpeed <= maximumSpeed then currentSpeed = maximumSpeed end
	runner.transition = transition.to( runner, {time=currentSpeed, x=math.random(20,300), y=ground.y, xScale=1, yScale=1, onComplete=gameover})
	runnerTimer = timer.performWithDelay( spawnSpeed*(currentSpeed/startSpeed), addRunner )
end

local function start()
	transition.cancel(startTransition)
	startButton.alpha = 0
	startTime = system.getTimer()
	Runtime:addEventListener( "enterFrame", updateScore )
	runnerTimer = timer.performWithDelay( spawnSpeed, addRunner )
end
startButton:addEventListener( "touch", start )
